_ 			= require "underscore"
database 	= require "./../database"
md5 		= require "MD5"
providers 	= require "./providers"
validation 	= require "./validation"

makePairs = (data) ->
	pairs = []
	
	for trip, tripNumber in data.trips

		if tripNumber is (data.trips.length-1)
			destinationIndex = 0
		else
			destinationIndex = tripNumber + 1

		pair = 
			destination 	: data.trips[destinationIndex]
			origin			: data.trips[tripNumber]

		pair.flights_signature 	= md5(JSON.stringify(pair.origin.place) + JSON.stringify(pair.destination.place) + pair.origin.date)
		
		if tripNumber is not (data.trips.length - 1)
			pair.hotels_signature 		= md5(JSON.stringify(pair.destination.place) + pair.origin.date + pair.destination.date)
		else
			pair.hotels_signature 		= null
		
		pairs.push pair

	allSignatures = _.map(pairs, (pair)->pair.flights_signature).concat(_.map(pairs, (pair)->pair.hotels_signature))
	allSignatures.pop()

	return {
		pairs 		: pairs,
		signatures 	: allSignatures 
	}

exports.search = (socket) ->
	socket.on 'search', (data) ->
		(error, data) <- validation.search data
		return socket.emit 'search_error', {error: error} if error

		database.search.insert(data)
		socket.emit 'search_ok', {} 

	socket.on 'search_start', (data) ->
		(error, data) <- validation.start_search data
		return socket.emit 'start_search_error', {error: error} if error

		(error, searchParams) <- database.search.findOne(data)
		return socket.emit 'start_search_error', {error: error} if error

		result 			= makePairs(searchParams)
		pairs 			= result.pairs
		signatures 		= {}

		delete searchParams._id

		socket.emit 'search_started', {
			form 	: searchParams
			trips 	: pairs
		}

		for signature in result.signatures
			signatures[signature] = false
	 
		# --- start helper functions ---
		resultReady = (error, items, eventName, signature) ->

			results = if error then [] else items.results

			console.log "socket.emit #{eventName}
			| Complete: #{items?.complete or ''} 
			| Error: #{error?.message or ''}
			| \# results: #{results.length}"
			
			socket.emit eventName , {
				error     	: error
				items   	: results
				signature 	: signature
			}

			if items?.complete or error
				signatures[signature] = true

			complete = _.filter(_.values(signatures), (elem) -> elem is true).length
			total    = _.values(signatures).length

			console.log "#{complete} / #{total}"

			socket.emit 'progress', {progress: complete.toFixed(2) / total}

		flightsReady 	= (error, items, signature) -> resultReady error, items, 'flights_ready', signature
		hotelsReady		= (error, items, signature) -> resultReady error, items, 'hotels_ready',  signature
		# --- end helper functions ---  

		for pair in pairs
			destination = pair.destination
			origin      = pair.origin
			extra       = 
				adults: searchParams.adults
				page: 1

			for flightProvider, counter in providers.flightProviders
				let signature = pair.flights_signature
					(error, items) <- flightProvider.search origin, destination, extra
					flightsReady error, items, signature

			for hotelProvider, counter 	in providers.hotelProviders when counter < (pairs.length - 1)
				let signature = pair.hotels_signature
					if signature
						(error, items) <- hotelProvider.search origin, destination, extra
						hotelsReady error, items, signature
						