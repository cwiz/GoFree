_ 			= require "underscore"
async		= require "async"
csv       	= require "csv"
database  	= require "./../../app/server/database.ls"
exec		= require("child_process").exec
progressBar = require "progress-bar"

String.prototype.capitalize = ->
	return this.charAt(0).toUpperCase() + this.slice(1)

String.prototype.replaceAll = (search, replace) ->
	return this.split(search).join(replace);

String.prototype.trim = ->
	return this.replace(/^\s+|\s+$/g, "")

importFile = (filename, singleOperation, collectionOperation, callback)->

	operations = []

	console.log "Importing: #{filename}"

	csv().from.path __dirname + filename, 
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
		"/cities1000.txt",  
		(
			(data, index) ->
				object = {
					geoname_id 				: parseInt(data[0])
					
					name					: data[1]
					name_ru_collection		: []
					name_lower_collection	: []

					longitude 				: parseFloat(data[4] or 0)
					latitude 				: parseFloat(data[4] or 0)
					
					population 				: parseInt(data[14] or 0)
					timezone 				: data[17]
							
					country_code 			: data[8]	
					country_name_ru 		: null
					country_name    		: null
				}

				object.name_lower = object.name.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')

				valid_geo_ids[object.geoname_id] = true

				if object.population <= 10000
					return null

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
		"/ruNames.txt",  
		(
			(data, index) ->
				geoname = {
					geoname_id		: parseInt(data[1])
					name_ru 		: data[3].toLowerCase!.capitalize!
				}

				if not valid_geo_ids[geoname.geoname_id]
					return null
				
				geoname.name_ru_lower = geoname.name_ru.toLowerCase().replace('-', '_').replace(' ', '_')

				operation = (total, cb) ->	
					database.geonames.update(
						{ geoname_id: geoname.geoname_id, name_ru: null }, 
						{ 
							$push: {
								name_ru_collection 			: geoname.name_ru
								name_ru_lower_collection 	: geoname.name_ru_lower
							}
						},
						(error, result) ->
							bar.update(Math.min(index.toFixed(2)/total, 1))
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
		"/countryCodes-ru.txt",  
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
		"/countryCodes-en.txt",  
		(
			(data, index) ->
				country = {
					code 		: data[0]
					name		: data[4]
					geoname_id 	: parseInt(data[11])
				}

				return null if not country.code

				country.name_lower = country.name.toLowerCase().replace('-', '_').replace(' ', '_')
					
				return operation = (total, cb) -> 
					database.geonames.update(
						{ country_code: country.code }, 
						{ $set: { country_name : country.name, country_name_lower : country.name_lower }},
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

	(err, airports) <- database.airports.find(iata: $ne: [null, '']).toArray()

	complete = 0
	operations = _.map airports, (airport) ->
		operation = (cb) ->
			country 		= airport.country.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')
			city			= airport.city.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')
			airport.iata 	= airport.iata.trim!

			return cb message : 'no airport found', null if not airport.iata
			complete += 1

			database.geonames.update(
				{ country_name_lower: country, name_lower: city },
				{ $set: { iata: airport.iata } },
				(error, result) ->
					bar.update(complete.toFixed(2)/airports.length);
					cb error, result
			)

	console.log "Performing DB operation on #{operations.length} operations."
	async.series operations, callback

addInflectedNames = (callback) ->

	console.log 'Inflecting'
	bar = progressBar.create process.stdout
	done = 0

	q = async.queue (
		(task, cb) -> 
			task cb
		), 4

	q.drain = ->
		callback null, 'done'

	(err, results) <- database.geonames.find(name_ru_collection: $ne : []).toArray!

	callbacks = _.map results, (result) ->
			
		opearation = (cb) ->

			operations = _.map result.name_ru_collection, (name_ru) -> 
				(callback) ->
					command = "python #{__dirname}/python/inflect.py -d #{__dirname}/python/dicts/ -w #{name_ru}"
					(error, stdout, stderr) <- exec command

					if stdout and stdout.toLowerCase!.capitalize!.replace('\n', '')
						name_ru_inflected = stdout.toLowerCase!.capitalize!.replaceAll('\n', '')

					else
						name_ru_inflected = "городе #{result.name_ru}"

					callback null, name_ru_inflected

			(error, name_ru_inflected_collection) <- async.parallel operations

			database.geonames.update( 
				{ geoname_id: result.geoname_id }, 
				{ $set: { 
					name_ru_inflected_collection: name_ru_inflected_collection
					}
				},
				(error, result) -> 
					bar.update done.toFixed(2) / results.length
					done += 1
					cb error, result
			)

		q.push opearation

	
setTimeout( (
	->
		async.series([
			(callback) -> database.geonames.drop(callback), 
			importBaseGeonames, 
			importRuGeonames, 
			importRuCountries, 
			importEnCountries, 
			syncWithAirports,
			addInflectedNames,
			(callback) -> process.exit()
		])
	), 1000
)