Mongolian = require "mongolian"

# Database stuff
server        			= new Mongolian()
db            			= server.db "ostroterra"


# Collections
exports.airports 		= db.collection 'airports'
exports.suggest 		= db.collection 'suggest'
exports.search 			= db.collection 'search'

# Indices
exports.airports.ensureIndex 	{ iata		: 1 }
exports.suggest.ensureIndex 	{ query		: 1 }
exports.search.ensureIndex 		{ hash		: 1 }
