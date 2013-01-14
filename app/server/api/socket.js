(function(){
  var providers, JSV, validate, convertToRows;
  providers = require("./providers");
  JSV = require("jsv").JSV;
  validate = function(data, cb){
    var schema, env, report;
    schema = {
      type: 'object',
      properties: {
        adults: {
          type: 'integer',
          required: true,
          minimum: 1,
          maximum: 6
        },
        budget: {
          type: 'integer',
          required: true,
          minimum: 0
        },
        signature: {
          type: 'string',
          required: false
        },
        trips: {
          type: 'array',
          required: true,
          items: {
            type: 'object',
            properties: {
              date: {
                type: 'string',
                format: 'date',
                required: true
              },
              removable: {
                type: 'boolean',
                required: false
              },
              place: {
                type: 'object',
                required: true
              }
            }
          }
        }
      }
    };
    env = JSV.createEnvironment();
    report = env.validate(data, schema);
    if (report.errors.length === 0) {
      return cb(null, data);
    } else {
      return cb(report.errors, null);
    }
  };
  convertToRows = function(data){
    var rows, tripNumber, ref$, len$, trip, index;
    rows = [];
    for (tripNumber = 0, len$ = (ref$ = data.trips).length; tripNumber < len$; ++tripNumber) {
      trip = ref$[tripNumber];
      if (tripNumber === data.trips.length - 1) {
        index = 0;
      } else {
        index = tripNumber + 1;
      }
      console.log(tripNumber);
      console.log(index);
      rows.push({
        destination: {
          place: data.trips[index].place,
          date: data.trips[index].date
        },
        origin: {
          place: data.trips[tripNumber].place,
          date: data.trips[tripNumber].date
        }
      });
    }
    return rows;
  };
  exports.search = function(socket){
    return socket.on('start_search', function(data){
      return validate(data, function(errors, data){
        var rows, signature, providersReady, totalProviders, resultReady, flightsReady, hotelsReady, rowNumber, len$, row, lresult$, destination, origin, extra, i$, ref$, len1$, flightProvider, hotelProvider, results$ = [];
        if (errors) {
          return socket.emit('start_search_validation_error', {
            errors: errors
          });
        }
        rows = convertToRows(data);
        signature = data.signature;
        providersReady = 0;
        totalProviders = rows.length * providers.flightProviders.length + (rows.length - 1) * providers.flightProviders.length;
        resultReady = function(error, items, eventName){
          var percentage;
          if (error) {
            items = {
              complete: true
            };
          }
          if (error || items.complete) {
            providersReady += 1;
          }
          percentage = providersReady.toFixed(2) / totalProviders;
          console.log("Emitting " + eventName + " Percentage: " + percentage + ": " + providersReady + " / " + totalProviders + "| " + items.complete);
          return socket.emit('flights_ready', {
            error: error,
            flights: error
              ? []
              : items.results,
            progress: percentage,
            rowNumber: rowNumber,
            signature: signature
          });
        };
        flightsReady = function(error, items){
          return resultReady(error, items, 'flights_ready');
        };
        hotelsReady = function(error, items){
          return resultReady(error, items, 'hotels_ready');
        };
        for (rowNumber = 0, len$ = rows.length; rowNumber < len$; ++rowNumber) {
          row = rows[rowNumber];
          lresult$ = [];
          destination = row.destination;
          origin = row.origin;
          extra = {
            adults: data.adults,
            page: 1
          };
          for (i$ = 0, len1$ = (ref$ = providers.flightProviders).length; i$ < len1$; ++i$) {
            flightProvider = ref$[i$];
            (fn$.call(this, rowNumber, data.signature, row, flightProvider));
          }
          for (i$ = 0, len1$ = (ref$ = providers.hotelProviders).length; i$ < len1$; ++i$) {
            hotelProvider = ref$[i$];
            lresult$.push((fn1$.call(this, rowNumber, data.signature, row, hotelProvider)));
          }
          results$.push(lresult$);
        }
        return results$;
        function fn$(rowNumber, signature, row, flightProvider){
          flightProvider.search(origin, destination, extra, flightsReady);
        }
        function fn1$(rowNumber, signature, row, hotelProvider){
          if (!(rowNumber === rows.length - 1)) {
            return hotelProvider.search(origin, destination, extra, hotelsReady);
          }
        }
      });
    });
  };
}).call(this);
