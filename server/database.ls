Mongolian = require "mongolian"

# Database stuff
server        			= new Mongolian("78.46.187.179")
db            			= server.db "ostroterra"

# Collections
airports 				= db.collection 'airports'
suggest 				= db.collection 'suggest'

# Indices
airports.ensureIndex 	{ iata:  1 }
suggest.ensureIndex 	{ query: 1 }

# Exports
exports.suggest    		= db.collection "suggest"
exports.airports    	= db.collection "airports"