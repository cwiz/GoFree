csv       = require("csv")
Mongolian = require("mongolian")

server    = new Mongolian()
db        = server.db("ostroterra")
airports  = db.collection("airports")

objects = []

csv().from.path "airports.csv",
	delimiter: ","
	columns: null

.transform (data) ->
	data.unshift data.pop()
	data

.on "record", (data, index) ->
	airportId = data[1]
	name      = data[2]
	city      = data[3]
	country   = data[4]
	iata      = data[5]
	icao      = data[6]
	lat       = data[7]
	lon       = data[8]
	alt       = data[9]
	timezone  = data[10]
	
	objects.push
		airportId:  airportId
		name:       name
		city:       city
		country:    country
		iata:       iata
		icao:       icao
		lat:        lat
		lon:        lon
		alt:        alt
		timezone:   timezone

.on "end", (count) ->
	console.log ">> Airports drop"
	airports.drop()
	console.log ">> Airports insert"
	airports.insert objects
	console.log ">> END"
	#process.exit()
