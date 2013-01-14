chai 		= require 'chai'
io 			= require('socket.io-client')

eviterra 	= require './../app/server/api/providers/eviterra'
ostrovok 	= require './../app/server/api/providers/ostrovok'
#socket 		= require './../app/server/api/socket'

# globals
expect = chai.expect

socketURL = 'http://localhost:1488'
socketOptions =
	transports: ['websocket']
	'force new connection': true


describe 'Ostrovok', ->
	describe '#autocomplete',  ->
		it 'should work with "Москва" input', (done) -> 

			moscowOutput = 
				name: 'Москва'
				oid: 2395
				country: 'Россия'
				displayName: 'Москва'
				provider: 'ostrovok'

			ostrovok.autocomplete "Москва", (err, result) ->
				expect(err).to.be.equal 			null
				expect(result.length).to.be.equal 	3
				expect(result[0]).to.be.deep.equal 	moscowOutput	
				done()

	describe '#search', ->
		it 'should find something in Moscow', (done) ->
			destination =
				place:
					oid: 2395
				date: '2013-02-07'
			origin = 
				date: '2013-02-01'
			extra =
				page: 1
				adults: 2
			
			ostrovok.search origin, destination, extra, (error, hotels) ->
				expect(error).to.be.equal 					null
				expect(hotels.results.length).to.be.above 	0
				done() if hotels.complete
					

describe 'Eviterra', ->
	describe '#autocomplete',  ->
		it 'should work with "Москва" input', (done) -> 
			
			moscowOutput = 
				name: 'Москва'
				iata: 'MOW'
				country: 'Россия'
				displayName: 'Москва'
				provider: 'eviterra' 

			eviterra.autocomplete "Москва", (err, result) ->
				expect(err).to.be.equal null
				expect(result[0]).to.be.deep.equal moscowOutput	
				done()

	describe '#search',  ->
		it 'should find MOW -> LED flights', (done) ->

			destination =
				place:
					iata: 'LED'
			
			origin = 
				place:
					iata: 'MOW'
				date: '2013-02-07'
			
			extra =
				adults: 2
			
			eviterra.search origin, destination, extra, (err, results) ->
				expect(err).to.be.equal null
				done()


describe 'Search API', ->
	describe '#search', ->
		it 'should work without errors', (done) ->
			client = io.connect(socketURL, socketOptions)
			
			data = 
				trips: 
					[
						{
							date: "2013-01-15"
							removable: false
							place: 
								oid: 2395
								iata: "MOW"
								name: "Москва°"
						}
						{
							date: "2013-01-18"
							removable: false
							place: 
								oid: 2114
								iata: "LON"
								name: "Лондон"	
						}
						
					]
				adults: 1
				budget: 100000
				signature: "search_1"
			
			client.emit 'start_search', data

			client.on 'hotels_ready', (hotels) ->
				done() if hotels.progress is 1.0
					
			client.on 'flights_ready', (flights) ->
				done() if flights.progress is 1.0
					