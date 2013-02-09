(function(){
  var airbnb, eviterra, ostrovok;
  airbnb = require("./airbnb");
  eviterra = require("./eviterra");
  ostrovok = require("./ostrovok");
  exports.hotelProviders = [ostrovok, airbnb];
  exports.flightProviders = [eviterra];
  exports.allProviders = exports.hotelProviders + exports.flightProviders;
}).call(this);
