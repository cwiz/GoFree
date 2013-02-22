(function(){
  var _, async, moment, request, cache;
  _ = require("underscore");
  async = require("async");
  moment = require("moment");
  request = require("request");
  cache = require("./../../cache");
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
            var listing, days;
            listing = r.listing;
            days = moment.duration(moment(destination.date) - moment(origin.date)).days();
            return {
              name: listing.name,
              stars: null,
              price: listing.price * 30 * days,
              rating: null,
              photo: listing.medium_url,
              provider: 'airbnb',
              id: r.id,
              type: 'apartment'
            };
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
}).call(this);
