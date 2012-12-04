(function(){
  var request;
  request = require("request");
  exports.name = "ostrovok";
  exports.query = function(origin, destination, extra, cb){
    var ostUrl;
    ostUrl = "http://ostrovok.ru/api/v1/search/page/" + extra.page + "/?region_id=" + destination.oid + "&arrivalDate=" + origin.date + "&departureDate=" + destination.date + "&room1_numberOfAdults=" + extra.adults;
    request(ostUrl, function(error, response, body){
      var json, page;
      console.log(">>> queried ostrovok serp | " + ostUrl + " | status " + response.statusCode);
      if (error) {
        return;
      }
      json = JSON.parse(response.body);
      page = json._next_page;
      cb(json);
      if (page) {
        extra.page = page;
        exports.query(origin, destination, extra, cb);
      }
    });
  };
  exports.process = function(json, cb){
    var hotels, rates, newHotels, i$, len$, hotel, rating, ref$, count, price, stars, newHotel;
    console.log(">>> processing ostrovok serp");
    if (!json || json.hotels == null) {
      return;
    }
    hotels = json.hotels;
    rates = json._meta.rates;
    newHotels = [];
    for (i$ = 0, len$ = hotels.length; i$ < len$; ++i$) {
      hotel = hotels[i$];
      if (hotel.rooms) {
        rating = 0;
        if (((ref$ = hotel.rating) != null ? ref$.total : void 8) != null) {
          count = hotel.rating.count;
          if (count > 25) {
            rating = hotel.rating.total * count;
          }
        }
        price = hotel.rooms[0].total_rate * rates[hotel.rooms[0].currency];
        stars = 1;
        if (hotel.star_rating) {
          stars = Math.ceil(hotel.star_rating / 10.0) + 1;
        }
        newHotel = {
          name: hotel.name,
          stars: stars,
          price: price,
          rating: rating,
          url: "http://ostrovok.ru" + hotel.url + "&partner_slug=ostroterra",
          provider: "ostrovok"
        };
        newHotels.push(newHotel);
      }
    }
    cb(newHotels);
  };
  exports.autocomplete = function(query, callback){
    var ostUrl;
    ostUrl = "http://ostrovok.ru/api/site/multicomplete.json?query=" + query + "&regions_ver=v5";
    return request(ostUrl, function(error, response, body){
      var json, finalJson, i$, ref$, len$, obj, country, name, id, displayName;
      console.log(">>> queried ostrovok autocomplete | " + ostUrl + " | status " + response.statusCode);
      if (error) {
        return callback(error, null);
      }
      json = JSON.parse(response.body);
      finalJson = [];
      for (i$ = 0, len$ = (ref$ = json.regions).length; i$ < len$; ++i$) {
        obj = ref$[i$];
        if (obj.target === "search" && obj.type === 'city') {
          country = obj.country;
          name = obj.name;
          if (name === 'Нью-Дели') {
            name = 'Дели';
          }
          id = obj.id;
          displayName = name;
          if (name.split(',').length > 1) {
            name = name.split(',')[0];
          }
          if (country !== "Россия") {
            displayName += ", " + country;
          }
          finalJson.push({
            name: name,
            oid: id,
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
