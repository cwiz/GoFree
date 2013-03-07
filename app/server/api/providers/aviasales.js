(function(){
  var _, cache, database, md5, moment, request, TOKEN, MARKER, query, process;
  _ = require("underscore");
  cache = require("./../../cache");
  database = require("./../../database");
  md5 = require("MD5");
  moment = require("moment");
  request = require("request");
  TOKEN = "734301ac8a847e3845a2d89527aefcba";
  MARKER = "19041";
  exports.name = 'aviasales';
  query = function(origin, destination, extra, cb){
    var searchParams, sortedKeys, paramsString, signature, command;
    searchParams = {
      origin_name: origin.nearest_airport.iata,
      destination_name: destination.nearest_airport.iata,
      depart_date: origin.date,
      adults: extra.adults,
      range: 0,
      children: 0,
      infants: 0,
      trip_class: 0,
      direct: 0
    };
    sortedKeys = _.keys(searchParams).sort();
    paramsString = [TOKEN, MARKER].concat(_.map(sortedKeys, function(key){
      return searchParams[key];
    })).join(':');
    signature = md5(paramsString);
    command = "curl -v \\\n\t-d \"signature=" + signature + "\" \\\n\t-d \"enable_api_auth=true\" \\\n\t-d \"search[marker]=" + MARKER + "\" \\\n\t-d \"search[params_attributes][origin_name]=" + searchParams.origin_name + "\" \\\n\t-d \"search[params_attributes][destination_name]=" + searchParams.destination_name + "\"\\\n\t-d \"search[params_attributes][depart_date]=" + searchParams.depart_date + "\" \\\n\t-d \"search[params_attributes][adults]=" + searchParams.adults + "\" \\\n\t-d \"search[params_attributes][range]=" + searchParams.range + "\" \\\n\t-d \"search[params_attributes][children]=" + searchParams.children + "\" \\\n\t-d \"search[params_attributes][infants]=" + searchParams.infants + "\" \\\n\t-d \"search[params_attributes][trip_class]=" + searchParams.trip_class + "\" \\\n\t-d \"search[params_attributes][direct]=" + searchParams.direct + "\" \\\n\thttp://nano.aviasales.ru/searches.json";
    return cache.exec(command, function(err, result){
      var res, error;
      if (err) {
        return cb(err, null);
      }
      try {
        res = JSON.parse(result);
      } catch (e$) {
        error = e$;
        return cb(error, null);
      }
      return cb(null, res);
    });
  };
  process = function(json, cb){
    var i$, ref$, len$, ticket, allAirports, allCarriers;
    if (!json || !json.tickets) {
      return cb({
        message: 'no flights found'
      }, null);
    }
    for (i$ = 0, len$ = (ref$ = json.tickets).length; i$ < len$; ++i$) {
      ticket = ref$[i$];
      ticket.transferNumber = ticket.direct_flights.length;
      ticket.firstFlight = ticket.direct_flights[0];
      ticket.lastFlight = ticket.direct_flights[ticket.transferNumber - 1];
    }
    allAirports = _.map(json.tickets, function(ticket){
      return ticket.firstFlight.origin;
    });
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.firstFlight.destination;
    }));
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.lastFlight.origin;
    }));
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.lastFlight.destination;
    }));
    allAirports = _.uniq(allAirports);
    allCarriers = _.map(json.tickets, function(ticket){
      return ticket.firstFlight.airline;
    });
    allCarriers = _.uniq(allCarriers);
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
        var results;
        results = _.map(json.tickets, function(ticket){
          var departureAirport, arrivalAirport, carrier, departure, arrival, utcDeparture, utcArrival, duration, result;
          departureAirport = _.filter(airportsInfo, function(el){
            return el.iata === ticket.firstFlight.origin;
          })[0];
          arrivalAirport = _.filter(airportsInfo, function(el){
            return el.iata === ticket.firstFlight.destination;
          })[0];
          carrier = _.filter(airlinesInfo, function(el){
            return el.iata === ticket.firstFlight.airline;
          })[0];
          if (carrier) {
            delete carrier._id;
          }
          departure = moment.unix(ticket.direct_flights[0].departure);
          arrival = moment.unix(ticket.direct_flights[ticket.transferNumber - 1].arrival);
          utcDeparture = departure.clone().subtract('hours', departureAirport.timezone);
          utcArrival = arrival.clone().subtract('hours', arrivalAirport.timezone);
          duration = utcArrival.diff(utcDeparture, 'hours');
          return result = {
            arrival: arrival.format("hh:mm"),
            carrier: [carrier],
            departure: departure.format("hh:mm"),
            duration: duration * 60 * 60,
            price: ticket.total,
            provider: 'aviasales',
            type: 'flight',
            stops: ticket.transferNumber - 1,
            url: "http://nano.aviasales.ru/searches/" + json.search_id + "/order_urls/" + _.keys(ticket.order_urls)[0] + "/"
          };
        });
        return cb(null, results);
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
        return cb(null, {
          results: results,
          complete: true
        });
      });
    });
  };
}).call(this);
