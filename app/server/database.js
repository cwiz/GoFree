(function(){
  var Mongolian, server, db;
  Mongolian = require("mongolian");
  server = new Mongolian();
  db = server.db("ostroterra");
  exports.airports = db.collection('airports');
  exports.suggest = db.collection('suggest');
  exports.airports.ensureIndex({
    iata: 1
  });
  exports.suggest.ensureIndex({
    query: 1
  });
}).call(this);
