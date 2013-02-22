_		= require "underscore"
cache   = require "./../../cache"
database= require "./../../database"
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
	return cb {message: 'no flights found'}, null if not json or not json.tickets

	for ticket in json.tickets
		ticket.transferNumber 	= ticket.direct_flights.length
		ticket.firstFlight 		= ticket.direct_flights[0]
		ticket.lastFlight		= ticket.direct_flights[ticket.transferNumber-1]

	allAirports  = _.map json.tickets, (ticket) -> ticket.firstFlight.origin
	allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.firstFlight.destination
	
	allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastFlight.origin
	allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastFlight.destination

	allAirports = _.uniq allAirports

	allCarriers = _.map json.tickets,  (ticket) -> ticket.firstFlight.airline
	allCarriers = _.uniq allCarriers

	(err, airportsInfo) <- database.airports.find({iata:{$in:allAirports}}).toArray()
	(err, airlinesInfo) <- database.airports.find({iata:{$in:allCarriers}}).toArray()

	results = _.map json.tickets, (ticket) ->

		departureAirport        = _.filter( airportsInfo, (el) -> el.iata is ticket.firstFlight.origin      )[0]
		arrivalAirport          = _.filter( airportsInfo, (el) -> el.iata is ticket.firstFlight.destination )[0]

		carrier                 = _.filter( airlinesInfo, (el) -> el.iata is ticket.firstFlight.airline)[0]
		delete carrier._id if carrier

		departure 	= moment.unix(ticket.direct_flights[0						].departure).clone().subtract 'hours', departureAirport.timezone
		arrival 	= moment.unix(ticket.direct_flights[ticket.transferNumber-1 ].arrival  ).clone().subtract 'hours', arrivalAirport.timezone
		duration 	= arrival.diff departure, 'hours'

		result = 
			arrival   : arrival.format "hh:mm"
			carrier   : carrier
			departure : departure.format "hh:mm"
			duration  : duration * 60 * 60
			price     : ticket.total
			provider  : \aviasales
			stops     : ticket.transferNumber - 1
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

