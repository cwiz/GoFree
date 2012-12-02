(function(){
  var async, database, moment, request, Sync, xml2js, parser, getAirportDetails;
  async = require("async");
  database = require("../database.js");
  moment = require("moment");
  request = require("request");
  Sync = require("sync");
  xml2js = require("xml2js");
  parser = new xml2js.Parser();
  moment.lang('ru');
  getAirportDetails = function(iata, callback){
    return database.airports.findOne({
      iata: iata
    }, callback);
  };
  exports.name = "eviterra";
  exports.query = function(origin, destination, extra, cb){
    var evUrl;
    evUrl = "http://api.eviterra.com/avia/v1/variants.xml?from=" + origin.iata + "&to=" + destination.iata + "&date1=" + origin.date + "&adults=" + extra.adults;
    request(evUrl, function(error, response, body){
      console.log(">>> queried eviterra serp | " + evUrl + " | status " + response.statusCode);
      if (error) {
        return;
      }
      parser.parseString(response.body, function(error, json){
        if (error) {
          return;
        }
        return cb(json);
      });
    });
  };
  exports.process = function(flights, cb){
    console.log(">>> processing eviterra serp");
    if (!flights || !flights.variant) {
      return;
    }
    Sync(function(){
      var newFlights, i$, ref$, len$, variant, transferNumber, firstFlight, lastFlight, arrivalDestinationDate, departureOriginDate, departureAirport, arrivalAirport, utcArrivalDate, utcDepartureDate, flightTimeSpan, newFlight;
      newFlights = [];
      for (i$ = 0, len$ = (ref$ = flights.variant).length; i$ < len$; ++i$) {
        variant = ref$[i$];
        if (variant.segment.flight.length != null) {
          transferNumber = variant.segment.flight.length;
          firstFlight = variant.segment.flight[0];
          lastFlight = variant.segment.flight[transferNumber - 1];
        } else {
          transferNumber = 1;
          firstFlight = variant.segment.flight;
          lastFlight = firstFlight;
        }
        arrivalDestinationDate = moment(lastFlight.arrivalDate + 'T' + lastFlight.arrivalTime);
        departureOriginDate = moment(firstFlight.departureDate + 'T' + firstFlight.departureTime);
        departureAirport = getAirportDetails.sync(null, firstFlight.departure);
        arrivalAirport = getAirportDetails.sync(null, lastFlight.arrival);
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
          transferNumber: transferNumber - 1,
          url: variant.url + "ostroterra",
          provider: "eviterra"
        };
        newFlights.push(newFlight);
      }
      return cb(newFlights);
    });
  };
  exports.autocomplete = function(query, callback){
    var eviterraUrl;
    eviterraUrl = "https://eviterra.com/complete.json?val=" + query;
    request(eviterraUrl, function(error, response, body){
      var json, finalJson, i$, ref$, len$, item, name, country, iata, displayName;
      console.log(">>> queried eviterra autocomplete | " + eviterraUrl + " | status " + response.statusCode);
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
