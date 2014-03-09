# @todo: get rid of curl 
# @todo: ugly, refactor!

_			= require "underscore"
cache   	= require "./../../cache"
database	= require "./../../database"
md5 		= require "MD5"
moment 		= require "moment"
request 	= require "request"

TOKEN 	= "734301ac8a847e3845a2d89527aefcba"
MARKER 	= "19041"

exports.name = 'aviasales.ru'

query = (origin, destination, extra, cb) ->

	if origin.nearest_airport?.iata
		originIata = origin.nearest_airport?.iata
	else
		originIata = origin.place.iata 

	if destination.nearest_airport?.iata
		destinationIata = destination.nearest_airport?.iata 
	else
		destinationIata = destination.place.iata 

	searchParams = 
		origin_name		: origin.nearest_airport.iata 		
		destination_name: destination.nearest_airport.iata
		depart_date		: origin.date
		adults			: extra.adults
		range			: 0
		children		: 0
		infants			: 0
		trip_class		: 0
		direct			: 0

	if destination.roundTrip
		searchParams.return_date = destination.date

	sortedKeys 		= _.keys(searchParams).sort!
	paramsString 	= [TOKEN, MARKER].concat(_.map sortedKeys, (key) -> searchParams[key]).join(':')
	signature		= md5 paramsString

	if not destination.roundTrip
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
	else
		command = """curl -v \\
			\t-d \"signature=#{signature}\" \\
			\t-d \"enable_api_auth=true\" \\
			\t-d \"search[marker]=#{MARKER}\" \\
			\t-d \"search[params_attributes][origin_name]=#{searchParams.origin_name}\" \\
			\t-d \"search[params_attributes][destination_name]=#{searchParams.destination_name}\"\\
			\t-d \"search[params_attributes][depart_date]=#{searchParams.depart_date}\" \\
			\t-d \"search[params_attributes][return_date]=#{searchParams.return_date}\" \\
			\t-d \"search[params_attributes][adults]=#{searchParams.adults}\" \\
			\t-d \"search[params_attributes][range]=#{searchParams.range}\" \\
			\t-d \"search[params_attributes][children]=#{searchParams.children}\" \\
			\t-d \"search[params_attributes][infants]=#{searchParams.infants}\" \\
			\t-d \"search[params_attributes][trip_class]=#{searchParams.trip_class}\" \\
			\t-d \"search[params_attributes][direct]=#{searchParams.direct}\" \\
			\thttp://nano.aviasales.ru/searches.json"""

	(err, result) <- cache.exec command
	return cb err, null if err
	
	try
		res = JSON.parse result
	catch error 
		return cb error, null

	cb null, res

process = (json, isRoundTrip, cb) -> 
	
	return cb message: 'no flights found', null if (not json or not json.tickets)

	for ticket in json.tickets
		
		ticket.transferDirectNumber = ticket.direct_flights.length
		ticket.firstDirectFlight	= ticket.direct_flights[0								]
		ticket.lastDirectFlight		= ticket.direct_flights[ticket.transferDirectNumber - 1	]

		if isRoundTrip
			ticket.transferReturnNumber = ticket.return_flights.length
			ticket.firstReturnFlight	= ticket.return_flights[0							 ]
			ticket.lastReturnFlight		= ticket.return_flights[ticket.transferReturnNumber-1]

	allAirports = _.map json.tickets, (ticket) -> ticket.firstDirectFlight.origin
	allAirports = allAirports.concat _.map json.tickets, (ticket) -> ticket.firstDirectFlight.destination
	allAirports = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastDirectFlight.origin
	allAirports = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastDirectFlight.destination

	if isRoundTrip
		allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.firstReturnFlight.origin
		allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.firstReturnFlight.destination
		allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastReturnFlight.origin
		allAirports  = allAirports.concat _.map json.tickets, (ticket) -> ticket.lastReturnFlight.destination

	allAirports = _.uniq allAirports

	allCarriers = _.map json.tickets,  (ticket) -> ticket.firstDirectFlight.airline
	allCarriers = _.uniq allCarriers

	(err, airportsInfo) <- database.airports.find( iata: $in: allAirports ).toArray!
	(err, airlinesInfo) <- database.airlines.find( iata: $in: allCarriers ).toArray!

	results = _.map json.tickets, (ticket) ->

		# direct flight

		departureAirport        = _.filter( airportsInfo, (el) -> el.iata is ticket.firstDirectFlight.origin      )[0]
		arrivalAirport          = _.filter( airportsInfo, (el) -> el.iata is ticket.firstDirectFlight.destination )[0]
		carrier                 = _.filter( airlinesInfo, (el) -> el.iata is ticket.firstDirectFlight.airline     )[0]
		delete carrier._id if carrier

		departure 	 = moment.unix ticket.direct_flights[0].departure
		arrival 	 = moment.unix ticket.direct_flights[ticket.transferDirectNumber-1].arrival

		utcDeparture = departure.clone!.subtract 	'hours', departureAirport.timezone
		utcArrival   = arrival.clone!.subtract 		'hours', arrivalAirport.timezone
		
		duration 	 = utcArrival.diff utcDeparture, 'hours'

		directFlight = 
			arrival   : arrival.format "hh:mm"
			carrier   : [carrier]
			departure : departure.format "hh:mm"
			duration  : duration * 60 * 60
			stops     : ticket.transferDirectNumber - 1

		segments = [directFlight]
			
		if isRoundTrip

			departureAirport = _.filter( airportsInfo, (el) -> el.iata is ticket.firstReturnFlight.origin      )[0]
			arrivalAirport   = _.filter( airportsInfo, (el) -> el.iata is ticket.firstReturnFlight.destination )[0]
			carrier          = _.filter( airlinesInfo, (el) -> el.iata is ticket.firstReturnFlight.airline     )[0]
			
			delete carrier._id if carrier

			departure 	 = moment.unix ticket.return_flights[0].departure
			arrival 	 = moment.unix ticket.return_flights[ticket.transferReturnNumber-1].arrival

			utcDeparture = departure.clone!.subtract 	 'hours', departureAirport.timezone
			utcArrival   = arrival.clone!.subtract 		 'hours', arrivalAirport.timezone
			
			duration 	 = utcArrival.diff utcDeparture, 'hours'

			returnFlight = 
				arrival   : arrival.format "hh:mm"
				carrier   : [carrier]
				departure : departure.format "hh:mm"
				duration  : duration * 60 * 60
				stops     : ticket.transferReturnNumber - 1

			segments.push returnFlight

		result =
			duration  : _.reduce segments, ((memo, segment) -> memo + segment.duration), 0
			stops  	  : _.reduce segments, ((memo, segment) -> memo + segment.stops),	 0

			segments  : segments
			price     : ticket.total
			provider  : exports.name
			type	  : \flight
			url		  : "http://nano.aviasales.ru/searches/#{json.search_id}/order_urls/#{_.keys(ticket.order_urls)[0]}/"

		return result

	cb null, results

exports.search = (origin, destination, extra, cb) ->
	(error, json)     <- query origin, destination, extra
	return cb(error, null) if error

	(error, results)  <- process json, !!destination.roundTrip
	return cb(error, null) if error

	cb null, do
		results	: results
		complete: true
