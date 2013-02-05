(function(){
  var _, database, md5, providers, validation, makePairs;
  _ = require("underscore");
  database = require("./../database");
  md5 = require("MD5");
  providers = require("./providers");
  validation = require("./validation");
  makePairs = function(data){
    var pairs, i$, ref$, len$, tripNumber, trip, destinationIndex, pair, allSignatures;
    pairs = [];
    for (i$ = 0, len$ = (ref$ = data.trips).length; i$ < len$; ++i$) {
      tripNumber = i$;
      trip = ref$[i$];
      if (tripNumber === data.trips.length - 1) {
        destinationIndex = 0;
      } else {
        destinationIndex = tripNumber + 1;
      }
      pair = {
        destination: data.trips[destinationIndex],
        origin: data.trips[tripNumber]
      };
      pair.flights_signature = md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date);
      if (tripNumber !== data.trips.length - 1) {
        pair.hotels_signature = md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date);
      } else {
        pair.hotels_signature = null;
      }
      pairs.push(pair);
    }
    allSignatures = _.map(pairs, function(pair){
      return pair.flights_signature;
    }).concat(_.map(pairs, function(pair){
      return pair.hotels_signature;
    }));
    allSignatures.pop();
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
    return socket.on('search_start', function(data){
      return validation.start_search(data, function(error, data){
        if (error) {
          return socket.emit('start_search_error', {
            error: error
          });
        }
        return database.search.findOne(data, function(error, searchParams){
          var result, pairs, signatures, i$, ref$, len$, signature, resultReady, flightsReady, hotelsReady, pair, lresult$, destination, origin, extra, j$, len1$, counter, flightProvider, hotelProvider, results$ = [];
          if (error || !searchParams) {
            return socket.emit('start_search_error', {
              error: error
            });
          }
          result = makePairs(searchParams);
          pairs = result.pairs;
          signatures = {};
          delete searchParams._id;
          socket.emit('search_started', {
            form: searchParams,
            trips: pairs
          });
          for (i$ = 0, len$ = (ref$ = result.signatures).length; i$ < len$; ++i$) {
            signature = ref$[i$];
            signatures[signature] = false;
          }
          resultReady = function(error, items, eventName, signature){
            var results, complete, total;
            results = error
              ? []
              : items.results;
            console.log("socket.emit " + eventName + "| Complete: " + ((items != null ? items.complete : void 8) || '') + " | Error: " + ((error != null ? error.message : void 8) || '') + "| # results: " + results.length);
            socket.emit(eventName, {
              error: error,
              items: results,
              signature: signature,
              progress: items != null && items.complete ? 1 : 0
            });
            if ((items != null && items.complete) || error) {
              signatures[signature] = true;
            }
            complete = _.filter(_.values(signatures), function(elem){
              return elem === true;
            }).length;
            total = _.values(signatures).length;
            console.log(complete + " / " + total);
            return socket.emit('progress', {
              hash: searchParams.hash,
              progress: complete.toFixed(2) / total
            });
          };
          flightsReady = function(error, items, signature){
            return resultReady(error, items, 'flights_ready', signature);
          };
          hotelsReady = function(error, items, signature){
            return resultReady(error, items, 'hotels_ready', signature);
          };
          for (i$ = 0, len$ = pairs.length; i$ < len$; ++i$) {
            pair = pairs[i$];
            lresult$ = [];
            destination = pair.destination;
            origin = pair.origin;
            extra = {
              adults: searchParams.adults,
              page: 1
            };
            for (j$ = 0, len1$ = (ref$ = providers.flightProviders).length; j$ < len1$; ++j$) {
              counter = j$;
              flightProvider = ref$[j$];
              (fn$.call(this, pair.flights_signature, pair, counter, flightProvider));
            }
            for (j$ = 0, len1$ = (ref$ = providers.hotelProviders).length; j$ < len1$; ++j$) {
              counter = j$;
              hotelProvider = ref$[j$];
              if (counter < pairs.length - 1) {
                lresult$.push((fn1$.call(this, pair.hotels_signature, pair, counter, hotelProvider)));
              }
            }
            results$.push(lresult$);
          }
          return results$;
          function fn$(signature, pair, counter, flightProvider){
            flightProvider.search(origin, destination, extra, function(error, items){
              return flightsReady(error, items, signature);
            });
          }
          function fn1$(signature, pair, counter, hotelProvider){
            if (signature) {
              return hotelProvider.search(origin, destination, extra, function(error, items){
                return hotelsReady(error, items, signature);
              });
            }
          }
        });
      });
    });
  };
}).call(this);
