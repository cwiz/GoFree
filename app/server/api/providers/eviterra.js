(function(){
  var async, database, moment, request, xml2js, _, parser;
  async = require("async");
  database = require("./../../database");
  moment = require("moment");
  request = require("request");
  xml2js = require("xml2js");
  _ = require("underscore");
  parser = new xml2js.Parser(xml2js.defaults["0.1"]);
  moment.lang('ru');
  exports.name = "eviterra";
  exports.query = function(origin, destination, extra, cb){
    var evUrl;
    evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=" + origin.place.iata + "&to=" + destination.place.iata + "&date1=" + origin.date + "&adults=" + extra.adults;
    return request(evUrl, function(error, response, body){
      console.log("Queried Eviterra serp | " + evUrl + " | status " + response.statusCode);
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
  };
  exports.process = function(flights, cb){
    var i$, ref$, len$, variant, allAirports;
    console.log("Processing Eviterra serp");
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
    allAirports = _.uniq(allAirports);
    return database.airports.find({
      iata: {
        $in: allAirports
      }
    }).toArray(function(err, airportsInfo){
      var newFlights, i$, ref$, len$, variant, arrivalDestinationDate, departureOriginDate, departureAirport, arrivalAirport, utcArrivalDate, utcDepartureDate, flightTimeSpan, newFlight;
      newFlights = [];
      for (i$ = 0, len$ = (ref$ = flights.variant).length; i$ < len$; ++i$) {
        variant = ref$[i$];
        arrivalDestinationDate = moment(variant.lastFlight.arrivalDate + 'T' + variant.lastFlight.arrivalTime);
        departureOriginDate = moment(variant.firstFlight.departureDate + 'T' + variant.firstFlight.departureTime);
        departureAirport = _.filter(airportsInfo, fn$)[0];
        arrivalAirport = _.filter(airportsInfo, fn1$)[0];
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
          arrival: arrivalDestinationDate.format('LL'),
          departure: departureOriginDate.format('LL'),
          price: parseInt(variant.price),
          timeSpan: flightTimeSpan,
          transferNumber: variant.transferNumber - 1,
          url: variant.url + "ostroterra",
          provider: "eviterra"
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
    });
  };
  exports.search = function(origin, destination, extra, cb){
    return exports.query(origin, destination, extra, function(error, json){
      if (error) {
        return cb(error, null);
      }
      return exports.process(json, function(error, results){
        if (error) {
          return cb(error, null);
        }
        return cb(null, results);
      });
    });
  };
  exports.autocomplete = function(query, callback){
    var eviterraUrl;
    eviterraUrl = "https://eviterra.com/complete.json?val=" + query;
    return request(eviterraUrl, function(error, response, body){
      var json, finalJson, i$, ref$, len$, item, name, country, iata, displayName;
      console.log("Queried eviterra autocomplete | " + eviterraUrl + " | status " + response.statusCode);
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
      callback(null, finalJson);
    });
  };
}).call(this);
