(function(){
  var Mongolian, server, db, airports, suggest;
  Mongolian = require("mongolian");
  server = new Mongolian;
  db = server.db("ostroterra");
  airports = db.collection('airports');
  suggest = db.collection('suggest');
  airports.ensureIndex({
    iata: 1
  });
  suggest.ensureIndex({
    query: 1
  });
  exports.suggest = db.collection("suggest");
  exports.airports = db.collection("airports");
}).call(this);
