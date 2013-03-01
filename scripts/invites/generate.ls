guid		= require "node-guid"
database  	= require "./../../app/server/database.ls"

for i in [0 til 100]
	invite = 
		guid: guid.new!
		used: false

	database.invites.insert invite

setTimeout (-> process.exit!), 1000