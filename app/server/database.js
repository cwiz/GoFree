(function(){
  var Mongolian, server, db;
  Mongolian = require("mongolian");
  server = new Mongolian();
  db = server.db("ostroterra");
  exports.airports = db.collection('airports');
  exports.suggest = db.collection('suggest');
  exports.search = db.collection('search');
  exports.geonames = db.collection('geonames');
  exports.airlines = db.collection('airlines');
  exports.hotels = db.collection('hotels');
  exports.countries = db.collection('countries');
  exports.users = db.collection('users');
  exports.trips = db.collection('trips');
  exports.conversions = db.collection('conversions');
  exports.links = db.collection('links');
  exports.normalized_searches = db.collection('normalized_searches');
  exports.normalized_trips = db.collection('normalized_trips');
}).call(this);
