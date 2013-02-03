(function(){
  var async, database, exec, fs, request, ostrovok, eviterra, travelmenu, glueAutocompleteResults, queryFlickr;
  async = require("async");
  database = require("./../database");
  exec = require("child_process").exec;
  fs = require("fs");
  request = require("request");
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
    query = query + " view";
    flickrKey = "7925109a48c26fe53555687f9d46a076";
    flickrSecret = "c936db59c720b4d5";
    flickrUrl = "http://api.flickr.com/services/rest/?per_page=5&sort=relevance&format=json&content_type=1&nojsoncallback=1&method=flickr.photos.search&api_key=" + flickrKey + "&text=" + query;
    return request(flickrUrl, function(error, response, body){
      var json, randomIndex, photo, url;
      console.log(">>> queried flickr search | " + flickrUrl + " | error: " + error + " | status " + (response != null ? response.statusCode : void 8));
      if (error || !(response.statusCode === 200)) {
        return;
      }
      json = JSON.parse(response.body);
      randomIndex = Math.floor(Math.random() * (json.photos.photo.length - 1));
      photo = json.photos.photo[randomIndex];
      if (photo) {
        url = "http://farm" + photo.farm + ".staticflickr.com/" + photo.server + "/" + photo.id + "_" + photo.secret + ".jpg";
        console.log(url);
        return callback(null, url);
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
    var country, city, shutterstockPath, shutterstockBlured, shutterstockSharp;
    country = encodeURIComponent(req.params.country.replace(/ /g, "_").toLowerCase());
    city = encodeURIComponent(req.params.city.replace(/ /g, "_").toLowerCase());
    shutterstockPath = "./public/img/cities/custom/" + country + "--" + city + "-blured.jpg";
    shutterstockBlured = "/img/cities/custom/" + country + "--" + city + "-blured.jpg";
    shutterstockSharp = "/img/cities/custom/" + country + "--" + city + "-resized.jpg";
    return fs.exists(shutterstockPath, function(shutterstockExits){
      var flickrPath, flickrBlured, flickrSharp;
      if (shutterstockExits) {
        return res.json({
          status: 'ok',
          value: {
            blured: shutterstockBlured,
            sharp: shutterstockSharp
          }
        });
      }
      flickrPath = "./public/img/cities/flickr/" + country + "--" + city + "-blured.jpg";
      flickrBlured = "/img/cities/flickr/" + country + "--" + city + "-blured.jpg";
      flickrSharp = "/img/cities/flickr/" + country + "--" + city + "-resized.jpg";
      return fs.exists(flickrPath, function(flickrExits){
        if (flickrExits) {
          return res.json({
            status: 'ok',
            value: {
              blured: flickrBlured,
              sharp: flickrBlured
            }
          });
        }
        return queryFlickr(city, function(error, image){
          var origFile, resizedFile, bluredFile;
          if (error) {
            return res.json({
              status: 'error',
              message: error
            });
          }
          origFile = "./public/img/cities/flickr/" + country + "--" + city + "-orig.jpg";
          resizedFile = "./public/img/cities/flickr/" + country + "--" + city + "-resized.jpg";
          bluredFile = "./public/img/cities/flickr/" + country + "--" + city + "-blured.jpg";
          return exec("wget " + image + " -O " + resizedFile, function(error, result){
            if (error) {
              exec("rm " + origFile);
              return res.json({
                status: 'error',
                message: error
              });
            }
            return fs.stat(resizedFile, function(error, stat){
              if (stat.size === 9218) {
                return res.json({
                  status: 'error',
                  message: error
                });
              }
              return exec("convert " + resizedFile + " -blur 0x3 -quality 0.6 " + bluredFile, function(error, result){
                return res.json({
                  status: 'ok',
                  value: {
                    blured: flickrBlured,
                    sharp: flickrBlured
                  }
                });
              });
            });
          });
        });
      });
    });
  };
}).call(this);
