_ 			= require "underscore"
async		= require "async"
database 	= require "./../database"
geobase 	= require "./../geobase"
links		= require "./links"
md5 		= require "MD5"
providers 	= require "./providers"
rome2rio 	= require "./providers/rome2rio"
validation 	= require "./validation"

fixDestination = (pair, cb) ->

	(error, airports) <- geobase.findRoute pair.origin.place, pair.destination.place
	return cb error, null if error

	pair.origin.nearest_airport 		= airports.originAirport
	pair.destination.nearest_airport 	= airports.destinationAirport

	cb null, pair

makePairs = (data, cb) ->
	
	for trip, tripNumber in data.trips
		trip.tripNumber 		= tripNumber
		trip.isLast 			= tripNumber is (data.trips.length-1)
		trip.destinationIndex	= if trip.isLast then 0 else tripNumber + 1

	pairs 		= []
	
	(error, pairs) <- async.map data.trips, (trip, callback) ->

		pair = 
			destination : data.trips[trip.destinationIndex]
			origin		: data.trips[trip.tripNumber]
			extra		: 
				adults	: data.adults
				page	: 1

		(error, pair) <- fixDestination pair
		return cb error, null if error

		pair.flights_signature 	= md5(JSON.stringify(pair.origin.place) 		+ JSON.stringify(pair.destination.place) 	+ pair.origin.date)
		
		pair.hotels_signature 	= md5(JSON.stringify(pair.destination.place) 	+ pair.origin.date 							+ pair.destination.date)
		pair.hotels_signature 	= null if trip.isLast
			
		callback null, pair

	return cb error, null if error

	flightSignatures= _.map( pairs, (pair) -> pair.flights_signature)
	
	hotelSignatures = _.map( pairs, (pair) -> pair.hotels_signature )
	hotelSignatures.pop()

	allSignatures 	= flightSignatures.concat hotelSignatures

	cb null, do
		pairs 			: pairs
		signatures 		: allSignatures

exports.search = (err, socket, session) ->
	
	socket.on 'search', (data) ->
		(error, data) <- validation.search data
		return socket.emit 'search_error', error: error if error

		database.search.insert(data)
		socket.emit 'search_ok', {} 

	socket.on 'pre_search', (searchParams) ->

		(error, result)		<- makePairs searchParams
		pairs 				= result.pairs

		callbacks = []
		_.map pairs, (pair) -> do ->

			# flights
			_.map providers.flightProviders, (provider) -> do ->
				callbacks.push (callback) ->
					(error, result) <- provider.search pair.origin, pair.destination, pair.extra

			# hotels
			return if not pair.hotels_signature
			_.map providers.hotelProviders, (provider) -> do ->
				callbacks.push (callback) ->
					(error, result) <- provider.search pair.origin, pair.destination, pair.extra
					
		async.parallel callbacks


	socket.on 'search_start', (data) ->

		(error, data) 			<- validation.start_search data
		return socket.emit 'start_search_error', error: error if error

		(error, searchParams) 	<- database.search.findOne data
		return socket.emit 'start_search_error', error: error if not searchParams
		delete searchParams._id

		(error, result)		<- makePairs searchParams
		pairs 				= result.pairs
		signatures 			= _.map(result.signatures, (signature) -> [signature, 0]) |> _.object
		totalProviders 		= (pairs.length - 1) * providers.allProviders.length + providers.flightProviders.length
		providersReady		= 0
		
		socket.emit 'search_started', do
			form  : searchParams
			trips : pairs 

		resultReady = (params) ->

			items 	 = params.result?.results 	or []
			complete = params.result?.complete  or false
			error    = params.error?.message 	or null

			console.log "SOCKET: #{params.event} 
			| Complete: #{complete} 
			| Provider: #{params.provider.name} 
			| Error: #{error} 
			| \# results: #{items.length}"
			
			providersReady += 1 if (complete or error or not items.length)

			# patching for redirect
			for item in items
				item.hash = links.getLinkHash item

			socket.emit params.event, do
				error     : error
				items     : items
				signature : params.signature
				progress  : 1

			progress = _.min([1, providersReady.toFixed(2) / totalProviders])

			console.log "SOCKET: progress | value: #{progress}"
			
			socket.emit 'progress', do
				hash	: searchParams.hash
				progress: progress
		
		callbacks = []
		_.map pairs, (pair) -> do ->

			# flights
			_.map providers.flightProviders, (provider) -> do ->
				callbacks.push (callback) ->
					(error, result) <- provider.search pair.origin, pair.destination, pair.extra
					resultReady do
						error 		: error
						event 		: \flights_ready
						result 		: result
						pair 		: pair
						provider 	: provider
						signature 	: pair.flights_signature

			# hotels
			return if not pair.hotels_signature
			_.map providers.hotelProviders, (provider) -> do ->
				callbacks.push (callback) ->
					(error, result) <- provider.search pair.origin, pair.destination, pair.extra
					resultReady do
						error 		: error
						event 		: \hotels_ready
						result 		: result
						pair 		: pair
						provider 	: provider
						signature 	: pair.hotels_signature
						
		async.parallel callbacks

	socket.on 'serp_selected', (data) ->

		(error, data) 			<- validation.serp_selected data
		return socket.emit 'serp_selected_error', error : error if error

		(error, searchParams) 	<- database.search.findOne hash : data.search_hash
		return socket.emit 'serp_selected_error', error : error if error

		(error, trip)			<- database.trips.findOne trip_hash : data.trip_hash
		database.trips.insert data if not trip

		session.trip_hash 	= data.trip_hash
		session.search_hash = data.search_hash

		session.save!

		socket.emit 'serp_selected_ok', {} 

	socket.on 'selected_list_fetch', (data) ->
		
		(error, trip)			<- database.trips.findOne trip_hash : data.trip_hash
		return socket.emit 'selected_list_fetch_error', error: error if (error or not trip)
		delete trip._id

		socket.emit 'selected_list_fetch_ok', trip 
