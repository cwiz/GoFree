_ 			= require "underscore"
async		= require "async"
database 	= require "./../database"
md5 		= require "MD5"
providers 	= require "./providers"
validation 	= require "./validation"

makePairs = (data) ->
	pairs = []
	
	for trip, tripNumber in data.trips

		isLastTrip 		= tripNumber is (data.trips.length-1) 

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

		socket.emit 'search_started', do
			form  : searchParams
			trips : pairs 

		# --- start helper functions --- 
		resultReady = (error, result, eventName, signature, totalProviders) ->

			items 	 = result?.results 	or []
			complete = result?.complete
			error    = error?.message 	or null

			signatures[signature] += 1.0 / totalProviders if complete or error

			console.log "SOCKET: #{eventName} | Complete: #{complete} | Error: #{error} | \# results: #{items.length}"
			
			socket.emit eventName, do
				error     : error
				items     : items
				signature : signature
				progress  : 1

			complete = _.filter(_.values(signatures), (elem) -> elem).length
			total    = _.values(signatures).length

			progress = complete.toFixed(2) / total

			console.log "SOCKET: progress | value: #{progress}"
			
			socket.emit 'progress', do
				hash	: searchParams.hash
				progress: progress

		flightsReady 	= (error, items, signature) -> resultReady error, items, 'flights_ready', signature, providers.flightProviders.length
		hotelsReady		= (error, items, signature) -> resultReady error, items, 'hotels_ready',  signature, providers.hotelProviders.length
		# --- end helper functions ---  

		callbacks = []
		
		_.map pairs, (pair) -> 

			do ->
				with copyPair = pair
					_.map providers.flightProviders, (provider) -> do ->
						callbacks.push (callback) ->
							(error, items) <- provider.search copyPair.origin, copyPair.destination, copyPair.extra
							flightsReady error, items, copyPair.flights_signature

				return if not pair.hotels_signature
					
				hotelOperations = _.map providers.hotelProviders, (provider) -> do ->
					with copyPair = pair
						callbacks.push (callback) ->
							(error, items) <- provider.search copyPair.origin, copyPair.destination, copyPair.extra
							hotelsReady error, items, copyPair.hotels_signature
						
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
