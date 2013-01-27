Mongolian = require "mongolian"

# Database stuff
server        			= new Mongolian()
db            			= server.db "ostroterra"

# Airports
exports.airports 		= db.collection 'airports'
exports.airports.ensureIndex 	{ iata		: 1 }, { unique: true }

# Suggest
exports.suggest 		= db.collection 'suggest'
exports.suggest.ensureIndex 	{ query		: 1 }, { unique: true }

# Search
exports.search 			= db.collection 'search'
exports.search.ensureIndex 		{ hash		: 1 }, { unique: true }

# Geonames
exports.geonames		= db.collection 'geonames'
exports.geonames.ensureIndex 	{ geoname_id: 1 }, { unique: true }
exports.geonames.ensureIndex 	{ name_ru_lower: 1 }
exports.geonames.ensureIndex 	{ name_ru: 1 }

# Countries
exports.countries		= db.collection 'countries'
exports.countries.ensureIndex 	{ geoname_id: 1 }, 	{ unique: true }
exports.countries.ensureIndex 	{ code: 1 }, 		{ unique: true }
