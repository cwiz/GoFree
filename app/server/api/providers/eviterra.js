(function(){
  var _, async, cache, database, moment, request, xml2js, parser, autocomplete, getEviterraId, query, process;
  _ = require("underscore");
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  xml2js = require("xml2js");
  parser = new xml2js.Parser(xml2js.defaults["0.1"]);
  moment.lang('ru');
  exports.name = "eviterra.com";
  autocomplete = function(query, callback){
    var eviterraUrl;
    eviterraUrl = "https://eviterra.com/complete.json?val=" + query;
    return cache.request(eviterraUrl, function(error, body){
      var json, finalJson, i$, ref$, len$, item, name, country, iata, displayName;
      if (error) {
        return callback(error, null);
      }
      try {
        json = JSON.parse(body);
      } catch (e$) {
        error = e$;
        return callback(error, null);
      }
      finalJson = [];
      for (i$ = 0, len$ = (ref$ = json.data).length; i$ < len$; ++i$) {
        item = ref$[i$];
        if (item.type === 'city') {
          name = item.name;
          country = item.area;
          iata = item.iata;
          displayName = name;
          if (country !== "Россия") {
            displayName += ", " + country;
          }
          finalJson.push({
            name: name,
            iata: iata,
            country: country,
            displayName: displayName,
            provider: exports.name
          });
        }
      }
      return callback(null, finalJson);
    });
  };
  getEviterraId = function(place, callback){
    if (place != null && place.eviterra_id) {
      return callback(null, place.eviterra_id);
    }
    return autocomplete(place.name_ru + "", function(error, result){
      var eviterra_id;
      if (error) {
        return callback(error, null);
      }
      if (result.length === 0) {
        return callback({
          'nothing found': 'nothing found'
        }, null);
      }
      eviterra_id = result[0].iata;
      callback(null, eviterra_id);
      return database.geonames.update({
        geoname_id: place.geoname_id
      }, {
        $set: {
          eviterra_id: eviterra_id
        }
      });
    });
  };
  query = function(origin, destination, extra, cb){
    return async.parallel({
      origin: function(callback){
        return getEviterraId(origin.nearest_airport, callback);
      },
      destination: function(callback){
        return getEviterraId(destination.nearest_airport, callback);
      }
    }, function(error, eviterraId){
      var evUrl;
      if (error) {
        return cb(error, null);
      }
      evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=" + eviterraId.origin + "&to=" + eviterraId.destination + "&date1=" + origin.date + "&adults=" + extra.adults;
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
      return database.airlines.find({
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
            carrier: carrier ? [carrier] : null,
            departure: departureOriginDate.format("hh:mm"),
            duration: flightTimeSpan * 60 * 60,
            price: parseInt(variant.price),
            provider: exports.name,
            stops: variant.transferNumber - 1,
            url: variant.url + 'ostroterra',
            type: 'flight'
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
