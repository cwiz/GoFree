(function(){
  var _, async, database, geobase, links, md5, providers, rome2rio, validation, log, fixDestination, makePairs;
  _ = require("underscore");
  async = require("async");
  database = require("./../database");
  geobase = require("./../geobase");
  links = require("./links");
  md5 = require("MD5");
  providers = require("./providers");
  rome2rio = require("./providers/rome2rio");
  validation = require("./validation");
  log = require("./../logging").getLogger("socket");
  fixDestination = function(pair, cb){
    return geobase.findRoute(pair.origin.place, pair.destination.place, function(error, airports){
      if (error) {
        return cb(error, null);
      }
      pair.origin.nearest_airport = airports.originAirport;
      pair.destination.nearest_airport = airports.destinationAirport;
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
        if (error) {
          return cb(error, null);
        }
        pair.flights_signature = md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date);
        pair.hotels_signature = md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date);
        if (trip.isLast) {
          pair.hotels_signature = null;
        }
        return callback(null, pair);
      });
    }, function(error, pairs){
      var flightSignatures, hotelSignatures, allSignatures, i$, ref$, len$, i, pair, nextPair;
      if (error) {
        return cb(error, null);
      }
      flightSignatures = _.map(pairs, function(pair){
        return pair.flights_signature;
      });
      hotelSignatures = _.map(pairs, function(pair){
        return pair.hotels_signature;
      });
      hotelSignatures.pop();
      allSignatures = flightSignatures.concat(hotelSignatures);
      for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
        i = ref$[i$];
        pair = pairs[i];
        nextPair = pairs[i + 1];
        if (pair.origin.place === nextPair.destination.place) {
          pair.destination.roundTrip = true;
        }
      }
      pairs = _.filter(pairs, function(pair){
        return pair.origin.roundTrip == null;
      });
      return cb(null, {
        pairs: pairs,
        signatures: allSignatures
      });
      function fn$(){
        var i$, to$, results$ = [];
        for (i$ = 0, to$ = pairs.length - 1; i$ < to$; ++i$) {
          results$.push(i$);
        }
        return results$;
      }
    });
  };
  exports.search = function(err, socket, session){
    socket.on('search', function(data){
      return validation.search(data, function(error, data){
        if (error) {
          return socket.emit('search_error', {
            error: error
          });
        }
        database.search.insert(data, function(error, search){});
        return socket.emit('search_ok', {});
      });
    });
    socket.on('pre_search', function(searchParams){
      return makePairs(searchParams, function(error, result){
        var pairs, callbacks;
        pairs = result.pairs;
        callbacks = [];
        _.map(pairs, function(pair){
          return function(){
            if (!pair.origin.date || !pair.destination.date) {
              return;
            }
            _.map(providers.flightProviders, function(provider){
              return function(){
                return callbacks.push(function(callback){
                  return provider.search(pair.origin, pair.destination, pair.extra, function(error, result){});
                });
              }();
            });
            if (!pair.hotels_signature) {
              return;
            }
            return _.map(providers.hotelProviders, function(provider){
              return function(){
                return callbacks.push(function(callback){
                  return provider.search(pair.origin, pair.destination, pair.extra, function(error, result){});
                });
              }();
            });
          }();
        });
        return async.parallel(callbacks);
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
            var pairs, signatures, totalProviders, i$, len$, i, pair, providersReady, resultReady, callbacks;
            pairs = result.pairs;
            signatures = _.object(
            _.map(result.signatures, function(signature){
              return [signature, 0];
            }));
            totalProviders = 0;
            for (i$ = 0, len$ = pairs.length; i$ < len$; ++i$) {
              i = i$;
              pair = pairs[i$];
              if (i === pairs.length - 1 && !pair.destination.roundTrip) {
                totalProviders += providers.flightProviders.length;
              } else {
                totalProviders += providers.allProviders.length;
              }
            }
            providersReady = 0;
            socket.emit('search_started', {
              form: searchParams,
              trips: pairs
            });
            resultReady = function(params){
              var items, ref$, complete, error, i$, len$, item, progress;
              items = ((ref$ = params.result) != null ? ref$.results : void 8) || [];
              complete = ((ref$ = params.result) != null ? ref$.complete : void 8) || false;
              error = ((ref$ = params.error) != null ? ref$.message : void 8) || null;
              log.info("SOCKET: " + params.event, {
                complete: complete,
                provider: params.provider.name,
                error: error,
                results: items.length
              });
              if (complete || error || !items.length) {
                providersReady += 1;
              }
              for (i$ = 0, len$ = items.length; i$ < len$; ++i$) {
                item = items[i$];
                item.hash = links.getLinkHash(item);
              }
              socket.emit(params.event, {
                error: error,
                items: items,
                signature: params.signature,
                progress: 1
              });
              progress = _.min([1, providersReady.toFixed(2) / totalProviders]);
              log.info("SOCKET: progress", {
                value: progress
              });
              return socket.emit('progress', {
                hash: searchParams.hash,
                progress: progress
              });
            };
            callbacks = [];
            _.map(pairs, function(pair){
              return function(){
                if (!pair.origin.date || !pair.destination.date) {
                  return;
                }
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
              database.trips.insert(data, function(error, trip){});
            }
            session.trip_hash = data.trip_hash;
            session.search_hash = data.search_hash;
            session.save();
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
