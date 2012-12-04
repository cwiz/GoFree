request = require "request"

exports.name = "ostrovok"

exports.query = !(origin, destination, extra, cb) ->
  ostUrl = "http://ostrovok.ru/api/v1/search/page/#{extra.page}/?region_id=#{destination.oid}&arrivalDate=#{origin.date}&departureDate=#{destination.date}&room1_numberOfAdults=#{extra.adults}"

  (error, response, body) <-! request ostUrl
  console.log ">>> queried ostrovok serp | #{ostUrl} | status #{response.statusCode}"
  return if error

  json = JSON.parse(response.body)
  page = json._next_page

  cb json
  
  if page
    extra.page = page
    exports.query origin, destination, extra, cb

exports.process = !(json, cb) ->
  console.log ">>> processing ostrovok serp"

  if not json or not json.hotels?
    return

  hotels = json.hotels
  rates  = json._meta.rates

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
      name:     hotel.name
      stars:    stars
      price:    price
      rating:   rating
      url:      "http://ostrovok.ru#{hotel.url}&partner_slug=ostroterra"
      provider: "ostrovok"
    
    newHotels.push newHotel

  cb newHotels

exports.autocomplete = (query, callback) ->
  ostUrl = "http://ostrovok.ru/api/site/multicomplete.json?query=#{query}&regions_ver=v5"
  (error, response, body) <-! request ostUrl
  console.log ">>> queried ostrovok autocomplete | #{ostUrl} | status #{response.statusCode}"
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
