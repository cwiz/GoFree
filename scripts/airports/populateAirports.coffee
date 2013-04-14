String.prototype.trim = ->
	return this.replace(/^\s+|\s+$/g, "")

csv       = require("csv")
Mongolian = require("mongolian")

server    = new Mongolian()
db        = server.db("ostroterra")
airports  = db.collection("airports")

objects = []

csv().from.path "scripts/airports/airports.csv",
	delimiter: ","
	columns: null

.transform (data) ->
	data.unshift data.pop()
	data

.on "record", (data, index) ->
	airportId = data[1].trim()
	name      = data[2].trim()
	city      = data[3].trim()
	country   = data[4].trim()
	iata      = data[5].trim()
	icao      = data[6].trim()
	lat       = data[7].trim()
	lon       = data[8].trim()
	alt       = data[9].trim()
	timezone  = data[10].trim()

	if iata
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
	process.exit()