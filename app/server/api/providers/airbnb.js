(function(){
  var _, async, request;
  _ = require("underscore");
  async = require("async");
  request = require("request");
  exports.name = "airbnb";
  exports.search = function(origin, destination, extra, cb){
    var operations;
    operations = _.map([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], function(i){
      return function(cb){
        var airUrl;
        airUrl = "https://m.airbnb.com/api/v1/listings/search?checkin=" + origin.date + "&checkout=" + destination.date + "&location=" + destination.place.country_name_ru + "--" + destination.place.name_ru + "&number_of_guests=" + extra.adults + "&offset=" + i * 20;
        return request(airUrl, function(error, response, body){
          var json, results;
          console.log("AIRBNB: Queried serp | " + airUrl + " | status " + response.statusCode);
          if (error) {
            return cb(error, null);
          }
          json = JSON.parse(response.body);
          if (!json.listings) {
            return cb({
              message: 'no listings'
            }, null);
          }
          results = _.map(json.listings, function(r){
            var listing;
            listing = r.listing;
            return {
              name: listing.name,
              stars: null,
              price: listing.price * 30,
              rating: null,
              photo: listing.medium_url,
              provider: 'airbnb',
              id: r.id
            };
          });
          return cb(null, results);
        });
      };
    });
    return async.parallel(operations, function(error, results){
      return cb(null, {
        results: _.flatten(results),
        complete: true
      });
    });
  };
}).call(this);
