_			= require "underscore"
async		= require "async"
database 	= require "./database"
S			= require "string"
rome2rio 	= require "./api/providers/rome2rio"

exports.extend_geoname = (geoname, params) ->
	if params?.regexp_query
		for name_ru_lower, i in geoname.name_ru_lower_collection when name_ru_lower.match params.regexp_query

			geoname.name_ru_lower 		= name_ru_lower
			geoname.name_ru 			= geoname.name_ru_collection[i]
			geoname.name_ru_inflected 	= geoname.name_ru_inflected_collection[i]

	geoname.name_ru 			= geoname.name_ru_collection[0] 			if not geoname.name_ru 
	geoname.name_ru_inflected 	= geoname.name_ru_inflected_collection[0] 	if not geoname.name_ru_inflected 
	geoname.name_ru_lower 		= geoname.name_ru_lower_collection[0] 		if not geoname.name_ru_lower 

	delete geoname._id
	delete geoname.name_ru_collection
	delete geoname.name_ru_inflected_collection
	delete geoname.name_ru_lower_collection

	return geoname

exports.autocomplete = (query, callback) ->
	
	query 			= S(query).toLowerCase!.replaceAll('-', '_').replaceAll(' ', '_').s
	regexp_query 	= new RegExp("^#{query}")
	
	(error, results) <- database.geonames.find {
		$or : [	
			{ name_lower				: regexp_query }
			{ name_ru_lower_collection	: regexp_query }
		] 
		population 			: $gte: 10000
		name_ru_collection  : $ne: []
	}
	.limit 10
	.sort population: -1 
	.toArray!

	return callback error, null if error

	results = _.map results, (r) -> exports.extend_geoname r, regexp_query : regexp_query
	callback null, results

getNeareastAirport = (origin, destination, cb) ->
	
	(error, iata) 	 <- rome2rio.getNeareasAirport origin, destination
	return cb error, null if error

	(error, result) <- async.parallel do 
		geoname: (callback) -> database.geonames.findOne iata: iata, callback
		airport: (callback) -> database.airports.findOne iata: iata, callback
	return cb error, null if error

	if result.geoname
		cb null, exports.extend_geoname result.geoname

	else if result.airport
		(error, geoname) <- database.geonames.findOne do 
			country_name: result.airport.country
			name 		: result.airport.city
		return cb error, null if (error or not geoname)

		cb null, exports.extend_geoname geoname

	else
		cb message: 'nothing found', null


exports.findRoute = (origin, destination, cb) ->

	originAirport 		= if origin.iata 	  then origin 	   else null
	destinationAirport 	= if destination.iata then destination else null

	return cb null, { 
		destinationAirport 	: destinationAirport
		originAirport		: originAirport
	} if (originAirport and destinationAirport)

	operations = {}

	operations.originAirport = (callback) ->
		if not originAirport
			(error, airport) <- getNeareastAirport destination, origin
			callback error, (airport or origin)
		else
			callback null, originAirport

	operations.destinationAirport = (callback) -> 
		if not destinationAirport
			(error, airport) <- getNeareastAirport origin, destination
			callback error, (airport or destination)
		else
			callback null, destinationAirport

	(error, results) <- async.parallel operations
	cb null, results
	