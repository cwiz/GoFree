_		= require "underscore"
cache  	= require "./../../cache"

exports.getNeareasAirport = (origin, destniation, cb) ->
	r2rUrl = "http://evaluate.rome2rio.com/api/1.2/json/Search?key=YK8wH2AY&oName=#{origin.place.name}, #{origin.place.country_name}&dName=#{destniation.place.name}, #{destniation.place.country_name}"

	(error, body) <- cache.request r2rUrl
	return cb error, null if error

	json = JSON.parse body
	routes = json.routes
	return cb {message : 'no routes dound'}, null if routes.length is 0

	bestRoute = routes[0]
	flightStops = _.filter bestRoute.stops, (stop) -> stop.kind is 'airport'
	return cb {message : 'no airports in the route'}, null if flightStops.length is 0

	cb null, flightStops[flightStops.length-1].code
