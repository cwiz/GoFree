(function(){
  var providers;
  providers = require("./providers");
  exports.search = function(socket){
    socket.on('start_search', function(data){
      var departure, destination, rowNumber, ref$, len$, row, origin, extra, providersReady, totalProviders, i$, ref1$, len1$, flightProvider, hotelProvider;
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
      for (rowNumber = 0, len$ = (ref$ = data.rows).length; rowNumber < len$; ++rowNumber) {
        row = ref$[rowNumber];
        destination = row.destination;
        origin = row.origin;
        extra = {
          adults: data.extra.adults,
          page: 1
        };
        providersReady = 0;
        totalProviders = providers.flightProviders.length + providers.hotelProviders.length;
        for (i$ = 0, len1$ = (ref1$ = providers.flightProviders).length; i$ < len1$; ++i$) {
          flightProvider = ref1$[i$];
          (fn$.call(this, rowNumber, data.signature, row, flightProvider));
        }
        for (i$ = 0, len1$ = (ref1$ = providers.hotelProviders).length; i$ < len1$; ++i$) {
          hotelProvider = ref1$[i$];
          (fn1$.call(this, rowNumber, data.signature, row, hotelProvider));
        }
      }
      function fn$(rowNumber, signature, row, flightProvider){
        flightProvider.search(origin, destination, extra, function(error, result){
          if (result.complete || error) {
            providersReady += 1;
          }
          if (error) {
            return socket.emit('flights_ready', {
              flights: [],
              rowNumber: rowNumber,
              signature: signature,
              progress: float(providersReady) / totalProviders
            });
          } else {
            return socket.emit('flights_ready', {
              flights: result.results,
              rowNumber: rowNumber,
              signature: signature,
              progress: float(providersReady) / totalProviders
            });
          }
        });
      }
      function fn1$(rowNumber, signature, row, hotelProvider){
        if (!(rowNumber === data.rows.length - 1)) {
          hotelProvider.search(origin, destination, extra, function(error, result){
            if (result.complete || error) {
              providersReady += 1;
            }
            if (error) {
              return socket.emit('hotels_ready', {
                hotels: [],
                rowNumber: rowNumber,
                signature: signature,
                progress: float(providersReady) / totalProviders
              });
            } else {
              return socket.emit('hotels_ready', {
                hotels: result.results,
                rowNumber: rowNumber,
                signature: signature,
                progress: float(providersReady) / totalProviders
              });
            }
          });
        }
      }
    });
  };
}).call(this);
