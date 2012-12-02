request = require "request"
url		= require "url"

exports.name = "travelmenu"

exports.autocomplete = (query, callback) ->
	query = query.replace(' ', '-')
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
			name:         name
			tmid:         id
			country:      country
			displayName:  displayName
			provider:     exports.name
		}

	callback null, finalJson
