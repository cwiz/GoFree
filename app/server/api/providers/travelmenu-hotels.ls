request = require "request"
url		= require "url"

exports.name = "travelmenu"

autocomplete = (query, callback) ->
	
	query 				= query.replace(' ', '-')
	tmUrl 				= url.parse "http://www.travelmenu.ru/a_search/hotel.loadLocations?limit=10&language=ru", true
	tmUrl.query['text']	= query
	tmUrl.search 		= null
	urlString 			= url.format tmUrl

	(error, response, body) <-! request urlString
	console.log ">>> queried travelmenu autocomplete | #{urlString} | status #{response.statusCode}"
	return callback(error, null) if error

	json      = JSON.parse(response.body)
	finalJson = []

	for obj in json.list when obj.cit
		name 		= obj.cit
		country 	= obj.cot
		id 			= obj.cid
		displayName = name

		# fucking long list of fixes
		name 	= name.split(',')[0] 	if name.split(',').length > 1
		name 	= "Сан Франциско" 		if name 	is "Юг Сан Франциско"
		country = "США" 				if country 	is 'Соединенные Штаты Америки'

		if country isnt "Россия"
			displayName += ", #{country}"

		finalJson.push {
			id 			: id
			name 		: name
			country 	: country
			displayName : displayName
		}

	callback null, finalJson


getTravelmenuId = (place, callback) ->
	return callback(null, place.travelmenu_id) if place.travelmenu_id

	(error, result) <- autocomplete "#{place.name_ru}, #{place.country_name_ru}"
	return callback(error,              null)  if error
	return callback({'nothing found'},  null)  if result.length is 0

	travelmenu_id = result[0].id
	callback null, travelmenu_id
	database.geonames.update {geoname_id : place.geoname_id}, {$set: {travelmenu_id : travelmenu_id}}

query = (origin, destination, extra, cb) ->

	(error, ostrovokId) <- async.parallel {
		origin      : (callback) -> getOstrovokId origin.place,       callback
		destination : (callback) -> getOstrovokId destination.place,  callback
	}

	return cb(error, null) if error

	ostUrl = "http://ostrovok.ru/api/v1/search/page/#{extra.page}/?region_id=#{ostrovokId.destination}&arrivalDate=#{origin.date}&departureDate=#{destination.date}&room1_numberOfAdults=#{extra.adults}"

	(error, response, body) <- request ostUrl
	console.log "OSTROVOK: Queried ostrovok serp | #{ostUrl} | status #{response.statusCode}"
	return cb(error, null) if error

	json = JSON.parse(response.body)
	page = json._next_page

	cb null, json
	
	if page
		extra.page = page
		query origin, destination, extra, cb


exports.search = (origin, destination, extra, cb) ->
  (error, json)     <- query origin, destination, extra
  return cb(error, null) if error
  
  (error, results)  <- process json
  return cb(error, null) if error

  cb null, results

