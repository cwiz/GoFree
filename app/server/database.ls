Mongolian = require "mongolian"

# Database stuff
server        			= new Mongolian()
db            			= server.db "ostroterra"


# Collections
exports.airports 		= db.collection 'airports'
exports.suggest 		= db.collection 'suggest'

# Indices
exports.airports.ensureIndex 	{ iata:  1 }
exports.suggest.ensureIndex 	{ query: 1 }
