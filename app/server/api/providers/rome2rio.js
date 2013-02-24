(function(){
  var _, cache, querystring;
  _ = require("underscore");
  cache = require("./../../cache");
  querystring = require("querystring");
  exports.getNeareasAirport = function(origin, destniation, cb){
    var params, r2rUrl;
    params = {
      key: 'YK8wH2AY',
      oName: origin.place.name + ", " + origin.place.country_name,
      dName: destniation.place.name + ", " + destniation.place.country_name
    };
    r2rUrl = "http://evaluate.rome2rio.com/api/1.2/json/Search?" + querystring.stringify(params);
    return cache.request(r2rUrl, function(error, body){
      var json, routes, bestRoute, flightStops;
      if (error) {
        return cb(error, null);
      }
      try {
        json = JSON.parse(body);
      } catch (e$) {
        error = e$;
        return cb({
          message: error
        }, null);
      }
      routes = json.routes;
      if (routes.length === 0) {
        return cb({
          message: 'no routes dound'
        }, null);
      }
      bestRoute = routes[0];
      flightStops = _.filter(bestRoute.stops, function(stop){
        return stop.kind === 'airport';
      });
      if (flightStops.length === 0) {
        return cb({
          message: 'no airports in the route'
        }, null);
      }
      return cb(null, flightStops[flightStops.length - 1].code);
    });
  };
}).call(this);
