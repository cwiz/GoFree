Mongolian = require "mongolian"

# Database stuff
server        			= new Mongolian
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