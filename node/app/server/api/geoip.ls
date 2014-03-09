database 	= require "./../database"
geoip 		= require "geoip-lite"

exports.get_location = (req, res) ->
	ip = req.connection.remoteAddress
	ip = '93.80.144.90' if ip is '127.0.0.1'

	location = geoip.lookup(ip)

	return res.json {
		status	: \error
		message	: 'nothign found'
	} if not location

	(error, city) <- database.geonames.findOne {
		country_code: location.country
		name		: location.city
	}

	return res.json {
		status	: \error
		message	: error
	} if error or not city

	delete city._id

	city.name_ru_lower 		= city.name_ru_lower_collection[0]
	city.name_ru 			= city.name_ru_collection[0]
	city.name_ru_inflected 	= city.name_ru_inflected_collection[0]

	res.json {
		status	: \ok
		value	: city
	}