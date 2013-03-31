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
  exports.name = 'aviasales.ru';
  query = function(origin, destination, extra, cb){
    var ref$, originIata, destinationIata, searchParams, sortedKeys, paramsString, signature, command;
    if ((ref$ = origin.nearest_airport) != null && ref$.iata) {
      originIata = (ref$ = origin.nearest_airport) != null ? ref$.iata : void 8;
    } else {
      originIata = origin.place.iata;
    }
    if ((ref$ = destination.nearest_airport) != null && ref$.iata) {
      destinationIata = (ref$ = destination.nearest_airport) != null ? ref$.iata : void 8;
    } else {
      destinationIata = destination.place.iata;
    }
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
    if (destination.roundTrip) {
      searchParams.return_date = destination.date;
    }
    sortedKeys = _.keys(searchParams).sort();
    paramsString = [TOKEN, MARKER].concat(_.map(sortedKeys, function(key){
      return searchParams[key];
    })).join(':');
    signature = md5(paramsString);
    if (!destination.roundTrip) {
      command = "curl -v \\\n\t-d \"signature=" + signature + "\" \\\n\t-d \"enable_api_auth=true\" \\\n\t-d \"search[marker]=" + MARKER + "\" \\\n\t-d \"search[params_attributes][origin_name]=" + searchParams.origin_name + "\" \\\n\t-d \"search[params_attributes][destination_name]=" + searchParams.destination_name + "\"\\\n\t-d \"search[params_attributes][depart_date]=" + searchParams.depart_date + "\" \\\n\t-d \"search[params_attributes][adults]=" + searchParams.adults + "\" \\\n\t-d \"search[params_attributes][range]=" + searchParams.range + "\" \\\n\t-d \"search[params_attributes][children]=" + searchParams.children + "\" \\\n\t-d \"search[params_attributes][infants]=" + searchParams.infants + "\" \\\n\t-d \"search[params_attributes][trip_class]=" + searchParams.trip_class + "\" \\\n\t-d \"search[params_attributes][direct]=" + searchParams.direct + "\" \\\n\thttp://nano.aviasales.ru/searches.json";
    } else {
      command = "curl -v \\\n\t-d \"signature=" + signature + "\" \\\n\t-d \"enable_api_auth=true\" \\\n\t-d \"search[marker]=" + MARKER + "\" \\\n\t-d \"search[params_attributes][origin_name]=" + searchParams.origin_name + "\" \\\n\t-d \"search[params_attributes][destination_name]=" + searchParams.destination_name + "\"\\\n\t-d \"search[params_attributes][depart_date]=" + searchParams.depart_date + "\" \\\n\t-d \"search[params_attributes][return_date]=" + searchParams.return_date + "\" \\\n\t-d \"search[params_attributes][adults]=" + searchParams.adults + "\" \\\n\t-d \"search[params_attributes][range]=" + searchParams.range + "\" \\\n\t-d \"search[params_attributes][children]=" + searchParams.children + "\" \\\n\t-d \"search[params_attributes][infants]=" + searchParams.infants + "\" \\\n\t-d \"search[params_attributes][trip_class]=" + searchParams.trip_class + "\" \\\n\t-d \"search[params_attributes][direct]=" + searchParams.direct + "\" \\\n\thttp://nano.aviasales.ru/searches.json";
    }
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
  process = function(json, isRoundTrip, cb){
    var i$, ref$, len$, ticket, allAirports, allCarriers;
    if (!json || !json.tickets) {
      return cb({
        message: 'no flights found'
      }, null);
    }
    for (i$ = 0, len$ = (ref$ = json.tickets).length; i$ < len$; ++i$) {
      ticket = ref$[i$];
      ticket.transferDirectNumber = ticket.direct_flights.length;
      ticket.firstDirectFlight = ticket.direct_flights[0];
      ticket.lastDirectFlight = ticket.direct_flights[ticket.transferDirectNumber - 1];
      if (isRoundTrip) {
        ticket.transferReturnNumber = ticket.return_flights.length;
        ticket.firstReturnFlight = ticket.return_flights[0];
        ticket.lastReturnFlight = ticket.return_flights[ticket.transferReturnNumber - 1];
      }
    }
    allAirports = _.map(json.tickets, function(ticket){
      return ticket.firstDirectFlight.origin;
    });
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.firstDirectFlight.destination;
    }));
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.lastDirectFlight.origin;
    }));
    allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
      return ticket.lastDirectFlight.destination;
    }));
    if (isRoundTrip) {
      allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
        return ticket.firstReturnFlight.origin;
      }));
      allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
        return ticket.firstReturnFlight.destination;
      }));
      allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
        return ticket.lastReturnFlight.origin;
      }));
      allAirports = allAirports.concat(_.map(json.tickets, function(ticket){
        return ticket.lastReturnFlight.destination;
      }));
    }
    allAirports = _.uniq(allAirports);
    allCarriers = _.map(json.tickets, function(ticket){
      return ticket.firstDirectFlight.airline;
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
          var departureAirport, arrivalAirport, carrier, departure, arrival, utcDeparture, utcArrival, duration, directFlight, segments, returnFlight, result;
          departureAirport = _.filter(airportsInfo, function(el){
            return el.iata === ticket.firstDirectFlight.origin;
          })[0];
          arrivalAirport = _.filter(airportsInfo, function(el){
            return el.iata === ticket.firstDirectFlight.destination;
          })[0];
          carrier = _.filter(airlinesInfo, function(el){
            return el.iata === ticket.firstDirectFlight.airline;
          })[0];
          if (carrier) {
            delete carrier._id;
          }
          departure = moment.unix(ticket.direct_flights[0].departure);
          arrival = moment.unix(ticket.direct_flights[ticket.transferDirectNumber - 1].arrival);
          utcDeparture = departure.clone().subtract('hours', departureAirport.timezone);
          utcArrival = arrival.clone().subtract('hours', arrivalAirport.timezone);
          duration = utcArrival.diff(utcDeparture, 'hours');
          directFlight = {
            arrival: arrival.format("hh:mm"),
            carrier: [carrier],
            departure: departure.format("hh:mm"),
            duration: duration * 60 * 60,
            stops: ticket.transferDirectNumber - 1
          };
          segments = [directFlight];
          if (isRoundTrip) {
            departureAirport = _.filter(airportsInfo, function(el){
              return el.iata === ticket.firstReturnFlight.origin;
            })[0];
            arrivalAirport = _.filter(airportsInfo, function(el){
              return el.iata === ticket.firstReturnFlight.destination;
            })[0];
            carrier = _.filter(airlinesInfo, function(el){
              return el.iata === ticket.firstReturnFlight.airline;
            })[0];
            if (carrier) {
              delete carrier._id;
            }
            departure = moment.unix(ticket.return_flights[0].departure);
            arrival = moment.unix(ticket.return_flights[ticket.transferReturnNumber - 1].arrival);
            utcDeparture = departure.clone().subtract('hours', departureAirport.timezone);
            utcArrival = arrival.clone().subtract('hours', arrivalAirport.timezone);
            duration = utcArrival.diff(utcDeparture, 'hours');
            returnFlight = {
              arrival: arrival.format("hh:mm"),
              carrier: [carrier],
              departure: departure.format("hh:mm"),
              duration: duration * 60 * 60,
              stops: ticket.transferReturnNumber - 1
            };
            segments.push(returnFlight);
          }
          result = {
            duration: _.reduce(segments, function(memo, segment){
              return memo + segment.duration;
            }, 0),
            stops: _.reduce(segments, function(memo, segment){
              return memo + segment.stops;
            }, 0),
            segments: segments,
            price: ticket.total,
            provider: exports.name,
            type: 'flight',
            url: "http://nano.aviasales.ru/searches/" + json.search_id + "/order_urls/" + _.keys(ticket.order_urls)[0] + "/"
          };
          return result;
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
      return process(json, !!destination.roundTrip, function(error, results){
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
