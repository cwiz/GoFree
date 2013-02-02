(function(){
  var async, database, request, getOstrovokId;
  async = require("async");
  database = require("./../../database");
  request = require("request");
  exports.name = "ostrovok";
  getOstrovokId = function(place, callback){
    if (place.ostrovok_id) {
      return callback(null, place.ostrovok_id);
    }
    return exports.autocomplete(place.name_ru + ", " + place.country_name_ru, function(error, result){
      var ostrovok_id;
      if (error) {
        return callback(error, null);
      }
      if (result.length === 0) {
        return callback({
          'nothing found': 'nothing found'
        }, null);
      }
      ostrovok_id = result[0].oid;
      callback(null, ostrovok_id);
      return database.geonames.update({
        geoname_id: place.geoname_id
      }, {
        $set: {
          ostrovok_id: ostrovok_id
        }
      });
    });
  };
  exports.query = function(origin, destination, extra, cb){
    return async.parallel({
      origin: function(callback){
        return getOstrovokId(origin.place, callback);
      },
      destination: function(callback){
        return getOstrovokId(destination.place, callback);
      }
    }, function(error, ostrovokId){
      var ostUrl;
      if (error) {
        return cb(error, null);
      }
      ostUrl = "http://ostrovok.ru/api/v1/search/page/" + extra.page + "/?region_id=" + ostrovokId.destination + "&arrivalDate=" + origin.date + "&departureDate=" + destination.date + "&room1_numberOfAdults=" + extra.adults;
      console.log("Querying ostrovok serp | " + ostUrl);
      return request(ostUrl, function(error, response, body){
        var json, page;
        console.log("Queried ostrovok serp | " + ostUrl + " | status " + response.statusCode);
        if (error) {
          return cb(error, null);
        }
        json = JSON.parse(response.body);
        page = json._next_page;
        cb(null, json);
        if (page) {
          extra.page = page;
          return exports.query(origin, destination, extra, cb);
        }
      });
    });
  };
  exports.process = function(json, cb){
    var hotels, rates, ref$, newHotels, i$, len$, hotel, rating, count, price, stars, newHotel;
    console.log("ostrovok.process");
    if (!json || json.hotels == null) {
      console.log("ostrovok.process");
      cb('empty json', null);
    }
    hotels = json.hotels;
    rates = (ref$ = json._meta) != null ? ref$.rates : void 8;
    if (!rates) {
      return cb({
        message: 'no rates'
      }, null);
    }
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
          photo: null,
          url: "http://ostrovok.ru" + hotel.url + "&partner_slug=ostroterra",
          provider: 'ostrovok'
        };
        newHotels.push(newHotel);
      }
    }
    return cb(null, {
      results: newHotels,
      complete: !json._next_page
    });
  };
  exports.search = function(origin, destination, extra, cb){
    return exports.query(origin, destination, extra, function(error, hotelResult){
      if (error) {
        return cb(error, null);
      }
      return exports.process(hotelResult, function(error, hotels){
        if (error) {
          return cb(error, null);
        }
        return cb(null, hotels);
      });
    });
  };
  exports.autocomplete = function(query, callback){
    var ostUrl;
    ostUrl = "http://ostrovok.ru/api/site/multicomplete.json?query=" + query + "&regions_ver=v5";
    return request(ostUrl, function(error, response, body){
      var json, finalJson, i$, ref$, len$, obj, country, name, id, displayName;
      console.log("ostrovok.autocomplete | " + ostUrl + " | status " + response.statusCode);
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
