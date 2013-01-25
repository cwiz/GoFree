providers 	= require "./providers"
validation 	= require "./validation"
database 	= require "./../database"

md5 		= require "MD5"

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

		pair.flightSignature 	= md5(JSON.stringify(origin.place) + JSON.stringify(destination.place) + origin.date)
		pair.hotelSignaure 		= md5(JSON.stringify(destination.place) + origin.date + destination.date)
		
		pairs.push pair

	return pairs

exports.search = (socket) ->
	socket.on 'search', (data) ->

		(error, data) <- validation.search data
		return socket.emit 'search_error', {error: error} if error

		database.search.insert(data)
		socket.emit 'search_validation_ok', {} 

	socket.on 'search_start', (data) ->

		(error, data) <- validation.start_search data
		return socket.emit 'start_search_error', {error: error} if error

		(error, searchParams) <- database.search.findOne(data)
		return socket.emit 'start_search_error', {error: error} if error

		socket.emit 'search_started', searchParams

		pairs 			= makePairs(searchParams)
		providersReady 	= 0
		totalProviders 	= rows.length * providers.flightProviders.length + (rows.length - 1) * providers.flightProviders.length
	 
		# --- start helper functions ---
		resultReady = (error, items, eventName, signature) ->
			if error
				items = {complete: true}
			
			providersReady += 1 if (error or items.complete)
			percentage      = providersReady.toFixed(2) / totalProviders

			results = if error then [] else items.results

			console.log "socket.emit #{eventName} 
			| Percentage: #{percentage}: #{providersReady} / #{totalProviders} 
			| Complete: #{items.complete or ''} 
			| Error: #{error?.message or ''}
			| \# results: #{results.length}"
			
			socket.emit eventName , {
				error     	: error
				items   	: results
				signature 	: signature
			}

			socket.emit 'progress', {progress: percentage}

		flightsReady 	= (error, items, signature) -> resultReady error, items, 'flights_ready', signature
		hotelsReady		= (error, items, signature) -> resultReady error, items, 'hotels_ready',  signature
		# --- end helper functions ---  

		for pair in rows
			destination = pair.destination
			origin      = pair.origin
			extra       = 
				adults: data.adults
				page: 1

			for flightProvider, counter in providers.flightProviders
				let signature = data.flightSignature
					(error, items) <- flightProvider.search origin, destination, extra
					flightsReady error, items, signature

			for hotelProvider, counter 	in providers.hotelProviders when counter < (pairs.length - 1)
				let signature = data.hotelSignature
					(error, items) <- hotelProvider.search origin, destination, extra
					hotelsReady error, items, signature
						