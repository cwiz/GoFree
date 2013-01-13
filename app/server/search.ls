providers = require "./providers"

exports.search = (socket) ->
  socket.on \start_search, (data) ->

    departure   = null
    destination = null

    data.rows.push {
      destination: 
        oid:  data.rows[0                 ].origin.oid
        iata: data.rows[0                 ].origin.iata
        date: data.rows[data.rows.length-1].destination.date
      
      origin:
        oid:  data.rows[data.rows.length-1].destination.oid
        iata: data.rows[data.rows.length-1].destination.iata
        date: data.rows[data.rows.length-1].destination.date
    }

    signature      = data.extra.signature
    providersReady = 0
    totalProviders = data.rows.length * providers.flightProviders.length + (data.rows.length - 1) * providers.flightProviders.length
   
    # --- start helper functions ---
    
    flightReady = (error, flights) ->
      providersReady += 1 if flights.complete or error
      percentage      = providersReady.toFixed(2) / totalProviders
      
      if error
        items         = [] 
      else
        items         = flights.results

      console.log "Flight Ready! Percentage: #{percentage}: #{providersReady} / #{totalProviders}| #{flights.complete}"
        
      socket.emit \flights_ready ,
        error     : error
        flights   : items
        progress  : percentage
        rowNumber : rowNumber
        signature : signature

    hotelReady = (error, hotels) ->
      providersReady += 1 if hotels.complete or error
      percentage      = providersReady.toFixed(2) / totalProviders
      
      if error
        items         = [] 
      else
        items         = hotels.results

      console.log "Hotel Ready! Percentage: #{percentage}: #{providersReady} / #{totalProviders} | #{hotels.complete}"

      socket.emit \hotels_ready ,
        error     : error
        hotels    : items
        progress  : percentage
        rowNumber : rowNumber
        signature : signature
    
    # --- end helper functions ---  

    for row, rowNumber in data.rows
      destination = row.destination
      origin      = row.origin
      extra       = {
        adults: data.extra.adults
        page: 1
      }

      for flightProvider in providers.flightProviders
        let rowNumber = rowNumber, signature = data.signature
          flightProvider.search origin, destination, extra, flightReady

      for hotelProvider in providers.hotelProviders
        let rowNumber = rowNumber, signature = data.signature
          if not (rowNumber is (data.rows.length - 1))
            hotelProvider.search origin, destination, extra, hotelReady