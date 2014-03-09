Mongolian = require "mongolian"

# Database stuff
# db = new mongodb.Db "ostroterra", new mongodb.Server!, w:1
server = new Mongolian()
db = server.db "ostroterra"

# Airports
exports.airports 		= db.collection 'airports'
exports.airports.ensureIndex 	{ iata			: 1 }, 	{ unique: true }

# Suggest
exports.suggest 		= db.collection 'suggest'
exports.suggest.ensureIndex 	{ query			: 1 }, 	{ unique: true }

# Search
exports.search 			= db.collection 'search'
exports.search.ensureIndex 		{ hash			: 1 }, 	{ unique: true }

# Geonames
exports.geonames		= db.collection 'geonames'
exports.geonames.ensureIndex 	{ geoname_id	: 1 }, 	{ unique: true }
exports.geonames.ensureIndex 	{ name_ru_lower	: 1 }
exports.geonames.ensureIndex 	{ name_ru 		: 1 }

# Airlines
exports.airlines		= db.collection 'airlines'
exports.airlines.ensureIndex 	{ iata			: 1 }, 	{ unique: true }

# Hotels
exports.hotels			= db.collection 'hotels'
exports.hotels.ensureIndex {id : 1, provider : 1}, 		{ unique: true }

# Countries
exports.countries		= db.collection 'countries'
exports.countries.ensureIndex 	{ geoname_id 	: 1 }, 	{ unique: true }
exports.countries.ensureIndex 	{ code			: 1 }, 	{ unique: true }

# Users
exports.users 			= db.collection 'users'
exports.countries.ensureIndex 	{ id 			: 1 }, 	{ unique: true }

# Selected params
exports.trips 			= db.collection 'trips'
exports.trips.ensureIndex 		{ trip_hash 	: 1 }, 	{ unique: true }
exports.trips.ensureIndex 		{ search_hash 	: 1 }

# Conversions
exports.conversions		= db.collection 'conversions'

# Links
exports.links 			= db.collection 'links'
exports.links.ensureIndex 		{ hash			: 1 }, 	{ unique: true }

# Normalized -- Searches
exports.normalized_searches = db.collection 'normalized_searches'

# Normalized -- Trips
exports.normalized_trips	= db.collection 'normalized_trips'