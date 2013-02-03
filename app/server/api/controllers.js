(function(){
  var request, database, async, fs, ostrovok, eviterra, travelmenu, glueAutocompleteResults, queryFlickr;
  request = require("request");
  database = require("./../database");
  async = require("async");
  fs = require("fs");
  ostrovok = require("./providers/ostrovok");
  eviterra = require("./providers/eviterra");
  travelmenu = require("./providers/travelmenu-hotels");
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
  queryFlickr = function(query, callback){
    var flickrKey, flickrSecret, flickrUrl;
    flickrKey = "7925109a48c26fe53555687f9d46a076";
    flickrSecret = "c936db59c720b4d5";
    flickrUrl = "http://api.flickr.com/services/rest/?per_page=5&sort=relevance&format=json&content_type=1&nojsoncallback=1&method=flickr.photos.search&api_key=" + flickrKey + "&text=" + query;
    return request(flickrUrl, function(error, response, body){
      var json, randomIndex, photo;
      console.log(">>> queried flickr search | " + flickrUrl + " | error: " + error + " | status " + (response != null ? response.statusCode : void 8));
      if (error || !(response.statusCode === 200)) {
        return;
      }
      json = JSON.parse(response.body);
      randomIndex = Math.floor(Math.random() * (json.photos.photo.length - 1));
      photo = json.photos.photo[randomIndex];
      if (photo) {
        return callback(null, "http://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + "_b.jpg");
      }
      return callback({
        message: 'nothing found'
      }, null);
    });
  };
  exports.image = function(req, res){
    var query;
    query = encodeURIComponent(req.params.query);
    return queryFlickr(query, function(error, image){
      if (error) {
        return res.json({
          status: 'error',
          message: error
        });
      }
      return res.json({
        status: 'ok',
        value: {
          image: image
        }
      });
    });
  };
  exports.image_v2 = function(req, res){
    var country, city;
    country = encodeURIComponent(req.params.country).toLowerCase();
    city = encodeURIComponent(req.params.city).toLowerCase();
    return fs.exists("./public/img/cities/" + country + "--" + city + "-blured.jpg", function(exists){
      console.log(exists);
      if (exists) {
        return res.json({
          status: 'ok',
          value: {
            blured: "/img/cities/" + country + "--" + city + "-blured.jpg",
            sharp: "/img/cities/" + country + "--" + city + "-resized.jpg"
          }
        });
      }
      return queryFlickr(city, function(error, image){
        if (error) {
          return res.json({
            status: 'error',
            message: error
          });
        }
        return res.json({
          status: 'ok',
          value: {
            blured: image,
            sharp: image
          }
        });
      });
    });
  };
}).call(this);
