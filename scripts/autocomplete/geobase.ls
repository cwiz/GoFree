_ 			= require "underscore"
async		= require "async"
csv       	= require "csv"
database  	= require "./../../app/server/database.ls"
progressBar = require "progress-bar"

importFile = (filename, singleOperation, collectionOperation, callback)->

	operations = []

	console.log "Importing: #{filename}"

	csv().from.path filename, 
		delimiter	: "\t"
		columns		: null
		escape		: null
		quote		: null

	.transform (data) ->
		data

	.on "record", (data, index) ->
		operation = singleOperation(data, operations.length)
		operations.push operation if operation

	.on "error", (err) ->
		console.log err

	.on "end", (count) ->
		console.log "Performing DB operation on #{operations.length} operations."
		collectionOperation(operations)


valid_geo_ids = {}

importBaseGeonames = (callback)->
	importFile(
		"./cities1000.txt",  
		(
			(data, index) ->
				object = {
					geoname_id 		: parseInt(data[0])
					
					name			: data[1]
					name_ru			: null

					longitude 		: parseFloat(data[4] or 0)
					latitude 		: parseFloat(data[4] or 0)
					
					population 		: parseInt(data[14] or 0)
					timezone 		: data[17]
							
					country_code 	: data[8]	
					country_name_ru : null
					country_name    : null
				}

				valid_geo_ids[object.geoname_id] = true

				return object
		),
		(
			(operations) ->
				database.geonames.insert operations
				console.log 'Done!'
				callback null, operations.length
		)
	)


importRuGeonames = (callback)->

	bar = progressBar.create process.stdout

	importFile(
		"./ruNames.txt",  
		(
			(data, index) ->
				geoname = {
					geoname_id		: parseInt(data[1])
					name_ru 		: data[3]
				}

				if not valid_geo_ids[geoname.geoname_id]
					return null
				
				geoname.name_ru_lower = geoname.name_ru.toLowerCase().replace('-', '_').replace(' ', '_')

				operation = (total, cb) ->	
					database.geonames.update(
						{ geoname_id: geoname.geoname_id }, 
						{ 
							$set: {
								name_ru 		: geoname.name_ru
								name_ru_lower 	: geoname.name_ru_lower
							}
						},
						(error, result) ->
							bar.update(Math.min(index.toFixed(2)/total, 1));
							cb error, result
					)
		),
		(
			(operations) ->
				async.series(
					_.map operations, (operation) -> (callback) -> operation(operations.length, callback)
					(err, result) ->
						console.log 'Done!'
						console.log "#{err} | #{result.length}"
						callback err, result
				)
		)
	)
		
importRuCountries = (callback)->

	bar = progressBar.create process.stdout

	importFile(
		"./countryCodes-ru.txt",  
		(
			(data, index) ->
				country = {
					code 		: data[0]
					name_ru		: data[4]
					geoname_id 	: parseInt(data[11])
				}

				return null if not country
				
				return operation = (total, cb) -> 
					database.geonames.update(
						{ country_code: country.code }, 
						{ $set: { country_name_ru : country.name_ru }},
						true, true,
						(error, result) ->
							bar.update(index.toFixed(2)/total);
							cb error, result
					)
		),
		(
			(operations) ->
				async.series(
					_.map operations, (operation) -> (callback) -> operation(operations.length, callback)
					(err, result) ->
						console.log 'Done!'
						console.log "#{err} | #{result.length}"
						callback err, result
				)
		)
	)

importEnCountries = (callback)->

	bar = progressBar.create process.stdout

	importFile(
		"./countryCodes-en.txt",  
		(
			(data, index) ->
				country = {
					code 		: data[0]
					name		: data[4]
					geoname_id 	: parseInt(data[11])
				}

				return null if not country
					
				return operation = (total, cb) -> 
					database.geonames.update(
						{ country_code: country.code }, 
						{ $set: { country_name : country.name }},
						true, true,
						(error, result) ->
							bar.update(index.toFixed(2)/total);
							cb error, result
					)
		),
		(
			(operations) ->
				async.series(
					_.map operations, (operation) -> (callback) -> operation(operations.length, callback)
					(err, result) ->
						console.log 'Done!'
						console.log "#{err} | #{result.length}"
						callback err, result
				)
		)
	)

syncWithAirports = (callback) ->

	console.log 'Syncing with airports'
	bar = progressBar.create process.stdout

	(err, airports) <- database.airports.find().toArray()
	operations = []

	for airport, number in airports
		let object = airport, number = number
			operation = (cb) ->
				database.geonames.update(
					{ country_name: object.country, name: object.city },
					{ $set: { iata: object.iata } },
					(error, result) ->
						bar.update(number.toFixed(2)/airports.length);
						cb error, result
				)

			operations.push operation


	console.log "Performing DB operation on #{operations.length} operations."
	async.series operations, callback

setTimeout( (
	->
		async.series([
			(callback) -> database.geonames.drop(callback), 
			importBaseGeonames, 
			importRuGeonames, 
			importRuCountries, 
			importEnCountries, 
			syncWithAirports,
			(callback) -> process.exit()
		])
	), 1000
)