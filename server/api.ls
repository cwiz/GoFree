request     = require "request"
database    = require "./database.js"
async       = require "async"

# providers
ostrovok    = require "./providers/ostrovok.js"
eviterra    = require "./providers/eviterra.js"
travelmenu  = require "./providers/travelmenu-hotels.js"

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

exports.image = (req, res) ->
  query = encodeURIComponent(req.params.query)

  flickrKey     = "7925109a48c26fe53555687f9d46a076"
  flickrSecret  = "c936db59c720b4d5"
  flickrUrl     = "http://api.flickr.com/services/rest/?per_page=10&sort=relevance&format=json&content_type=1&nojsoncallback=1&method=flickr.photos.search&api_key=#{flickrKey}&text=#{query}"
  
  (error, response, body) <- request flickrUrl
  console.log ">>> queried flickr search | #{flickrUrl} | status #{response.statusCode}"
  return if error or not(response.statusCode is 200)
  
  json          = JSON.parse(response.body)
  randomIndex   = Math.floor((Math.random()*json.photos.photo.length));
  photo         = json.photos.photo[randomIndex]
  
  res.json {
    status: 'ok'
    value: 
      image: "http://farm#{photo.farm}.staticflickr.com/#{photo.server}/#{photo.id}_#{photo.secret}_z.jpg"
  }
