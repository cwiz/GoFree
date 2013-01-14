(function(){
  var request, url;
  request = require("request");
  url = require("url");
  exports.name = "travelmenu";
  exports.autocomplete = function(query, callback){
    var tmUrl, urlString;
    query = query.replace(' ', '-');
    tmUrl = url.parse("http://www.travelmenu.ru/a_search/hotel.loadLocations?limit=10&language=ru", true);
    tmUrl.query['text'] = query;
    tmUrl.search = null;
    urlString = url.format(tmUrl);
    return request(urlString, function(error, response, body){
      var json, finalJson, i$, ref$, len$, obj, name, country, id, displayName;
      console.log(">>> queried travelmenu autocomplete | " + urlString + " | status " + response.statusCode);
      if (error) {
        return callback(error, null);
      }
      json = JSON.parse(response.body);
      finalJson = [];
      for (i$ = 0, len$ = (ref$ = json.list).length; i$ < len$; ++i$) {
        obj = ref$[i$];
        if (obj.cit) {
          name = obj.cit;
          country = obj.cot;
          id = obj.cid;
          displayName = name;
          if (name.split(',').length > 1) {
            name = name.split(',')[0];
          }
          if (name === "Юг Сан Франциско") {
            name = "Сан Франциско";
          }
          if (country === 'Соединенные Штаты Америки') {
            country = "США";
          }
          if (country !== "Россия") {
            displayName += ", " + country;
          }
          finalJson.push({
            name: name,
            tmid: id,
            country: country,
            displayName: displayName,
            provider: exports.name
          });
        }
      }
      callback(null, finalJson);
    });
  };
}).call(this);
