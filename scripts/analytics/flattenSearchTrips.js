(function(){
  var async, _, database;
  async = require("async");
  _ = require("underscore");
  database = require("./../../app/server/database.ls");
  database.normalized_searches.drop(function(err, result){
    return database.normalized_trips.drop(function(err, result){
      return database.search.find().toArray(function(err, searches){
        var newSearches, newTrips, i$, len$, s, search_object, j$, ref$, len1$, number, t, object;
        newSearches = [];
        newTrips = [];
        for (i$ = 0, len$ = searches.length; i$ < len$; ++i$) {
          s = searches[i$];
          search_object = {
            hash: s.hash,
            adults: s.adults,
            budget: s.budget
          };
          newSearches.push(search_object);
          for (j$ = 0, len1$ = (ref$ = s.trips).length; j$ < len1$; ++j$) {
            number = j$;
            t = ref$[j$];
            object = {
              hash: s.hash,
              date: t.date,
              geoname_id: t.place.geoname_id,
              number: number
            };
            newTrips.push(object);
          }
        }
        console.log("Importing " + newSearches.length + " searches.");
        console.log("Importing " + newTrips.length + " trips.");
        _.map(newSearches, function(search){
          return function(){
            return database.normalized_searches.insert(search);
          }();
        });
        _.map(newTrips, function(trip){
          return function(){
            return database.normalized_trips.insert(trip);
          }();
        });
        console.log("Flatteing OK!");
        return process.exit();
      });
    });
  });
}).call(this);
