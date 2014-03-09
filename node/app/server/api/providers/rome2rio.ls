_			= require "underscore"
cache  		= require "./../../cache"
querystring = require "querystring"

exports.getNeareasAirport = (origin, destniation, cb) ->

	params = 
		key 	: 'YK8wH2AY'
		oName 	: "#{origin.name}, #{origin.country_name}"
		dName 	: "#{destniation.name}, #{destniation.country_name}"

	r2rUrl = "http://evaluate.rome2rio.com/api/1.2/json/Search?" + querystring.stringify params

	(error, body) <- cache.request r2rUrl

	return cb error, null if error

	try
		json = JSON.parse body
	catch error
		return cb message : error, null

	routes = json.routes
	return cb {message : 'no routes dound'}, null if routes.length is 0

	for route in routes
		flightStops = _.filter route.stops, (stop) -> stop.kind is 'airport'
			
		if flightStops.length
			return cb null, flightStops[flightStops.length-1].code 

	return cb message : 'no airports in the route', null
