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

	(error, airport) <- database.airports.findOne iata: iata
	return cb error, null if error

	(error, geoname) <- database.geonames.findOne do 
		country_name: airport.country
		name 		: airport.city.replace('St.', 'Saint')

	geoname.iata = iata
	database.geonames.update( {_id : geoname._id}, {$set: {iata: iata}} )

	return cb error, null if error

	geoname = if geoname then exports.extend_geoname geoname else destination.place
	cb null, geoname

exports.findRoute = (origin, destination, cb) ->

	originAirport 		= if origin.iata 	  then origin 	   else null
	destinationAirport 	= if destination.iata then destination else null

	return cb null, { 
		destinationAirport 	: destinationAirport
		originAirport		: originAirport
	} if originAirport and destinationAirport

	operations = {}

	operations.originAirport = (callback) ->
		if not originAirport
			(error, airport) <- getNeareastAirport destination, origin
			callback error, airport
		else
			callback null, originAirport

	operations.destinationAirport = (callback) -> 
		if not destinationAirport
			(error, airport) <- getNeareastAirport origin, destination
			callback error, airport
		else
			callback null, destinationAirport

	(error, results) <- async.parallel operations
	cb error, results
	