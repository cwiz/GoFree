async		= require "async"
_			= require "underscore"
database  	= require "./../../app/server/database.ls"

# drop searches and trips
(err, result) 	<- database.normalized_searches.drop!
(err, result) 	<- database.normalized_trips.drop!
(err, searches) <- database.search.find!.toArray!

newSearches	= []
newTrips 	= []

for s in searches

	search_object = 
		hash 	: s.hash
		adults 	: s.adults
		budget 	: s.budget

	newSearches.push search_object

	for t, number in s.trips
		object = 
			hash 		: s.hash
			date 		: t.date
			geoname_id 	: t.place.geoname_id
			number		: number

		newTrips.push object

console.log "Importing #{newSearches.length} searches."
console.log "Importing #{newTrips.length} trips."

_.map newSearches,  (search) -> do ->
	console.log "inserting search #{search.hash}"
	database.normalized_searches.insert search

_.map newTrips,		(trip) 	 -> do ->
	console.log "inserting trip #{trip.hash}"
	database.normalized_trips.insert trip

process.exit!