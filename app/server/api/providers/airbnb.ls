_               = require "underscore"
async           = require "async"
cache           = require "./../../cache"
database        = require "./../../database"
moment          = require "moment"
request         = require "request"

exports.name = "airbnb"

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
                
                return hotel

            cb null, results

    async.parallel operations, (error, results) ->

        if error
          return cb error, {}

        cb null, {
            results : _.flatten(results),
            complete: true
        }
