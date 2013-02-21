(function(){
  var _, cache, md5, moment, request, TOKEN, MARKER, query, process;
  _ = require("underscore");
  cache = require("./../../cache");
  md5 = require("MD5");
  moment = require("moment");
  request = require("request");
  TOKEN = "734301ac8a847e3845a2d89527aefcba";
  MARKER = "19041";
  query = function(origin, destination, extra, cb){
    var searchParams, sortedKeys, paramsString, signature, command;
    searchParams = {
      origin_name: origin.place.iata,
      destination_name: destination.place.iata,
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
      if (err) {
        return cb(err, null);
      }
      return cb(null, JSON.parse(result));
    });
  };
  process = function(json, cb){
    var results;
    results = _.map(json.tickets, function(ticket){
      var departure, arrival, duration, result;
      departure = moment(ticket.direct_flights[0].departure, 'X');
      arrival = moment(ticket.direct_flights[0].arrival, 'X');
      duration = arrival.diff(departure, 'hours');
      return result = {
        arrival: arrival.format("hh:mm"),
        carrier: null,
        departure: departure.format("hh:mm"),
        duration: duration * 60 * 60,
        price: ticket.total,
        provider: 'aviasales',
        stops: ticket.direct_flights.length - 1,
        url: 'yoyoy!'
      };
    });
    return cb(null, results);
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
