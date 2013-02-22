_ 			= require "underscore"
async		= require "async"
database 	= require "./../database"
md5 		= require "MD5"
providers 	= require "./providers"
validation 	= require "./validation"

makePairs = (data) ->
	pairs = []
	
	for trip, tripNumber in data.trips

		isLastTrip 		 = tripNumber is (data.trips.length-1) 
		destinationIndex = if isLastTrip then 0 else tripNumber + 1
			
		pair = 
			destination : data.trips[destinationIndex]
			origin		: data.trips[tripNumber]
			extra		: 
				adults	: data.adults
				page	: 1

		pair.flights_signature 	= md5(JSON.stringify(pair.origin.place) 		+ JSON.stringify(pair.destination.place) 	+ pair.origin.date)
		
		pair.hotels_signature 	= md5(JSON.stringify(pair.destination.place) 	+ pair.origin.date 							+ pair.destination.date)
		pair.hotels_signature 	= null if isLastTrip
			
		pairs.push pair

	flightSignatures= _.map( pairs, (pair) -> pair.flights_signature)
	
	hotelSignatures = _.map( pairs, (pair) -> pair.hotels_signature )
	hotelSignatures.pop()

	allSignatures 	= flightSignatures.concat hotelSignatures

	return do
		pairs 			: pairs
		signatures 		: allSignatures

exports.search = (socket) ->
	
	socket.on 'search', (data) ->
		(error, data) <- validation.search data
		return socket.emit 'search_error', {error: error} if error

		database.search.insert(data)
		socket.emit 'search_ok', {} 

	socket.on 'search_start', (data) ->

		(error, data) 			<- validation.start_search data
		return socket.emit 'start_search_error', {error: error} if error

		(error, searchParams) 	<- database.search.findOne data
		return socket.emit 'start_search_error', {error: error} if not searchParams

		delete searchParams._id

		result 				= makePairs searchParams
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
			
			providersReady += 1 if (complete or error)

			socket.emit params.event, do
				error     : error
				items     : items
				signature : params.signature
				progress  : 1

			progress = providersReady.toFixed(2) / totalProviders

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
		return socket.emit 'serp_selected_error', { error : error } if error

		(error, searchParams) 	<- database.search.findOne { hash : data.search_hash }
		return socket.emit 'serp_selected_error', { error : error } if error

		(error, trip)			<- database.trips.findOne  { hash : data.trip_hash }
		return if trip

		database.trips.insert data

		socket.emit 'serp_selected_ok', {}
