_		= require "underscore"
cache   = require "./../../cache"
md5 	= require "MD5"
moment 	= require "moment"
request = require "request"

TOKEN 	= "734301ac8a847e3845a2d89527aefcba"
MARKER 	= "19041"

query = (origin, destination, extra, cb) ->

	searchParams = 
		origin_name		: origin.place.iata
		destination_name: destination.place.iata
		depart_date		: origin.date
		adults			: extra.adults
		range			: 0
		children		: 0
		infants			: 0
		trip_class		: 0 
		direct			: 0

	sortedKeys 		= _.keys(searchParams).sort!
	paramsString 	= [TOKEN, MARKER].concat(_.map sortedKeys, (key) -> searchParams[key]).join(':')
	signature		= md5 paramsString

	command = """curl -v \\
		\t-d \"signature=#{signature}\" \\
		\t-d \"enable_api_auth=true\" \\
		\t-d \"search[marker]=#{MARKER}\" \\
		\t-d \"search[params_attributes][origin_name]=#{searchParams.origin_name}\" \\
		\t-d \"search[params_attributes][destination_name]=#{searchParams.destination_name}\"\\
		\t-d \"search[params_attributes][depart_date]=#{searchParams.depart_date}\" \\
		\t-d \"search[params_attributes][adults]=#{searchParams.adults}\" \\
		\t-d \"search[params_attributes][range]=#{searchParams.range}\" \\
		\t-d \"search[params_attributes][children]=#{searchParams.children}\" \\
		\t-d \"search[params_attributes][infants]=#{searchParams.infants}\" \\
		\t-d \"search[params_attributes][trip_class]=#{searchParams.trip_class}\" \\
		\t-d \"search[params_attributes][direct]=#{searchParams.direct}\" \\
		\thttp://nano.aviasales.ru/searches.json"""

	(err, result) <- cache.exec command
	return cb err, null if err
	
	cb null, JSON.parse result

process = (json, cb) -> 
	
	results = _.map json.tickets, (ticket) ->

		departure 	= moment ticket.direct_flights[0].departure, 'X'
		arrival 	= moment ticket.direct_flights[0].arrival, 	 'X'
		duration 	= arrival.diff departure, 'hours'

		result = 
			arrival   : arrival.format "hh:mm"
			carrier   : null
			departure : departure.format "hh:mm"
			duration  : duration * 60 * 60
			price     : ticket.total
			provider  : \aviasales
			stops     : ticket.direct_flights.length - 1
			url       : 'yoyoy!' #variant.url + \aviasales

	cb null, results

exports.search = (origin, destination, extra, cb) ->
	(error, json)     <- query origin, destination, extra
	return cb(error, null) if error

	(error, results)  <- process json
	return cb(error, null) if error

	cb null, do
		results	: results
		complete: true

