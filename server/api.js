(function(){
  var request, database, async, ostrovok, eviterra, travelmenu, glueAutocompleteResults;
  request = require("request");
  database = require("./database.js");
  async = require("async");
  ostrovok = require("./providers/ostrovok.js");
  eviterra = require("./providers/eviterra.js");
  travelmenu = require("./providers/travelmenu-hotels.js");
  exports.autocomplete = function(req, res){
    var emitResults, query, x$;
    emitResults = function(results){
      return res.send({
        status: "ok",
        value: results
      });
    };
    query = req.params.query;
    if (!query) {
      x$ = res.send;
      ({
        status: "error",
        message: "please supply q GET param"
      });
    }
    return database.suggest.findOne({
      query: query
    }, function(err, results){
      var providerCallbacks;
      console.log("searched mongodb for " + query);
      if (results) {
        return emitResults(results.results);
      }
      providerCallbacks = {
        ostrovok: function(callback){
          return ostrovok.autocomplete(query, callback);
        },
        eviterra: function(callback){
          return eviterra.autocomplete(query, callback);
        },
        travelmenu: function(callback){
          return travelmenu.autocomplete(query, callback);
        }
      };
      return async.parallel(providerCallbacks, function(err, autocompleteResults){
        return glueAutocompleteResults(autocompleteResults, function(results){
          database.suggest.insert({
            query: query,
            results: results
          });
          return emitResults(results);
        });
      });
    });
  };
  glueAutocompleteResults = function(results, cb){
    var ostrovok, eviterra, travelmenu, finalResults, pushResults, i$, len$, o, j$, len1$, e, tmRecord, k$, len2$, t;
    ostrovok = results.ostrovok;
    if (!ostrovok) {
      return cb("ostrovok null", null);
    }
    eviterra = results.eviterra;
    if (!eviterra) {
      return cb("eviterra null", null);
    }
    travelmenu = results.travelmenu;
    if (!travelmenu) {
      return cb("travelmenu null", null);
    }
    finalResults = [];
    pushResults = function(ostrovok, eviterra, travelmenu){
      var tmId;
      tmId = null;
      if (travelmenu) {
        tmId = travelmenu.tmid;
      }
      return finalResults.push({
        oid: ostrovok.oid,
        tmid: tmId,
        iata: eviterra.iata,
        name: eviterra.name
      });
    };
    for (i$ = 0, len$ = ostrovok.length; i$ < len$; ++i$) {
      o = ostrovok[i$];
      for (j$ = 0, len1$ = eviterra.length; j$ < len1$; ++j$) {
        e = eviterra[j$];
        if (o.name === e.name && o.country === e.country) {
          tmRecord = null;
          for (k$ = 0, len2$ = travelmenu.length; k$ < len2$; ++k$) {
            t = travelmenu[k$];
            if (o.name === t.name && t.country === o.country) {
              tmRecord = t;
              break;
            }
          }
          pushResults(o, e, t);
        }
      }
    }
    return cb(finalResults);
  };
  exports.image = function(req, res){
    var query, flickrKey, flickrSecret, flickrUrl;
    query = encodeURIComponent(req.params.query);
    flickrKey = "7925109a48c26fe53555687f9d46a076";
    flickrSecret = "c936db59c720b4d5";
    flickrUrl = "http://api.flickr.com/services/rest/?per_page=10&sort=relevance&format=json&content_type=1&nojsoncallback=1&method=flickr.photos.search&api_key=" + flickrKey + "&text=" + query;
    return request(flickrUrl, function(error, response, body){
      var json, randomIndex, photo;
      console.log(">>> queried flickr search | " + flickrUrl + " | status " + response.statusCode);
      if (error || !(response.statusCode === 200)) {
        return;
      }
      json = JSON.parse(response.body);
      randomIndex = Math.floor(Math.random() * json.photos.photo.length);
      photo = json.photos.photo[randomIndex];
      return res.json({
        status: 'ok',
        value: {
          image: "http://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_z.jpg"
        }
      });
    });
  };
}).call(this);
