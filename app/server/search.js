(function(){
  var providers;
  providers = require("./providers");
  exports.search = function(socket){
    return socket.on('start_search', function(data){
      var departure, destination, signature, providersReady, totalProviders, flightReady, hotelReady, rowNumber, ref$, len$, row, lresult$, origin, extra, i$, ref1$, len1$, flightProvider, hotelProvider, results$ = [];
      departure = null;
      destination = null;
      data.rows.push({
        destination: {
          oid: data.rows[0].origin.oid,
          iata: data.rows[0].origin.iata,
          date: data.rows[data.rows.length - 1].destination.date
        },
        origin: {
          oid: data.rows[data.rows.length - 1].destination.oid,
          iata: data.rows[data.rows.length - 1].destination.iata,
          date: data.rows[data.rows.length - 1].destination.date
        }
      });
      signature = data.extra.signature;
      providersReady = 0;
      totalProviders = data.rows.length * providers.flightProviders.length + (data.rows.length - 1) * providers.flightProviders.length;
      flightReady = function(error, flights){
        var percentage, items;
        if (flights.complete || error) {
          providersReady += 1;
        }
        percentage = providersReady.toFixed(2) / totalProviders;
        if (error) {
          items = [];
        } else {
          items = flights.results;
        }
        console.log("Flight Ready! Percentage: " + percentage + ": " + providersReady + " / " + totalProviders + "| " + flights.complete);
        return socket.emit('flights_ready', {
          error: error,
          flights: items,
          progress: percentage,
          rowNumber: rowNumber,
          signature: signature
        });
      };
      hotelReady = function(error, hotels){
        var percentage, items;
        if (hotels.complete || error) {
          providersReady += 1;
        }
        percentage = providersReady.toFixed(2) / totalProviders;
        if (error) {
          items = [];
        } else {
          items = hotels.results;
        }
        console.log("Hotel Ready! Percentage: " + percentage + ": " + providersReady + " / " + totalProviders + " | " + hotels.complete);
        return socket.emit('hotels_ready', {
          error: error,
          hotels: items,
          progress: percentage,
          rowNumber: rowNumber,
          signature: signature
        });
      };
      for (rowNumber = 0, len$ = (ref$ = data.rows).length; rowNumber < len$; ++rowNumber) {
        row = ref$[rowNumber];
        lresult$ = [];
        destination = row.destination;
        origin = row.origin;
        extra = {
          adults: data.extra.adults,
          page: 1
        };
        for (i$ = 0, len1$ = (ref1$ = providers.flightProviders).length; i$ < len1$; ++i$) {
          flightProvider = ref1$[i$];
          (fn$.call(this, rowNumber, data.signature, row, flightProvider));
        }
        for (i$ = 0, len1$ = (ref1$ = providers.hotelProviders).length; i$ < len1$; ++i$) {
          hotelProvider = ref1$[i$];
          lresult$.push((fn1$.call(this, rowNumber, data.signature, row, hotelProvider)));
        }
        results$.push(lresult$);
      }
      return results$;
      function fn$(rowNumber, signature, row, flightProvider){
        flightProvider.search(origin, destination, extra, flightReady);
      }
      function fn1$(rowNumber, signature, row, hotelProvider){
        if (!(rowNumber === data.rows.length - 1)) {
          return hotelProvider.search(origin, destination, extra, hotelReady);
        }
      }
    });
  };
}).call(this);
