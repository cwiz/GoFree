(function(){
  var async, database, moment, request, xml2js, _, parser, getEviterraId, query, process, autocomplete;
  async = require("async");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  xml2js = require("xml2js");
  _ = require("underscore");
  parser = new xml2js.Parser(xml2js.defaults["0.1"]);
  moment.lang('ru');
  exports.name = "eviterra";
  getEviterraId = function(place, callback){
    if (place.eviterra_id) {
      return callback(null, place.eviterra_id);
    }
    return exports.autocomplete(place.name_ru + "", function(error, result){
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
        return getEviterraId(origin.place, callback);
      },
      destination: function(callback){
        return getEviterraId(destination.place, callback);
      }
    }, function(error, eviterraId){
      var evUrl;
      if (error) {
        return cb(error, null);
      }
      evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=" + eviterraId.origin + "&to=" + eviterraId.destination + "&date1=" + origin.date + "&adults=" + extra.adults;
      return request(evUrl, function(error, response, body){
        console.log("EVITERRA: Queried Eviterra serp | " + evUrl + " | status " + response.statusCode);
        if (error) {
          return cb(error, null);
        }
        return parser.parseString(response.body, function(error, json){
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
      return variant.firstFlight.marketingCarrier;
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
            price: parseInt(variant.price),
            arrival: arrivalDestinationDate.format("hh:mm"),
            departure: departureOriginDate.format("hh:mm"),
            duration: flightTimeSpan * 60 * 60,
            stops: variant.transferNumber - 1,
            url: variant.url + 'ostroterra',
            provider: 'eviterra',
            carrier: carrier
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
          return el.iata === variant.lastFlight.marketingCarrier;
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
  autocomplete = function(query, callback){
    var eviterraUrl;
    eviterraUrl = "https://eviterra.com/complete.json?val=" + query;
    return request(eviterraUrl, function(error, response, body){
      var json, finalJson, i$, ref$, len$, item, name, country, iata, displayName;
      console.log("Queried eviterra autocomplete | " + eviterraUrl + " | error: " + error + " | status: " + (response != null ? response.statusCode : void 8));
      if (error) {
        return callback(error, null);
      }
      json = JSON.parse(response.body);
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
}).call(this);
