(function(){
  var _, async, database;
  _ = require("underscore");
  async = require("async");
  database = require("./../database");
  exports.autocomplete = function(req, res){
    var query, regexp_query;
    query = req.params.query;
    if (!query) {
      res.send({
        status: "error",
        message: "Please supply 'q' GET param."
      });
    }
    query = query.toLowerCase().replace('-', '_').replace(' ', '_');
    regexp_query = new RegExp("^" + query);
    return database.geonames.find({
      $or: [
        {
          name_lower: regexp_query
        }, {
          name_ru_lower_collection: regexp_query
        }
      ],
      population: {
        $gte: 10000
      },
      name_ru_collection: {
        $ne: []
      }
    }).limit(10).sort({
      population: -1
    }).toArray(function(err, results){
      var i$, len$, r, j$, ref$, len1$, i, name_ru_lower;
      if (err) {
        res.send({
          status: 'error',
          error: err
        });
      }
      for (i$ = 0, len$ = results.length; i$ < len$; ++i$) {
        r = results[i$];
        for (j$ = 0, len1$ = (ref$ = r.name_ru_lower_collection).length; j$ < len1$; ++j$) {
          i = j$;
          name_ru_lower = ref$[j$];
          if (name_ru_lower.match(regexp_query)) {
            r.name_ru_lower = name_ru_lower;
            r.name_ru = r.name_ru_collection[i];
            r.name_ru_inflected = r.name_ru_inflected_collection[i];
          }
        }
        if (!r.name_ru) {
          r.name_ru = r.name_ru_collection[0];
        }
        if (!r.name_ru_inflected) {
          r.name_ru_inflected = r.name_ru_inflected_collection[0];
        }
        if (!r.name_ru_lower) {
          r.name_ru_lower = r.name_ru_lower_collection[0];
        }
        delete r._id;
      }
      return res.send({
        status: "ok",
        value: results
      });
    });
  };
}).call(this);
