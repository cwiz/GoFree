assert 		= require 'assert'
chai 		= require 'chai'
eviterra 	= require './../app/server/api/providers/eviterra'
io 			= require 'socket.io-client'
ostrovok 	= require './../app/server/api/providers/ostrovok'
md5			= require 'MD5'
moment		= require 'moment'

# globals
expect = chai.expect

socketURL = 'http://localhost:3000'
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
							date: "2013-02-1"
							removable: false
							place: 
								oid: 2395
								iata: "MOW"
								name: "Москва°"
							signature:  md5(moment().format('MMMM Do YYYY, h:mm:ss a'))
						}
						{
							date: "2013-02-10"
							removable: false
							place: 
								oid: 2114
								iata: "LON"
								name: "Лондон"
							signature: md5(moment().format('MMMM Do YYYY, h:mm:ss a'))
						}
					]
				adults: 1
				budget: 100000
				hash:  md5(moment().format('MMMM Do YYYY, h:mm:ss a'))

			hash = data.hash
			
			client.emit 'search', data

			client.on 'search_error', (data) ->
				assert false

			client.on 'search_ok', (data) ->
				client.emit 'search_start', { hash : hash }

				client.on 'progress', (data) ->
					done() if data.progress is 1.0
					