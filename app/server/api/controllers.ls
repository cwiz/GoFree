async       = require "async"
database    = require "./../database"
exec		= require("child_process").exec
fs          = require "fs"
request     = require "request"

# providers
ostrovok    = require "./providers/ostrovok"
eviterra    = require "./providers/eviterra"
travelmenu  = require "./providers/travelmenu-hotels"

exports.autocomplete = (req, res) ->
	
	emitResults = (results) ->
		res.send {
			status: "ok"
			value:  results
		}

	query = req.params.query

	if not query
		res.send
			status: "error"
			message: "please supply q GET param"

	(err, results) <- database.suggest.findOne { query: query }
	console.log "searched mongodb for #{query}"
	return emitResults(results.results) if results
	
	providerCallbacks = {
		ostrovok:   (callback) -> ostrovok.autocomplete   query, callback
		eviterra:   (callback) -> eviterra.autocomplete   query, callback
		travelmenu: (callback) -> travelmenu.autocomplete query, callback
	}

	(err, autocompleteResults) <- async.parallel providerCallbacks
	results <- glueAutocompleteResults autocompleteResults
	
	database.suggest.insert {
		query:    query
		results:  results
	}

	emitResults results

glueAutocompleteResults = (results, cb) ->

	ostrovok    = results.ostrovok
	if not ostrovok
		return cb "ostrovok null", null

	eviterra    = results.eviterra
	if not eviterra
		return cb "eviterra null", null

	travelmenu  = results.travelmenu
	if not travelmenu
		return cb "travelmenu null", null

	finalResults = []
	pushResults = (ostrovok, eviterra, travelmenu) ->

		tmId = null
		tmId = travelmenu.tmid if travelmenu

		finalResults.push {
			oid:  ostrovok.oid
			tmid: tmId
			iata: eviterra.iata
			name: eviterra.name
		}

	for o in ostrovok
		for e in eviterra
			if (o.name is e.name) and (o.country is e.country)
				tmRecord = null
				
				for t in travelmenu
						if (o.name is t.name) and (t.country is o.country)
							tmRecord = t
							break
				
				pushResults(o, e, t)

	cb finalResults

queryFlickr = (query, callback) ->

	query = "#{query} view"
	flickrKey     = "7925109a48c26fe53555687f9d46a076"
	flickrSecret  = "c936db59c720b4d5"
	flickrUrl     = "http://api.flickr.com/services/rest/?per_page=5&sort=relevance&format=json&content_type=1&nojsoncallback=1&method=flickr.photos.search&api_key=#{flickrKey}&text=#{query}"
	
	(error, response, body) <- request flickrUrl
	console.log ">>> queried flickr search | #{flickrUrl} | error: #{error} | status #{response?.statusCode}"
	return if error or not(response.statusCode is 200)
	
	json          = JSON.parse(response.body)
	randomIndex   = Math.floor((Math.random()*(json.photos.photo.length-1)))
	photo         = json.photos.photo[randomIndex]

	if photo
		url = "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}.jpg"
		console.log url
		return callback null, url

	return callback {message: 'nothing found'}, null
		

exports.image = (req, res) ->
	query = encodeURIComponent(req.params.query)

	(error, image) <- queryFlickr query
	return res.json({
		status: 'error'
		message: error
	}) if error

	return res.json({
		status: 'ok'
		value:
			image: image
	})

exports.image_v2 = (req, res) ->
	country = encodeURIComponent(req.params.country.replace(/ /g, "_").toLowerCase())
	city 	= encodeURIComponent(req.params.city.replace(/ /g, "_").toLowerCase())

	shutterstockPath 	= "./public/img/cities/custom/#{country}--#{city}-blured.jpg"
	shutterstockBlured	= "/img/cities/custom/#{country}--#{city}-blured.jpg"
	shutterstockSharp	= "/img/cities/custom/#{country}--#{city}-resized.jpg"

	shutterstockExits <- fs.exists shutterstockPath
	return res.json({
		status: 'ok'
		value: 
			blured	: shutterstockBlured
			sharp	: shutterstockSharp
	}) if shutterstockExits


	flickrPath 			= "./public/img/cities/flickr/#{country}--#{city}-blured.jpg"
	flickrBlured		= "/img/cities/flickr/#{country}--#{city}-blured.jpg"
	flickrSharp			= "/img/cities/flickr/#{country}--#{city}-resized.jpg"

	flickrExits <- fs.exists flickrPath
	return res.json({
		status: 'ok'
		value: 
			blured	: flickrBlured
			sharp	: flickrBlured
	}) if flickrExits


	(error, image) <- queryFlickr city
	return res.json({
		status: 'error'
		message: error
	}) if error

	origFile 			= "./public/img/cities/flickr/#{country}--#{city}-orig.jpg"
	resizedFile 		= "./public/img/cities/flickr/#{country}--#{city}-resized.jpg"
	bluredFile 			= "./public/img/cities/flickr/#{country}--#{city}-blured.jpg"

	(error, result) <- exec "wget #{image} -O #{resizedFile}"
	if error
		exec "rm #{origFile}"
		return res.json({
			status: 'error'
			message: error
		})

	(error, stat) <- fs.stat resizedFile
	return res.json({
		status: 'error'
		message: error
	}) if stat.size is 9218 # flickr bullshit

	(error, result) <- exec "convert #{resizedFile} -blur 0x3 -quality 0.6 #{bluredFile}"
	return res.json({
		status: 'ok'
		value:
			blured	: flickrBlured
			sharp	: flickrBlured
	})

