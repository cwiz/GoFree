(function(){
  var _, async, database, md5, providers, rome2rio, validation, fixDestination, makePairs;
  _ = require("underscore");
  async = require("async");
  database = require("./../database");
  md5 = require("MD5");
  providers = require("./providers");
  rome2rio = require("./providers/rome2rio");
  validation = require("./validation");
  fixDestination = function(pair, cb){
    var operations;
    if (pair.origin.place.iata && pair.destination.place.iata) {
      pair.origin.nearest_airport = pair.origin.place;
      pair.destination.nearest_airport = pair.destination.place;
      return cb(null, pair);
    }
    if (pair.origin.place.iata) {
      pair.origin.nearest_airport = pair.origin.place;
    }
    if (pair.destination.place.iata) {
      pair.destination.nearest_airport = pair.destination.place;
    }
    operations = [];
    if (!pair.destination.place.iata) {
      operations.push(function(callback){
        return rome2rio.getNeareasAirport(pair.origin, pair.destination, function(error, destinationIata){
          if (error) {
            return callback(error, null);
          }
          pair.destination.place.iata = destinationIata;
          return database.geonames.findOne({
            iata: destinationIata
          }, function(error, destination_airport){
            if (error) {
              return callback(error, null);
            }
            if (destination_airport) {
              delete destination_airport._id;
              pair.destination.nearest_airport = destination_airport;
            } else {
              pair.destination.nearest_airport = pair.destination.place;
            }
            return callback(null, {});
          });
        });
      });
    }
    if (!pair.origin.place.iata) {
      operations.push(function(callback){
        return rome2rio.getNeareasAirport(pair.destination, pair.origin, function(error, originIata){
          if (error) {
            return callback(error, null);
          }
          pair.origin.place.iata = originIata;
          return database.geonames.findOne({
            iata: originIata
          }, function(error, origin_airport){
            if (error) {
              return callback(error, null);
            }
            if (origin_airport) {
              delete origin_airport._id;
              pair.origin.nearest_airport = origin_airport;
            } else {
              pair.origin.nearest_airport = pair.origin.place;
            }
            return callback(null, {});
          });
        });
      });
    }
    return async.parallel(operations, function(error, result){
      return cb(null, pair);
    });
  };
  makePairs = function(data, cb){
    var i$, ref$, len$, tripNumber, trip, pairs;
    for (i$ = 0, len$ = (ref$ = data.trips).length; i$ < len$; ++i$) {
      tripNumber = i$;
      trip = ref$[i$];
      trip.tripNumber = tripNumber;
      trip.isLast = tripNumber === data.trips.length - 1;
      trip.destinationIndex = trip.isLast
        ? 0
        : tripNumber + 1;
    }
    pairs = [];
    return async.map(data.trips, function(trip, callback){
      var pair;
      pair = {
        destination: data.trips[trip.destinationIndex],
        origin: data.trips[trip.tripNumber],
        extra: {
          adults: data.adults,
          page: 1
        }
      };
      return fixDestination(pair, function(error, pair){
        pair.flights_signature = md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date);
        pair.hotels_signature = md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date);
        if (trip.isLast) {
          pair.hotels_signature = null;
        }
        return callback(null, pair);
      });
    }, function(error, pairs){
      var flightSignatures, hotelSignatures, allSignatures;
      flightSignatures = _.map(pairs, function(pair){
        return pair.flights_signature;
      });
      hotelSignatures = _.map(pairs, function(pair){
        return pair.hotels_signature;
      });
      hotelSignatures.pop();
      allSignatures = flightSignatures.concat(hotelSignatures);
      return cb(null, {
        pairs: pairs,
        signatures: allSignatures
      });
    });
  };
  exports.search = function(socket){
    socket.on('search', function(data){
      return validation.search(data, function(error, data){
        if (error) {
          return socket.emit('search_error', {
            error: error
          });
        }
        database.search.insert(data);
        return socket.emit('search_ok', {});
      });
    });
    socket.on('search_start', function(data){
      return validation.start_search(data, function(error, data){
        if (error) {
          return socket.emit('start_search_error', {
            error: error
          });
        }
        return database.search.findOne(data, function(error, searchParams){
          if (!searchParams) {
            return socket.emit('start_search_error', {
              error: error
            });
          }
          delete searchParams._id;
          return makePairs(searchParams, function(error, result){
            var pairs, signatures, totalProviders, providersReady, resultReady, callbacks;
            pairs = result.pairs;
            signatures = _.object(
            _.map(result.signatures, function(signature){
              return [signature, 0];
            }));
            totalProviders = (pairs.length - 1) * providers.allProviders.length + providers.flightProviders.length;
            providersReady = 0;
            socket.emit('search_started', {
              form: searchParams,
              trips: pairs
            });
            resultReady = function(params){
              var items, ref$, complete, error, progress;
              items = ((ref$ = params.result) != null ? ref$.results : void 8) || [];
              complete = ((ref$ = params.result) != null ? ref$.complete : void 8) || false;
              error = ((ref$ = params.error) != null ? ref$.message : void 8) || null;
              console.log("SOCKET: " + params.event + " | Complete: " + complete + " | Provider: " + params.provider.name + " | Error: " + error + " | # results: " + items.length);
              if (complete || error) {
                providersReady += 1;
              }
              socket.emit(params.event, {
                error: error,
                items: items,
                signature: params.signature,
                progress: 1
              });
              progress = providersReady.toFixed(2) / totalProviders;
              console.log("SOCKET: progress | value: " + progress);
              return socket.emit('progress', {
                hash: searchParams.hash,
                progress: progress
              });
            };
            callbacks = [];
            _.map(pairs, function(pair){
              return function(){
                _.map(providers.flightProviders, function(provider){
                  return function(){
                    return callbacks.push(function(callback){
                      return provider.search(pair.origin, pair.destination, pair.extra, function(error, result){
                        return resultReady({
                          error: error,
                          event: 'flights_ready',
                          result: result,
                          pair: pair,
                          provider: provider,
                          signature: pair.flights_signature
                        });
                      });
                    });
                  }();
                });
                if (!pair.hotels_signature) {
                  return;
                }
                return _.map(providers.hotelProviders, function(provider){
                  return function(){
                    return callbacks.push(function(callback){
                      return provider.search(pair.origin, pair.destination, pair.extra, function(error, result){
                        return resultReady({
                          error: error,
                          event: 'hotels_ready',
                          result: result,
                          pair: pair,
                          provider: provider,
                          signature: pair.hotels_signature
                        });
                      });
                    });
                  }();
                });
              }();
            });
            return async.parallel(callbacks);
          });
        });
      });
    });
    socket.on('serp_selected', function(data){
      return validation.serp_selected(data, function(error, data){
        if (error) {
          return socket.emit('serp_selected_error', {
            error: error
          });
        }
        return database.search.findOne({
          hash: data.search_hash
        }, function(error, searchParams){
          if (error) {
            return socket.emit('serp_selected_error', {
              error: error
            });
          }
          return database.trips.findOne({
            trip_hash: data.trip_hash
          }, function(error, trip){
            if (!trip) {
              database.trips.insert(data);
            }
            return socket.emit('serp_selected_ok', {});
          });
        });
      });
    });
    return socket.on('selected_list_fetch', function(data){
      return database.trips.findOne({
        trip_hash: data.trip_hash
      }, function(error, trip){
        if (error || !trip) {
          return socket.emit('selected_list_fetch_error', {
            error: error
          });
        }
        delete trip._id;
        return socket.emit('selected_list_fetch_ok', trip);
      });
    });
  };
}).call(this);
