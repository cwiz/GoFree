_ 			= require "underscore"
async		= require "async"
csv       	= require "csv"
database  	= require "./../../app/server/database.ls"
progressBar = require "progress-bar"


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

syncAirlines = (callback)->
	importFile(
		"/airlines.csv",
		(
			(data, index) ->
				object = {
					iata 	: data[0]
					name 	: data[2]
				}

				return object
		),
		(
			(operations) ->
				database.airlines.insert operations
				console.log 'Done!'
				callback null, operations.length
		)
	)

setTimeout( (
	->
		async.series([
			(callback) -> database.airlines.drop(callback), 
			syncAirlines,
			(callback) -> process.exit()
		])
	), 1000
)