assert 		= require 'assert'
chai 		= require 'chai'
io 			= require 'socket.io-client'
md5			= require 'MD5'
moment		= require 'moment'

# providers
airbnb 		= require './../app/server/api/providers/airbnb'
aviasales 	= require './../app/server/api/providers/aviasales'
eviterra 	= require './../app/server/api/providers/eviterra'
flatora 	= require './../app/server/api/providers/flatora'
ostrovok 	= require './../app/server/api/providers/ostrovok'

# globals
expect = chai.expect

generateTrips = () ->
	data = 
		trips: 
			[
				{
					date: moment().add('days', 7).format("YYYY-MM-DD")
					removable: false
					place: 
						iata			: "MOW"
						name_ru			: "Москва"
						country_name_ru	: "Россия"
					signature:  md5(moment().format('MMMM Do YYYY, h:mm:ss a'))
				}
				{
					date: moment().add('days', 14).format("YYYY-MM-DD")
					removable: false
					place: 
						iata			: "LON"
						name_ru			: "Лондон"
						country_name_ru	: "Великобритания"
					signature: md5(moment().format('MMMM Do YYYY, h:mm:ss a'))
				}
			]
		adults: 1
		budget: 100000
		hash:  md5(moment().format('MMMM Do YYYY, h:mm:ss a'))

	return data

generateData = () ->
	data 		= generateTrips()
	origin 		= data.trips[0]
	destination = data.trips[1]
	extra =
		adults: data.adults
		page: 1

	return {
		origin		: origin
		destination : destination
		extra		: extra
	}

describe 'Flatora', ->

	describe '#search', ->
		it 'should find something in Moscow', (done) ->
			
			data = generateData()
			
			flatora.search data.origin, data.destination, data.extra, (error, hotels) ->
				expect(error).to.be.equal 					null
				expect(hotels.results.length).to.be.above 	0
				done() if hotels.complete

# describe 'Aviasales', ->

# 	describe '#search',  ->
# 		it 'should find MOW -> LON flights', (done) ->

# 			data = generateData()

# 			aviasales.search data.origin, data.destination, data.extra, (err, flights) ->
# 				expect(err).to.be.equal null
# 				expect(flights.results.length).to.be.above 	0
# 				done()

# describe 'AirBnb', ->

# 	describe '#search', ->
# 		it 'should find something in Moscow', (done) ->

# 			data = generateData()
			
# 			airbnb.search data.origin, data.destination, data.extra, (error, hotels) ->
# 				expect(error).to.be.equal 					null
# 				expect(hotels.results.length).to.be.above 	0
# 				done() 


# describe 'Ostrovok', ->

# 	describe '#search', ->
# 		it 'should find something in Moscow', (done) ->
			
# 			data = generateData()
			
# 			ostrovok.search data.origin, data.destination, data.extra, (error, hotels) ->
# 				expect(error).to.be.equal 					null
# 				expect(hotels.results.length).to.be.above 	0
# 				done() if hotels.complete
					

# describe 'Eviterra', ->

# 	describe '#search',  ->
# 		it 'should find MOW -> LED flights', (done) ->

# 			data = generateData()
			
# 			eviterra.search data.origin, data.destination, data.extra, (err, results) ->
# 				expect(err).to.be.equal null
# 				done()

# socketURL = 'http://localhost:3000'
# socketOptions =
# 	transports: ['websocket']
# 	'force new connection': true


# describe 'Search API', ->
# 	describe '#search', ->

# 		client = io.connect(socketURL, socketOptions)
		
# 		it 'should work without errors', (done) ->	
# 			data = generateData()
# 			hash = data.hash
			
# 			client.emit 'search', data
				
# 			client.emit 'search_start', { hash : hash }

# 			finished = false

# 			client.on 'progress', (data) ->
# 				if data.progress is 1.0 and not finished
# 					done() 
# 					finished = true

# 		it 'should fail validation error', (done) ->	
# 			data = generateData()
# 			hash = data.hash

# 			delete data.hash
			
# 			client.emit 'search', data
				
# 			client.on 'search_error', (data) ->
# 				done()

# 		it 'should fail with dates in the past', (done) ->	
# 			data = generateData()
# 			hash = data.hash

# 			data.trips[0].date = moment().add('days', -14).format("YYYY-MM-DD")
# 			data.trips[1].date = moment().add('days', -7).format("YYYY-MM-DD")
			
# 			client.emit 'search', data
				
# 			client.emit 'search_start', { hash : hash }

# 			client.on 'progress', (data) ->
# 				done() if data.progress is 1.0
