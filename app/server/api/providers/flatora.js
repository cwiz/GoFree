(function(){
  var _, async, cache, database, moment, request, url, getCities, getFlatoraId, detailsInBulk, query, process;
  _ = require("underscore");
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  url = require("url");
  exports.name = "flatora.ru";
  getCities = function(callback){
    var cityListUrl;
    cityListUrl = "http://flatora.ru/api/v1/city/json/getList";
    return cache.request(cityListUrl, function(error, result){
      var json, e, ref$, cities;
      if (error) {
        return cb(error, null);
      }
      try {
        json = JSON.parse(result);
      } catch (e$) {
        e = e$;
        return callback({
          message: "couldn't parse JSON"
        }, null);
      }
      if ((json != null ? json.status : void 8) === 'success' && ((ref$ = json.data) != null && ref$.response)) {
        cities = _.filter((ref$ = json.data) != null ? ref$.response : void 8, function(city){
          return !!city.status;
        });
        if (cities) {
          return callback(null, cities);
        }
      }
      return callback({
        message: 'bad response'
      }, null);
    });
  };
  getFlatoraId = function(place, callback){
    if (place.flatora_id) {
      return callback(null, place.flatora_id);
    }
    return getCities(function(error, cities){
      var matchingCities, matchingCity;
      if (error) {
        return callback(error, null);
      }
      matchingCities = _.filter(cities, function(city){
        return city.title === place.name_ru;
      });
      matchingCity = matchingCities[0];
      if (!matchingCity) {
        return callback({
          message: 'no matching city found'
        }, null);
      }
      callback(null, matchingCity.id);
      return database.geonames.update({
        geoname_id: place.geoname_id
      }, {
        $set: {
          flatora_id: matchingCity.id
        }
      }, function(error, place){});
    });
  };
  exports.details = function(id, callback){
    return database.hotels.findOne({
      provider: exports.name,
      id: id
    }, function(error, apartment){
      var accomodationUrl;
      if (apartment) {
        return callback(null, apartment);
      }
      accomodationUrl = "http://flatora.ru/api/v1/accommodation/json/getByIds?ids[]=" + id;
      return cache.request(accomodationUrl, function(error, result){
        var json, e, ref$, accommodations, filteredAccommodation, accommodation, images, apartment;
        if (error) {
          return callback(error, null);
        }
        try {
          json = JSON.parse(result);
        } catch (e$) {
          e = e$;
          return callback({
            message: "couldn't parse JSON"
          }, null);
        }
        if (!((json != null ? json.status : void 8) === 'success' && ((ref$ = json.data) != null && ref$.response))) {
          return callback({
            message: 'bad response'
          }, null);
        }
        accommodations = (ref$ = json.data) != null ? ref$.response : void 8;
        filteredAccommodation = _.filter(accommodations, function(accommodation){
          return accommodation.id === id;
        });
        accommodation = filteredAccommodation[0];
        if (!accommodation) {
          return callback({
            message: "no accomodation found"
          }, null);
        }
        images = _.map(accommodation.photos, function(image){
          return "http://img.flatora.ru/images/accommodation/" + accommodation.id + "/large/" + image.fileName;
        });
        apartment = {
          address: accommodation.address,
          description: null,
          id: accommodation.id,
          images: images,
          latitude: accommodation.lng,
          longitude: accommodation.lat,
          name: accommodation.title,
          photo: images[0],
          price: accommodation.priceNight * 1.1 / 100,
          provider: exports.name,
          rating: null,
          stars: null,
          type: 'apartment',
          url: "http://flatora.ru/flat_" + accommodation.id + ".html"
        };
        callback(null, apartment);
        return database.hotels.insert(apartment, function(error, apartment){});
      });
    });
  };
  detailsInBulk = function(ids, callback){
    return database.hotels.find({
      provider: exports.name,
      id: {
        $in: ids
      }
    }).toArray(function(error, hotels){
      var hotelIdsInDatabase, hotelIdsNotInDatabase, operations;
      hotelIdsInDatabase = _.map(hotels, function(hotel){
        return hotel.id;
      });
      hotelIdsNotInDatabase = _.without(ids, hotelIdsInDatabase);
      operations = _.map(hotelIdsNotInDatabase, function(id){
        return function(cb){
          return exports.details(id, cb);
        };
      });
      return async.series(operations, function(error, results){
        var hotels;
        if (results) {
          hotels = _.union(hotels, results);
        }
        return callback(null, hotels);
      });
    });
  };
  query = function(origin, destination, extra, cb){
    return getFlatoraId(destination.place, function(error, destinationId){
      var accomodationListUrl;
      if (error) {
        return cb(error, null);
      }
      accomodationListUrl = "http://flatora.ru/api/v1/accommodation/json/searchWithParams?location[cityIds][]=" + destinationId + "&currencyId=1&minPrice=0&maxPrice=999999999&limit=9999&offset=0";
      return cache.request(accomodationListUrl, function(error, result){
        var json, e, ref$, accommodations;
        if (error) {
          return cb(error, null);
        }
        try {
          json = JSON.parse(result);
        } catch (e$) {
          e = e$;
          return cb({
            message: "couldn't parse JSON"
          }, null);
        }
        if ((json != null ? json.status : void 8) === 'success' && ((ref$ = json.data) != null && ref$.response)) {
          accommodations = (ref$ = json.data) != null ? ref$.response : void 8;
          return cb(null, accommodations);
        }
        return cb({
          message: 'bad response'
        }, null);
      });
    });
  };
  process = function(accommodations, origin, destination, cb){
    return detailsInBulk(_.map(accommodations, function(a){
      return a.id;
    }), function(error, results){
      var checkin, checkout, nights;
      if (!results) {
        return cb(error || {
          message: 'couldnt find anything'
        }, null);
      }
      checkin = moment(origin.date);
      checkout = moment(destination.date);
      nights = checkout.diff(checkin, "days");
      results = _.filter(results, function(result){
        return result != null;
      });
      results = _.filter(results, function(result){
        var filtered;
        filtered = true;
        if (result.nightMinCount) {
          filtered = filtered && result.nightMinCount <= nights;
        }
        if (result.nightMaxCount) {
          filtered = filtered && result.nightMaxCount >= nights;
        }
        return filtered;
      });
      results = _.map(results, function(result){
        result.price *= nights;
        return result;
      });
      return cb(null, {
        results: results,
        complete: true
      });
    });
  };
  exports.search = function(origin, destination, extra, cb){
    if (destination.place.country_code !== 'RU') {
      return cb({
        message: "flatora works only in Russia"
      }, null);
    }
    return query(origin, destination, extra, function(error, json){
      if (error) {
        return cb(error, null);
      }
      return process(json, origin, destination, function(error, results){
        if (error) {
          return cb(error, null);
        }
        return cb(null, results);
      });
    });
  };
}).call(this);