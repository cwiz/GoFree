(function(){
  var airbnb, eviterra, ostrovok, aviasales;
  airbnb = require("./airbnb");
  eviterra = require("./eviterra");
  ostrovok = require("./ostrovok");
  aviasales = require("./aviasales");
  exports.hotelProviders = [ostrovok, airbnb];
  exports.flightProviders = [eviterra, aviasales];
  exports.allProviders = exports.hotelProviders.concat(exports.flightProviders);
}).call(this);
