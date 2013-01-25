(function(){
  var providers, validation, database, md5, makePairs;
  providers = require("./providers");
  validation = require("./validation");
  database = require("./../database");
  md5 = require("MD5");
  makePairs = function(data){
    var pairs, tripNumber, ref$, len$, trip, destinationIndex, pair;
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
      pair.flightSignature = md5(JSON.stringify(origin.place) + JSON.stringify(destination.place) + origin.date);
      pair.hotelSignaure = md5(JSON.stringify(destination.place) + origin.date + destination.date);
      pairs.push(pair);
    }
    return pairs;
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
        return socket.emit('search_validation_ok', {});
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
          var pairs, providersReady, totalProviders, resultReady, flightsReady, hotelsReady, i$, ref$, len$, pair, lresult$, destination, origin, extra, counter, ref1$, len1$, flightProvider, hotelProvider, results$ = [];
          if (error) {
            return socket.emit('start_search_error', {
              error: error
            });
          }
          socket.emit('search_started', searchParams);
          pairs = makePairs(searchParams);
          providersReady = 0;
          totalProviders = rows.length * providers.flightProviders.length + (rows.length - 1) * providers.flightProviders.length;
          resultReady = function(error, items, eventName, signature){
            var percentage, results;
            if (error) {
              items = {
                complete: true
              };
            }
            if (error || items.complete) {
              providersReady += 1;
            }
            percentage = providersReady.toFixed(2) / totalProviders;
            results = error
              ? []
              : items.results;
            console.log("socket.emit " + eventName + " | Percentage: " + percentage + ": " + providersReady + " / " + totalProviders + " | Complete: " + (items.complete || '') + " | Error: " + ((error != null ? error.message : void 8) || '') + "| # results: " + results.length);
            socket.emit(eventName, {
              error: error,
              items: results,
              signature: signature
            });
            return socket.emit('progress', {
              progress: percentage
            });
          };
          flightsReady = function(error, items, signature){
            return resultReady(error, items, 'flights_ready', signature);
          };
          hotelsReady = function(error, items, signature){
            return resultReady(error, items, 'hotels_ready', signature);
          };
          for (i$ = 0, len$ = (ref$ = rows).length; i$ < len$; ++i$) {
            pair = ref$[i$];
            lresult$ = [];
            destination = pair.destination;
            origin = pair.origin;
            extra = {
              adults: data.adults,
              page: 1
            };
            for (counter = 0, len1$ = (ref1$ = providers.flightProviders).length; counter < len1$; ++counter) {
              flightProvider = ref1$[counter];
              (fn$.call(this, data.flightSignature, pair, counter, flightProvider));
            }
            for (counter = 0, len1$ = (ref1$ = providers.hotelProviders).length; counter < len1$; ++counter) {
              hotelProvider = ref1$[counter];
              if (counter < pairs.length - 1) {
                lresult$.push((fn1$.call(this, data.hotelSignature, pair, counter, hotelProvider)));
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
            return hotelProvider.search(origin, destination, extra, function(error, items){
              return hotelsReady(error, items, signature);
            });
          }
        });
      });
    });
  };
}).call(this);
