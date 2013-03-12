(function(){
  var _, async, cache, database, moment, request, jsdom;
  _ = require("underscore");
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  jsdom = require("jsdom").jsdom;
  exports.name = "airbnb";
  exports.search = function(origin, destination, extra, cb){
    var numPages, operations;
    numPages = 20;
    operations = _.map((function(){
      var i$, to$, results$ = [];
      for (i$ = 0, to$ = numPages; i$ < to$; ++i$) {
        results$.push(i$);
      }
      return results$;
    }()), function(i){
      return function(cb){
        var airUrl;
        airUrl = "https://m.airbnb.com/api/v1/listings/search?checkin=" + origin.date + "&checkout=" + destination.date + "&location=" + destination.place.country_name_ru + "--" + destination.place.name_ru + "&number_of_guests=" + extra.adults + "&offset=" + i * 20;
        return cache.request(airUrl, function(error, body){
          var json, results;
          if (error) {
            return cb(error, null);
          }
          try {
            json = JSON.parse(body);
          } catch (e$) {
            error = e$;
            return cb(error, null);
          }
          if (!json.listings) {
            return cb({
              message: 'no listings'
            }, null);
          }
          results = _.map(json.listings, function(r){
            var listing, days, hotel, dbHotel;
            listing = r.listing;
            days = moment.duration(moment(destination.date) - moment(origin.date)).days();
            hotel = {
              name: listing.name,
              stars: null,
              price: listing.price * 30 * days,
              rating: null,
              photo: listing.medium_url,
              provider: 'airbnb',
              id: listing.id,
              type: 'apartment',
              url: "https://www.airbnb.com/rooms/" + listing.id,
              reviews_count: listing.reviews_count,
              latitude: listing.lat,
              longitude: listing.lng,
              images: listing.picture_urls,
              address: listing.address
            };
            dbHotel = clone$(hotel);
            delete dbHotel.price;
            database.hotels.insert(dbHotel);
            return hotel;
          });
          return cb(null, results);
        });
      };
    });
    return async.parallel(operations, function(error, results){
      if (error) {
        return cb(error, {});
      }
      return cb(null, {
        results: _.flatten(results),
        complete: true
      });
    });
  };
  exports.details = function(id, callback){
    return database.hotels.findOne({
      provider: exports.name,
      id: id
    }, function(error, hotel){
      var url;
      if (error || !hotel) {
        return callback(error, null);
      }
      if (!hotel.description) {
        url = "https://www.airbnb.com/rooms/" + id;
        return cache.request(url, function(error, airBnbPage){
          if (error) {
            return callback(error, null);
          }
          return cache.request("http://code.jquery.com/jquery.js", function(error, jQuery){
            if (error) {
              return callback(error, null);
            }
            return jsdom.env({
              html: airBnbPage,
              src: [jQuery],
              done: function(errors, window){
                if (errors) {
                  return callback(errors, null);
                }
                hotel.description = window.$('#description_text_wrapper').html();
                database.hotels.update({
                  _id: hotel._id
                }, {
                  $set: {
                    description: hotel.description
                  }
                }, true);
                delete hotel._id;
                return callback(null, hotel);
              }
            });
          });
        });
      } else {
        delete hotel._id;
        return callback(null, hotel);
      }
    });
  };
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
