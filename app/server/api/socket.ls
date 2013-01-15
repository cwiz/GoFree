providers = require "./providers"
JSV       = require("JSV").JSV

validate = (data, cb) ->
	schema = 
		type: 'object'
		properties:
			adults: 
				type: 'integer'
				required: true
				minimum: 1
				maximum: 6

			budget:
				type: 'integer'
				required: true
				minimum: 0

			signature:
				type: 'string'
				required: false
			
			trips:
				type: 'array'
				required: true
				
				items: 
					type: 'object'
					properties:
						
						date:
							type: 'string'
							format: 'date'
							required: true
						
						removable:
							type: 'boolean'
							required: false
						
						place:
							type: 'object'
							required: true

	env     = JSV.createEnvironment()
	report  = env.validate(data, schema)

	if report.errors.length is 0
		cb null, data

	else
		cb report.errors, null

convertToRows = (data) ->
	rows = []
	for trip, tripNumber in data.trips

		if tripNumber is (data.trips.length-1)
			index = 0
		else
			index = tripNumber+1

		console.log tripNumber
		console.log index

		rows.push {
			destination:
				place : data.trips[index].place
				date  : data.trips[index].date
			origin:
				place : data.trips[tripNumber].place
				date  : data.trips[tripNumber].date
		}

	return rows

exports.search = (socket) ->
	socket.on 'start_search', (data) ->

		(errors, data) <- validate data
		return socket.emit 'start_search_validation_error', {errors: errors} if errors

		rows 			= convertToRows(data)
		signature      	= data.signature
		providersReady 	= 0
		totalProviders 	= rows.length * providers.flightProviders.length + (rows.length - 1) * providers.flightProviders.length
	 
		# --- start helper functions ---
		resultReady = (error, items, eventName) ->
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
			
			socket.emit eventName ,
				error     	: error
				items   	: results
				progress  	: percentage
				rowNumber 	: rowNumber
				signature 	: signature

		flightsReady 	= (error, items) -> resultReady error, items, 'flights_ready'
		hotelsReady		= (error, items) -> resultReady error, items, 'hotels_ready'	
		# --- end helper functions ---  

		for row, rowNumber in rows
			destination = row.destination
			origin      = row.origin
			extra       = 
				adults: data.adults
				page: 1

			for flightProvider in providers.flightProviders
				let rowNumber = rowNumber, signature = data.signature
					flightProvider.search origin, destination, extra, flightsReady

			for hotelProvider in providers.hotelProviders
				let rowNumber = rowNumber, signature = data.signature
					if not (rowNumber is (rows.length - 1))
						hotelProvider.search origin, destination, extra, hotelsReady
						