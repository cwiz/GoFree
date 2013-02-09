async       = require "async"
database    = require "./../../database"
request     = require "request"
phantom     = require 'phantom'

exports.name = "airbnb"

_page = null

getPage = (cb) ->

    if not _page
        (ph)    <- phantom.create
        (_page)  <- ph.createPage 
        cb _page

    else
        cb _page

process = (results) ->

    output = []

    for r in results
        newResult =
          name      : r.name
          stars     : null
          price     : r.price
          rating    : null
          photo     : r.thumbnail_url.replace('_small', '_large')
          provider  : \airbnb
          id        : r.id

        output.push newResult

    return output

exports.search = (origin, destination, extra, cb, i) ->

    i = 0 if not i

    airUrl = "https://www.airbnb.ru/s/#{destination.place.country_name_ru}--#{destination.place.name_ru}?checkin=#{origin.date}&checkout=#{destination.date}?page=#{extra.page}"

    (page)      <- getPage()    
    (status)    <- page.open airUrl  

    console.log "AIRBNB: queried page | #{airUrl} | status #{status}"

    (result)    <- page.evaluate (-> AirbnbSearch.resultsJson)

    hasResults = result.properties?.length
    console.log "AIRBNB: page: #{extra.page} | # results found: #{hasResults}"
    
    return cb null, {
        results : [],
        complete: true,
    } if not hasResults

    results = process result.properties

    cb null, {
        results : results,
        complete: false,
    }

    extra.page += 1
    i          += 1

    return cb null, {
        results : [],
        complete: true,
    } if i >= 5

    exports.search origin, destination, extra, cb, i