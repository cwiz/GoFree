(function(){
  var _, cache;
  _ = require("underscore");
  cache = require("./../../cache");
  exports.getNeareasAirport = function(origin, destniation, cb){
    var r2rUrl;
    r2rUrl = "http://evaluate.rome2rio.com/api/1.2/json/Search?key=YK8wH2AY&oName=" + origin.place.name + ", " + origin.place.country_name + "&dName=" + destniation.place.name + ", " + destniation.place.country_name;
    return cache.request(r2rUrl, function(error, body){
      var json, routes, bestRoute, flightStops;
      if (error) {
        return cb(error, null);
      }
      json = JSON.parse(body);
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
