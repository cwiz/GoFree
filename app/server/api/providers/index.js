(function(){
  var airbnb, eviterra, ostrovok, aviasales, flatora;
  airbnb = require("./airbnb");
  eviterra = require("./eviterra");
  ostrovok = require("./ostrovok");
  aviasales = require("./aviasales");
  flatora = require("./flatora");
  exports.hotelProviders = [flatora, ostrovok, airbnb];
  exports.flightProviders = [aviasales, aviasales];
  exports.allProviders = exports.hotelProviders.concat(exports.flightProviders);
}).call(this);
