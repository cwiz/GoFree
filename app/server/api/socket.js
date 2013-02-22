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
          var result, pairs, signatures, totalProviders, providersReady, resultReady, callbacks;
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
