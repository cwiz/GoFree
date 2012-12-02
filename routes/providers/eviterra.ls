async       = require "async"
database    = require "../database.js"
moment      = require "moment"
request     = require "request"
Sync        = require "sync"
xml2js      = require "xml2js"

# Globals
parser = new xml2js.Parser()
moment.lang('ru')

# Helper functions
getAirportDetails = (iata, callback) ->
  database.airports.findOne { iata: iata }, callback

# Providers
exports.name = "eviterra"

exports.query = !(origin, destination, extra, cb) ->
  evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=#{origin.iata}&to=#{destination.iata}&date1=#{origin.date}&adults=#{extra.adults}"

  (error, response, body) <-! request evUrl
  console.log ">>> queried eviterra serp | #{evUrl} | status #{response.statusCode}"
  return if error

  (error, json) <- parser.parseString response.body
  return if error
  
  cb json

exports.process = !(flights, cb) -> 
  console.log ">>> processing eviterra serp"

  if not flights or not flights.variant
    return

  Sync ->

    newFlights = []
    for variant in flights.variant

      if variant.segment.flight.length?
        transferNumber  = variant.segment.flight.length
        firstFlight     = variant.segment.flight[0]
        lastFlight      = variant.segment.flight[transferNumber-1]
      
      else
        transferNumber  = 1
        firstFlight     = variant.segment.flight
        lastFlight      = firstFlight               

      arrivalDestinationDate  = moment lastFlight.arrivalDate     + 'T' + lastFlight.arrivalTime
      departureOriginDate     = moment firstFlight.departureDate  + 'T' + firstFlight.departureTime
      
      departureAirport  = getAirportDetails.sync null, firstFlight.departure
      arrivalAirport    = getAirportDetails.sync null, lastFlight.arrival

      # UTC massage
      utcArrivalDate    = arrivalDestinationDate.clone().subtract 'hours', arrivalAirport.timezone  
      utcDepartureDate  = departureOriginDate.clone().subtract    'hours', departureAirport.timezone

      flightTimeSpan    = utcArrivalDate.diff utcDepartureDate,   'hours'
        
      flightTimeSpan    = 1 if (flightTimeSpan is 0)

      newFlight = 
        arrival:        arrivalDestinationDate.format('LL')
        departure:      departureOriginDate.format('LL')
        price:          parseInt(variant.price)
        timeSpan:       flightTimeSpan
        transferNumber: transferNumber - 1
        url:            variant.url + "ostroterra"
        provider:       "eviterra"

      newFlights.push newFlight

    cb newFlights

exports.autocomplete = !(query, callback) ->
  eviterraUrl = "https://eviterra.com/complete.json?val=#{query}"
  (error, response, body) <-! request eviterraUrl
  console.log ">>> queried eviterra autocomplete | #{eviterraUrl} | status #{response.statusCode}"
  return callback(error, null) if error

  json = JSON.parse(response.body)  
  finalJson = []
  
  for item in json.data when item.type is 'city'

    name        = item.name
    country     = item.area
    iata        = item.iata
    displayName = name

    if country isnt "Россия"
      displayName += ", #{country}"

    finalJson.push {
      name:         name
      iata:         iata
      country:      country
      displayName:  displayName
      provider:     exports.name
    }

  callback null, finalJson
