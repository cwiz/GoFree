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
          name_ru_lower: regexp_query
        }, {
          name_lower: regexp_query
        }
      ],
      population: {
        $gte: 10000
      },
      name_ru: {
        $ne: null
      }
    }).limit(10).sort({
      population: -1
    }).toArray(function(err, results){
      var i$, len$, r;
      if (err) {
        res.send({
          status: 'error',
          error: err
        });
      }
      for (i$ = 0, len$ = results.length; i$ < len$; ++i$) {
        r = results[i$];
        delete r._id;
      }
      return res.send({
        status: "ok",
        value: results
      });
    });
  };
}).call(this);
