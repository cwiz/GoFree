
_				= require "underscore"
async			= require "async"
database  		= require "./../../app/server/database.ls"
child_process   = require "child_process"
exec            = child_process.exec

(error, airlines) <- database.airlines.find().toArray()

operations = _.map airlines, (ai) ->

	operation = (callback) ->
		command = "wget https://eviterra.com/images/carriers/#{ai.iata}.png -O icons/#{ai.iata}.png"
		console.log command
		(err, result) <- exec command
		callback null, {}

console.log operations

async.series operations
