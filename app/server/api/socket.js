(function(){
  var _, database, md5, providers, validation, makePairs;
  _ = require("underscore");
  database = require("./../database");
  md5 = require("MD5");
  providers = require("./providers");
  validation = require("./validation");
  makePairs = function(data){
    var pairs, tripNumber, ref$, len$, trip, destinationIndex, pair, allSignatures;
    pairs = [];
    for (tripNumber = 0, len$ = (ref$ = data.trips).length; tripNumber < len$; ++tripNumber) {
      trip = ref$[tripNumber];
      if (tripNumber === data.trips.length - 1) {
        destinationIndex = 0;
      } else {
        destinationIndex = tripNumber + 1;
      }
      pair = {
        destination: data.trips[destinationIndex],
        origin: data.trips[tripNumber]
      };
      pair.flightSignature = md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date);
      if (tripNumber !== data.trips.length - 1) {
        pair.hotelSignature = md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date);
      } else {
        pair.hotelSignature = null;
      }
      pairs.push(pair);
    }
    allSignatures = _.map(pairs, function(pair){
      return pair.flightSignature;
    }).concat(_.map(pairs, function(pair){
      return pair.hotelSignature;
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
          var result, pairs, signatures, i$, ref$, len$, signature, resultReady, flightsReady, hotelsReady, pair, lresult$, destination, origin, extra, counter, len1$, flightProvider, hotelProvider, results$ = [];
          if (error) {
            return socket.emit('start_search_error', {
              error: error
            });
          }
          socket.emit('search_started', searchParams);
          result = makePairs(searchParams);
          pairs = result.pairs;
          signatures = {};
          for (i$ = 0, len$ = (ref$ = result.signatures).length; i$ < len$; ++i$) {
            signature = ref$[i$];
            signatures[signature] = false;
          }
          resultReady = function(error, items, eventName, signature){
            var results, complete, total;
            results = error
              ? []
              : items.results;
            console.log("socket.emit " + eventName + "| Complete: " + (items.complete || '') + " | Error: " + ((error != null ? error.message : void 8) || '') + "| # results: " + results.length);
            socket.emit(eventName, {
              error: error,
              items: results,
              signature: signature
            });
            if (items.complete || error) {
              signatures[signature] = true;
            }
            complete = _.filter(_.values(signatures), function(elem){
              return elem === true;
            }).length;
            total = _.values(signatures).length;
            console.log(complete + " / " + total);
            return socket.emit('progress', {
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
            for (counter = 0, len1$ = (ref$ = providers.flightProviders).length; counter < len1$; ++counter) {
              flightProvider = ref$[counter];
              (fn$.call(this, pair.flightSignature, pair, counter, flightProvider));
            }
            for (counter = 0, len1$ = (ref$ = providers.hotelProviders).length; counter < len1$; ++counter) {
              hotelProvider = ref$[counter];
              if (counter < pairs.length - 1) {
                lresult$.push((fn1$.call(this, pair.hotelSignature, pair, counter, hotelProvider)));
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
            console.log(signature);
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
