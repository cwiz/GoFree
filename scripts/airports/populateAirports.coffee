String.prototype.trim = ->
	return this.replace(/^\s+|\s+$/g, "")

csv       	= require("csv")
database	= require "./../../app/server/database"

airports 	= database.airports

objects = []

csv().from.path "./scripts/airports/airports.csv",
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
	console.log ">> Airports insert: #{objects.length} objects"
	airports.insert objects

	# ugly hack sick airports.insert does not provide onEnd callback
	setTimeout (
		->
			console.log ">> END"
			process.exit()
		), 5000