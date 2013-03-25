(function(){
  var _, async, cache, database, moment, request, xml2js, winston, parser, autocomplete, getEviterraId, query, process;
  _ = require("underscore");
  async = require("async");
  cache = require("./../../cache");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  xml2js = require("xml2js");
  winston = require("winston");
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
    if ((place != null && place.eviterra_id) && (place != null && place.iata)) {
      return callback(null, place.eviterra_id);
    }
    return autocomplete(place.name_ru, function(error, result){
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
          eviterra_id: eviterra_id,
          iata: eviterra_id
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
      if (destination.roundTrip) {
        evUrl += "&date2=" + destination.date;
      }
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
    var variants, i$, len$, variant, segments, j$, len1$, segment, allAirports, ref$, allCarriers;
    if (!flights || !flights.variant) {
      return cb({
        message: 'No flights found'
      }, null);
    }
    variants = flights.variant;
    for (i$ = 0, len$ = variants.length; i$ < len$; ++i$) {
      variant = variants[i$];
      segments = !variant.segment.length
        ? [variant.segment]
        : variant.segment;
      variant.segments = segments;
      for (j$ = 0, len1$ = segments.length; j$ < len1$; ++j$) {
        segment = segments[j$];
        if (segment.flight.length != null) {
          segment.transferNumber = segment.flight.length;
          segment.firstFlight = segment.flight[0];
          segment.lastFlight = segment.flight[segment.transferNumber - 1];
        } else {
          segment.transferNumber = 1;
          segment.firstFlight = segment.flight;
          segment.lastFlight = segment.firstFlight;
        }
      }
    }
    allAirports = [];
    for (i$ = 0, len$ = variants.length; i$ < len$; ++i$) {
      variant = variants[i$];
      for (j$ = 0, len1$ = (ref$ = variant.segments).length; j$ < len1$; ++j$) {
        segment = ref$[j$];
        allAirports.push(segment.firstFlight.departure);
        allAirports.push(segment.lastFlight.arrival);
      }
    }
    allCarriers = _.map(variants, function(variant){
      var ref$;
      return ((ref$ = variant.firstFlight) != null ? ref$.marketingCarrier : void 8) != null;
    });
    allCarriers = _.uniq(allCarriers);
    allAirports = _.uniq(allAirports);
    return database.airports.find({
      iata: {
        $in: allAirports
      }
    }).toArray(function(error, airportsInfo){
      return database.airlines.find({
        iata: {
          $in: allCarriers
        }
      }).toArray(function(error, airlinesInfo){
        var newFlights, i$, ref$, len$, variant, flights, j$, ref1$, len1$, segment, arrivalDestinationDate, departureOriginDate, departureAirport, arrivalAirport, carrier, utcArrivalDate, utcDepartureDate, flightTimeSpan, newFlight;
        newFlights = [];
        for (i$ = 0, len$ = (ref$ = variants).length; i$ < len$; ++i$) {
          variant = ref$[i$];
          flights = [];
          for (j$ = 0, len1$ = (ref1$ = variant.segments).length; j$ < len1$; ++j$) {
            segment = ref1$[j$];
            arrivalDestinationDate = moment(segment.lastFlight.arrivalDate + 'T' + segment.lastFlight.arrivalTime);
            departureOriginDate = moment(segment.firstFlight.departureDate + 'T' + segment.firstFlight.departureTime);
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
              stops: segment.transferNumber - 1,
              url: segment.url + 'ostroterra'
            };
            flights.push(newFlight);
          }
          newFlights.push({
            price: parseInt(variant.price),
            provider: exports.name,
            segments: flights,
            type: 'flight'
          });
        }
        return cb(null, {
          results: newFlights,
          complete: true
        });
        function fn$(el){
          return el.iata === segment.firstFlight.departure;
        }
        function fn1$(el){
          return el.iata === segment.lastFlight.arrival;
        }
        function fn2$(el){
          var ref$;
          return el.iata === (((ref$ = segment.lastFlight) != null ? ref$.marketingCarrier : void 8) != null);
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
