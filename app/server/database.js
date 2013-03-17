(function(){
  var Mongolian, server, db;
  Mongolian = require("mongolian");
  server = new Mongolian();
  db = server.db("ostroterra");
  exports.airports = db.collection('airports');
  exports.airports.ensureIndex({
    iata: 1
  }, {
    unique: true
  });
  exports.suggest = db.collection('suggest');
  exports.suggest.ensureIndex({
    query: 1
  }, {
    unique: true
  });
  exports.search = db.collection('search');
  exports.search.ensureIndex({
    hash: 1
  }, {
    unique: true
  });
  exports.geonames = db.collection('geonames');
  exports.geonames.ensureIndex({
    geoname_id: 1
  }, {
    unique: true
  });
  exports.geonames.ensureIndex({
    name_ru_lower: 1
  });
  exports.geonames.ensureIndex({
    name_ru: 1
  });
  exports.airlines = db.collection('airlines');
  exports.airlines.ensureIndex({
    iata: 1
  }, {
    unique: true
  });
  exports.hotels = db.collection('hotels');
  exports.hotels.ensureIndex({
    id: 1,
    provider: 1
  }, {
    unique: true
  });
  exports.countries = db.collection('countries');
  exports.countries.ensureIndex({
    geoname_id: 1
  }, {
    unique: true
  });
  exports.countries.ensureIndex({
    code: 1
  }, {
    unique: true
  });
  exports.users = db.collection('users');
  exports.countries.ensureIndex({
    id: 1
  }, {
    unique: true
  });
  exports.trips = db.collection('trips');
  exports.trips.ensureIndex({
    trip_hash: 1
  }, {
    unique: true
  });
  exports.trips.ensureIndex({
    search_hash: 1
  });
  exports.conversions = db.collection('conversions');
  exports.invites = db.collection('invites');
  exports.invites.ensureIndex({
    guid: 1
  });
  exports.normalized_searches = db.collection('normalized_searches');
  exports.normalized_trips = db.collection('normalized_trips');
}).call(this);
