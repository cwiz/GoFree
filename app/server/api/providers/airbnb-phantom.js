(function(){
  var async, database, request, phantom, _page, getPage, process;
  async = require("async");
  database = require("./../../database");
  request = require("request");
  phantom = require('phantom');
  exports.name = "airbnb";
  _page = null;
  getPage = function(cb){
    if (!_page) {
      return phantom.create(function(ph){
        return ph.createPage(function(_page){
          return cb(_page);
        });
      });
    } else {
      return cb(_page);
    }
  };
  process = function(results){
    var output, i$, len$, r, newResult;
    output = [];
    for (i$ = 0, len$ = results.length; i$ < len$; ++i$) {
      r = results[i$];
      newResult = {
        name: r.name,
        stars: null,
        price: r.price,
        rating: null,
        photo: r.thumbnail_url.replace('_small', '_large'),
        provider: 'airbnb',
        id: r.id
      };
      output.push(newResult);
    }
    return output;
  };
  exports.search = function(origin, destination, extra, cb, i){
    var airUrl;
    if (!i) {
      i = 0;
    }
    airUrl = "https://www.airbnb.ru/s/" + destination.place.country_name_ru + "--" + destination.place.name_ru + "?checkin=" + origin.date + "&checkout=" + destination.date + "?page=" + extra.page;
    return getPage(function(page){
      return page.open(airUrl, function(status){
        console.log("AIRBNB: queried page | " + airUrl + " | status " + status);
        return page.evaluate(function(){
          return AirbnbSearch.resultsJson;
        }, function(result){
          var ref$, hasResults, results;
          hasResults = (ref$ = result.properties) != null ? ref$.length : void 8;
          console.log("AIRBNB: page: " + extra.page + " | # results found: " + hasResults);
          if (!hasResults) {
            return cb(null, {
              results: [],
              complete: true
            });
          }
          results = process(result.properties);
          cb(null, {
            results: results,
            complete: false
          });
          extra.page += 1;
          i += 1;
          if (i >= 5) {
            return cb(null, {
              results: [],
              complete: true
            });
          }
          return exports.search(origin, destination, extra, cb, i);
        });
      });
    });
  };
}).call(this);
