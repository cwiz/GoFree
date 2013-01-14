chai 		= require 'chai'
io 			= require('socket.io-client')

chai.should() 
expect = chai.expect

ostrovok 	= require './../app/server/providers/ostrovok'

describe 'Ostrovok', ->

	describe '#autocomplete',  ->
		it 'should work with "Москва" input', (done) -> 
			ostrovok.autocomplete "Москва", (err, result) ->
				expect(err).to.be.equal null
				
				result.length.should.equal 3
				
				expect(result[0]).to.be.deep.equal	
					name: 'Москва', 
					oid: 2395,
					country: 'Россия',
					displayName: 'Москва',
					provider: 'ostrovok' 
				
				done()

	describe '#search', ->
		it 'should find something in Moscow', (done) ->
			
			destination =
				oid: 2395
				date: '2013-02-07'
			
			origin = 
				date: '2013-02-01'
			
			extra =
				page: 1
				adults: 2
			
			ostrovok.search origin, destination, extra, (error, hotels) ->
				expect(error).to.be.equal null

				expect(hotels.results.length).to.be.above 0

				if hotels.complete
					done()

eviterra 	= require './../app/server/providers/eviterra' 

describe 'Eviterra', ->
	describe '#autocomplete',  ->
		it 'should work with "Москва" input', (done) -> 
			eviterra.autocomplete "Москва", (err, result) ->
				expect(err).to.be.equal null
				
				expect(result[0]).to.be.deep.equal	
					name: 'Москва', 
					iata: 'MOW',
					country: 'Россия',
					displayName: 'Москва',
					provider: 'eviterra' 
				
				done()

	describe '#search',  ->
		it 'should find MOW -> LED flights', (done) ->

			destination =
				iata: 'LED'
			
			origin = 
				iata: 'MOW'
				date: '2013-02-07'
			
			extra =
				adults: 2
			
			eviterra.search origin, destination, extra, (err, results) ->
				expect(err).to.be.equal null
				done()

search 		= require './../app/server/search'

socketURL = 'http://localhost:1488'
socketOptions =
	transports: ['websocket']
	'force new connection': true

describe 'Search API', ->
	describe '#search', ->
		it 'should work without errors', (done) ->
			client = io.connect(socketURL, socketOptions)
			
			data = 
				rows: [
					destination:
						oid: 2395
						date: '2013-02-07'
						iata: 'LED'
					
					origin: 
						iata: 'MOW'
						date: '2013-02-01'
						oid: 2395
					]
				extra:
					page: 1
					adults: 2

			client.emit 'start_search', data

			client.on 'hotels_ready', (hotels) ->
				console.log
				if hotels.progress is 1.0
					done()

			client.on 'flights_ready', (flights) ->
				if flights.progress is 1.0
					done()
