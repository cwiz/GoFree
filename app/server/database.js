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
  exports.cache = db.collection('cache');
  exports.cache.ensureIndex({
    hash: 1
  }, {
    unique: true
  });
}).call(this);
