async     = require "async"
database  = require "./../../database"
request   = require "request"

exports.name = "ostrovok"

getOstrovokId = (place, callback) ->
  return callback(null, place.ostrovok_id) if place.ostrovok_id

  (error, result) <- exports.autocomplete "#{place.name_ru}, #{place.country_name_ru}"
  return callback(error,              null)  if error
  return callback({'nothing found'},  null)  if result.length is 0

  ostrovok_id = result[0].oid
  callback null, ostrovok_id
  database.geonames.update {geoname_id : place.geoname_id}, {$set: {ostrovok_id : ostrovok_id}}

exports.query = (origin, destination, extra, cb) ->

  (error, ostrovokId) <- async.parallel {
    origin      : (callback) -> getOstrovokId origin.place,       callback
    destination : (callback) -> getOstrovokId destination.place,  callback
  }

  return cb(error, null) if error

  ostUrl = "http://ostrovok.ru/api/v1/search/page/#{extra.page}/?region_id=#{ostrovokId.destination}&arrivalDate=#{origin.date}&departureDate=#{destination.date}&room1_numberOfAdults=#{extra.adults}"

  console.log "Querying ostrovok serp | #{ostUrl}"
  (error, response, body) <- request ostUrl
  console.log "Queried ostrovok serp | #{ostUrl} | status #{response.statusCode}"
  return cb(error, null) if error

  json = JSON.parse(response.body)
  page = json._next_page

  cb null, json
  
  if page
    extra.page = page
    exports.query origin, destination, extra, cb

exports.process = (json, cb) ->
  console.log "ostrovok.process"

  if not json or not json.hotels?
    console.log "ostrovok.process" 
    cb 'empty json', null

  hotels = json.hotels
  rates  = json._meta?.rates

  if not rates
    return cb {message: 'no rates'}, null

  newHotels = []
  for hotel in hotels when hotel.rooms

    rating = 0
    if hotel.rating?.total?
      count  = hotel.rating.count
      rating = hotel.rating.total * count if count > 25

    price = hotel.rooms[0].total_rate * rates[hotel.rooms[0].currency]
    stars = 1
    stars = (Math.ceil(hotel.star_rating/10.0) + 1) if hotel.star_rating
    
    newHotel =
      name    : hotel.name
      stars   : stars
      price   : price
      rating  : rating
      photo   : hotel.thumbnail_url
      url     : "http://ostrovok.ru#{hotel.url}&partner_slug=ostroterra"
      provider: \ostrovok
    
    newHotels.push newHotel

  cb null, {
    results: newHotels,
    complete: (not json._next_page)
  }

exports.search = (origin, destination, extra, cb) ->
  error, hotelResult <- exports.query origin, destination, extra
  return cb(error, null) if error
  
  error, hotels <- exports.process hotelResult 
  return cb(error, null) if error

  cb null, hotels


exports.autocomplete = (query, callback) ->
  ostUrl = "http://ostrovok.ru/api/site/multicomplete.json?query=#{query}&regions_ver=v5"
  (error, response, body) <-! request ostUrl
  console.log "ostrovok.autocomplete | #{ostUrl} | status #{response.statusCode}"
  return callback error, null if error
  
  json      = JSON.parse(response.body)
  finalJson = []
  for obj in json.regions when (obj.target is "search" and obj.type is 'city')
    country     = obj.country
    name        = obj.name

    name = 'Дели' if name is 'Нью-Дели' 

    id          = obj.id
    displayName = name

    name = name.split(',')[0] if name.split(',').length > 1

    if country isnt "Россия"
      displayName += ", #{country}"

    finalJson.push {
      name:         name
      oid:          id
      country:      country
      displayName:  displayName
      provider:     exports.name
    }

  callback null, finalJson
