_           = require "underscore"
async       = require "async"
cache       = require "./../../cache"
database    = require "./../../database"
moment      = require "moment"
request     = require "request"
url         = require "url"

exports.name = "flatora.ru"

getCities = (callback) ->
    
    cityListUrl = "http://flatora.ru/api/v1/city/json/getList"

    (error, result) <- cache.request cityListUrl
    return cb error, null if error 

    try
        json = JSON.parse result
    catch 
        return callback message: "couldn't parse JSON", null 

    if json?.status is \success and json.data?.response
        cities = _.filter json.data?.response, (city) -> !!city.status
        return callback null, cities if cities
    
    callback message: 'bad response', null

getFlatoraId = (place, callback) ->
    return callback null, place.flatora_id if place.flatora_id

    (error, cities) <- getCities!
    return callback error, null if error

    matchingCities  = _.filter cities, (city) -> city.title is place.name_ru
    matchingCity    = matchingCities[0]
    
    return callback message: 'no matching city found', null if not matchingCity

    callback null, matchingCity.id
    database.geonames.update {geoname_id : place.geoname_id}, $set : flatora_id : matchingCity.id

exports.details = (id, callback) ->

    (error, apartment) <- database.hotels.findOne do
        provider: exports.name
        id      : id

    return callback null, apartment if apartment

    accomodationUrl = "http://flatora.ru/api/v1/accommodation/json/getByIds?ids[]=#{id}"

    (error, result) <- cache.request accomodationUrl
    return callback error, null if error

    try
        json = JSON.parse result
    catch 
        return callback message: "couldn't parse JSON", null 

    return callback message: 'bad response', null if not (json?.status is \success and json.data?.response)
    
    accommodations          = json.data?.response
    filteredAccommodation   = _.filter accommodations, (accommodation) -> accommodation.id is id
    accommodation           = filteredAccommodation[0]

    return callback message : "no accomodation found", null if not accommodation

    images = _.map accommodation.photos, (image) -> 
        "http://img.flatora.ru/images/accommodation/#{accommodation.id}/large/#{image.fileName}"

    apartment =
        address     : accommodation.address
        description : null
        id          : accommodation.id
        images      : images
        latitude    : accommodation.lng
        longitude   : accommodation.lat
        name        : accommodation.title
        photo       : images[0]
        price       : accommodation.priceNight * 1.1 / 100
        provider    : exports.name
        rating      : null
        stars       : null
        type        : 'apartment'
        url         : "http://flatora.ru/flat_#{accommodation.id}.html"

    database.hotels.insert apartment

    return callback null, apartment

query = (origin, destination, extra, cb) ->

    (error, destinationId) <- getFlatoraId destination.place
    return cb error, null if error

    accomodationListUrl = "http://flatora.ru/api/v1/accommodation/json/searchWithParams?location[cityIds][]=#{destinationId}&currencyId=1&minPrice=0&maxPrice=999999999&limit=9999&offset=0"

    (error, result) <- cache.request accomodationListUrl
    return cb error, null if error 

    try
        json = JSON.parse result
    catch 
        return cb message: "couldn't parse JSON", null 

    if json?.status is \success and json.data?.response
        accommodations = json.data?.response
        return cb null, accommodations

    cb message: 'bad response', null

process = (accommodations, origin, destination, cb) ->

    operations = _.map accommodations, (accommodation) ->
        (callback) -> exports.details accommodation.id, callback

    (error, results) <- async.parallel operations
    return cb error or {message : 'couldnt find anything', null if not results

    checkin = moment origin.date
    checkout= moment destination.date
    nights  = checkout.diff checkin, "days"

    results = _.filter results, (result) -> result?
    results = _.filter results, (result) -> 
        filtered = true
        
        if result.nightMinCount
            filtered = filtered and result.nightMinCount <= nights

        if result.nightMaxCount
            filtered = filtered and result.nightMaxCount >= nights

        return filtered
    
    results = _.map     results, (result) -> 
        result.price *= nights
        return result

    cb null, do
        results : results
        complete: true

exports.search = (origin, destination, extra, cb) ->
    return if destination.place.country_code is not \RU

    (error, json)     <- query origin, destination, extra
    return cb error, null if error

    (error, results)  <- process json, origin, destination
    return cb error, null if error

    cb null, results

