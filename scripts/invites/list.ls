guid		= require "node-guid"
database  	= require "./../../app/server/database.ls"

(err, results) <- database.invites.find(used:false).toArray!

for r in results
	console.log r.guid

setTimeout (-> process.exit!), 1000