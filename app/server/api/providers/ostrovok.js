(function(){
  var async, cache, database, request, getOstrovokId, query, process, autocomplete;
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  request = require("request");
  exports.name = "ostrovok.ru";
  getOstrovokId = function(place, callback){
    if (place.ostrovok_id) {
      return callback(null, place.ostrovok_id);
    }
    return autocomplete(place.name_ru + ", " + place.country_name_ru, function(error, result){
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
  query = function(origin, destination, extra, cb){
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
      return cache.request(ostUrl, function(error, body){
        var json, page;
        console.log("OSTROVOK: Queried ostrovok serp | " + ostUrl + " | success: " + !!body);
        if (error) {
          return cb(error, null);
        }
        json = JSON.parse(body);
        page = json._next_page;
        cb(null, json);
        if (page) {
          extra.page = page;
          return query(origin, destination, extra, cb);
        }
      });
    });
  };
  process = function(json, cb){
    var hotels, rates, ref$, newHotels, i$, len$, hotel, rating, count, price, stars, newHotel, dbHotel;
    if (!json || json.hotels == null) {
      return cb('empty json', null);
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
          stars = hotel.star_rating / 10.0;
        }
        newHotel = {
          id: hotel.ostrovok_id,
          name: hotel.name,
          photo: hotel.thumbnail_url_220,
          price: price,
          provider: exports.name,
          rating: rating,
          stars: stars,
          type: 'hotel',
          url: "http://ostrovok.ru" + hotel.url + "&partner_slug=ostroterra",
          latitude: hotel.latitude,
          longitude: hotel.longitude,
          description: hotel.description_short,
          address: hotel.address,
          images: [hotel.thumbnail_url_220, hotel.thumbnail_url_220, hotel.thumbnail_url_220, hotel.thumbnail_url_220]
        };
        dbHotel = clone$(newHotel);
        delete dbHotel.price;
        database.hotels.insert(dbHotel);
        newHotels.push(newHotel);
      }
    }
    return cb(null, {
      results: newHotels,
      complete: !json._next_page
    });
  };
  exports.search = function(origin, destination, extra, cb){
    return query(origin, destination, extra, function(error, hotelResult){
      if (error) {
        return cb(error, null);
      }
      return process(hotelResult, function(error, hotels){
        if (error) {
          return cb(error, null);
        }
        return cb(null, hotels);
      });
    });
  };
  exports.details = function(id, callback){
    return database.hotels.findOne({
      provider: exports.name,
      id: id
    }, function(error, hotel){
      console.log(hotel);
      if (error || !hotel) {
        return callback(error, null);
      }
      return callback(null, hotel);
    });
  };
  autocomplete = function(query, callback){
    var ostUrl;
    ostUrl = "http://ostrovok.ru/api/site/multicomplete.json?query=" + query + "&regions_ver=v5";
    return cache.request(ostUrl, function(error, body){
      var json, finalJson, i$, ref$, len$, obj, country, name, id, displayName;
      console.log("ostrovok.autocomplete | " + ostUrl + " | status " + !!body);
      if (error) {
        return callback(error, null);
      }
      json = JSON.parse(body);
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
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
