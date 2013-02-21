(function(){
  var _, async, cache, database, moment, request, xml2js, parser, query, process;
  _ = require("underscore");
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  xml2js = require("xml2js");
  parser = new xml2js.Parser(xml2js.defaults["0.1"]);
  moment.lang('ru');
  exports.name = "eviterra";
  query = function(origin, destination, extra, cb){
    var evUrl;
    evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=" + origin.place.iata + "&to=" + destination.place.iata + "&date1=" + origin.date + "&adults=" + extra.adults;
    return cache.request(evUrl, function(error, body){
      console.log("EVITERRA: Queried Eviterra serp | " + evUrl + " | status: " + !!body);
      if (error) {
        return cb(error, null);
      }
      return parser.parseString(body, function(error, json){
        if (error) {
          return cb(error, null);
        }
        return cb(null, json);
      });
    });
  };
  process = function(flights, cb){
    var i$, ref$, len$, variant, allAirports, allCarriers;
    if (!flights || !flights.variant) {
      return cb({
        message: 'No flights found'
      }, null);
    }
    for (i$ = 0, len$ = (ref$ = flights.variant).length; i$ < len$; ++i$) {
      variant = ref$[i$];
      if (variant.segment.flight.length != null) {
        variant.transferNumber = variant.segment.flight.length;
        variant.firstFlight = variant.segment.flight[0];
        variant.lastFlight = variant.segment.flight[variant.transferNumber - 1];
      } else {
        variant.transferNumber = 1;
        variant.firstFlight = variant.segment.flight;
        variant.lastFlight = variant.firstFlight;
      }
    }
    allAirports = [];
    for (i$ = 0, len$ = (ref$ = flights.variant).length; i$ < len$; ++i$) {
      variant = ref$[i$];
      allAirports.push(variant.firstFlight.departure);
      allAirports.push(variant.lastFlight.arrival);
    }
    allCarriers = _.map(flights.variant, function(variant){
      var ref$;
      return ((ref$ = variant.firstFlight) != null ? ref$.marketingCarrier : void 8) != null;
    });
    allCarriers = _.uniq(allCarriers);
    allAirports = _.uniq(allAirports);
    return database.airports.find({
      iata: {
        $in: allAirports
      }
    }).toArray(function(err, airportsInfo){
      return database.airports.find({
        iata: {
          $in: allCarriers
        }
      }).toArray(function(err, airlinesInfo){
        var newFlights, i$, ref$, len$, variant, arrivalDestinationDate, departureOriginDate, departureAirport, arrivalAirport, carrier, utcArrivalDate, utcDepartureDate, flightTimeSpan, newFlight;
        newFlights = [];
        for (i$ = 0, len$ = (ref$ = flights.variant).length; i$ < len$; ++i$) {
          variant = ref$[i$];
          arrivalDestinationDate = moment(variant.lastFlight.arrivalDate + 'T' + variant.lastFlight.arrivalTime);
          departureOriginDate = moment(variant.firstFlight.departureDate + 'T' + variant.firstFlight.departureTime);
          departureAirport = _.filter(airportsInfo, fn$)[0];
          arrivalAirport = _.filter(airportsInfo, fn1$)[0];
          carrier = _.filter(airlinesInfo, fn2$)[0];
          if (carrier) {
            delete carrier._id;
          }
          if (!(departureAirport && arrivalAirport)) {
            return cb({
              message: "No airport found | departure: " + departureAirport + " | arrival: " + arrivalAirport
            }, null);
          }
          utcArrivalDate = arrivalDestinationDate.clone().subtract('hours', arrivalAirport.timezone);
          utcDepartureDate = departureOriginDate.clone().subtract('hours', departureAirport.timezone);
          flightTimeSpan = utcArrivalDate.diff(utcDepartureDate, 'hours');
          if (flightTimeSpan === 0) {
            flightTimeSpan = 1;
          }
          newFlight = {
            arrival: arrivalDestinationDate.format("hh:mm"),
            carrier: carrier,
            departure: departureOriginDate.format("hh:mm"),
            duration: flightTimeSpan * 60 * 60,
            price: parseInt(variant.price),
            provider: 'eviterra',
            stops: variant.transferNumber - 1,
            url: variant.url + 'ostroterra'
          };
          newFlights.push(newFlight);
        }
        return cb(null, {
          results: newFlights,
          complete: true
        });
        function fn$(el){
          return el.iata === variant.firstFlight.departure;
        }
        function fn1$(el){
          return el.iata === variant.lastFlight.arrival;
        }
        function fn2$(el){
          var ref$;
          return el.iata === (((ref$ = variant.lastFlight) != null ? ref$.marketingCarrier : void 8) != null);
        }
      });
    });
  };
  exports.search = function(origin, destination, extra, cb){
    return query(origin, destination, extra, function(error, json){
      if (error) {
        return cb(error, null);
      }
      return process(json, function(error, results){
        if (error) {
          return cb(error, null);
        }
        return cb(null, results);
      });
    });
  };
}).call(this);
