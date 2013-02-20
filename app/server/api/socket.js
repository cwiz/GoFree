(function(){
  var _, async, database, md5, providers, validation, makePairs;
  _ = require("underscore");
  async = require("async");
  database = require("./../database");
  md5 = require("MD5");
  providers = require("./providers");
  validation = require("./validation");
  makePairs = function(data){
    var pairs, i$, ref$, len$, tripNumber, trip, isLastTrip, destinationIndex, pair, flightSignatures, hotelSignatures, allSignatures;
    pairs = [];
    for (i$ = 0, len$ = (ref$ = data.trips).length; i$ < len$; ++i$) {
      tripNumber = i$;
      trip = ref$[i$];
      isLastTrip = tripNumber === data.trips.length - 1;
      destinationIndex = isLastTrip
        ? 0
        : tripNumber + 1;
      pair = {
        destination: data.trips[destinationIndex],
        origin: data.trips[tripNumber],
        extra: {
          adults: data.adults,
          page: 1
        }
      };
      pair.flights_signature = md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date);
      pair.hotels_signature = md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date);
      if (isLastTrip) {
        pair.hotels_signature = null;
      }
      pairs.push(pair);
    }
    flightSignatures = _.map(pairs, function(pair){
      return pair.flights_signature;
    });
    hotelSignatures = _.map(pairs, function(pair){
      return pair.hotels_signature;
    });
    hotelSignatures.pop();
    allSignatures = flightSignatures.concat(hotelSignatures);
    return {
      pairs: pairs,
      signatures: allSignatures
    };
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
          var result, pairs, signatures, resultReady, flightsReady, hotelsReady, callbacks;
          if (!searchParams) {
            return socket.emit('start_search_error', {
              error: error
            });
          }
          delete searchParams._id;
          result = makePairs(searchParams);
          pairs = result.pairs;
          signatures = _.object(
          _.map(result.signatures, function(signature){
            return [signature, 0];
          }));
          socket.emit('search_started', {
            form: searchParams,
            trips: pairs
          });
          resultReady = function(error, result, eventName, signature, totalProviders){
            var items, complete, total, progress;
            items = (result != null ? result.results : void 8) || [];
            complete = result != null ? result.complete : void 8;
            error = (error != null ? error.message : void 8) || null;
            if (complete || error) {
              signatures[signature] += 1.0 / totalProviders;
            }
            console.log("SOCKET: " + eventName + " | Complete: " + complete + " | Error: " + error + " | # results: " + items.length);
            socket.emit(eventName, {
              error: error,
              items: items,
              signature: signature,
              progress: 1
            });
            complete = _.filter(_.values(signatures), function(elem){
              return elem;
            }).length;
            total = _.values(signatures).length;
            progress = complete.toFixed(2) / total;
            console.log("SOCKET: progress | value: " + progress);
            return socket.emit('progress', {
              hash: searchParams.hash,
              progress: progress
            });
          };
          flightsReady = function(error, items, signature){
            return resultReady(error, items, 'flights_ready', signature, providers.flightProviders.length);
          };
          hotelsReady = function(error, items, signature){
            return resultReady(error, items, 'hotels_ready', signature, providers.hotelProviders.length);
          };
          callbacks = [];
          _.map(pairs, function(pair){
            return function(){
              var x$, copyPair, hotelOperations;
              x$ = copyPair = pair;
              _.map(providers.flightProviders, function(provider){
                return function(){
                  return callbacks.push(function(callback){
                    return provider.search(copyPair.origin, copyPair.destination, copyPair.extra, function(error, items){
                      return flightsReady(error, items, copyPair.flights_signature);
                    });
                  });
                }();
              });
              if (!pair.hotels_signature) {
                return;
              }
              return hotelOperations = _.map(providers.hotelProviders, function(provider){
                return function(){
                  var x$, copyPair;
                  x$ = copyPair = pair;
                  callbacks.push(function(callback){
                    return provider.search(copyPair.origin, copyPair.destination, copyPair.extra, function(error, items){
                      return hotelsReady(error, items, copyPair.hotels_signature);
                    });
                  });
                  return x$;
                }();
              });
            }();
          });
          return async.parallel(callbacks);
        });
      });
    });
    return socket.on('serp_selected', function(data){
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
            hash: data.trip_hash
          }, function(error, trip){
            if (trip) {
              return;
            }
            database.trips.insert(data);
            return socket.emit('serp_selected_ok', {});
          });
        });
      });
    });
  };
}).call(this);
