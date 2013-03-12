_               = require "underscore"
async           = require "async"
cache           = require "./../../cache"
database        = require "./../../database"
moment          = require "moment"
request         = require "request"
jsdom           = require("jsdom").jsdom

exports.name    = "airbnb"

exports.search = (origin, destination, extra, cb) ->

    numPages  = 20
    operations = _.map [0 til numPages], (i) ->

        return (cb) ->

            airUrl = "https://m.airbnb.com/api/v1/listings/search?checkin=#{origin.date}&checkout=#{destination.date}&location=#{destination.place.country_name_ru}--#{destination.place.name_ru}&number_of_guests=#{extra.adults}&offset=#{i*20}"

            (error, body) <- cache.request airUrl
            return cb error, null if error

            try
              json = JSON.parse body
            catch error
              return cb error, null
            
            return cb {message: 'no listings'}, null if not json.listings

            results = _.map json.listings, (r) ->
                
                listing = r.listing

                days = moment.duration(moment(destination.date) - moment(origin.date)).days()

                hotel =
                  name          : listing.name
                  stars         : null
                  price         : listing.price * 30 * days
                  rating        : null
                  photo         : listing.medium_url
                  provider      : \airbnb
                  id            : listing.id
                  type          : 'apartment'
                  url           : "https://www.airbnb.com/rooms/#{listing.id}"
                  reviews_count : listing.reviews_count
                  
                  latitude      : listing.lat
                  longitude     : listing.lng
                  images        : listing.picture_urls
                  address       : listing.address

                dbHotel = ^^hotel
                delete dbHotel.price
                
                database.hotels.insert dbHotel
                
                return hotel

            cb null, results

    async.parallel operations, (error, results) ->

        return cb error, {} if error

        cb null, {
            results : _.flatten(results),
            complete: true
        }

exports.details = (id, callback) ->

  (error, hotel) <- database.hotels.findOne do 
    provider: exports.name
    id      : id

  return callback error, null if (error or not hotel)

  if not hotel.description

    url = "https://www.airbnb.com/rooms/#{id}"
    (error, airBnbPage) <- cache.request url
    return callback error, null if error

    (error, jQuery) <- cache.request "http://code.jquery.com/jquery.js"
    return callback error, null if error

    jsdom.env do
      html    : airBnbPage
      src     : [jQuery],
      done    : (errors, window) ->      
        return callback errors, null if errors

        hotel.description = window.$('#description_text_wrapper').html!
        database.hotels.update {_id: hotel._id}, { $set: description : hotel.description }, true

        delete hotel._id
        callback null, hotel
  
  else
    delete hotel._id
    callback null, hotel
