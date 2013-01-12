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
   
    for row, rowNumber in data.rows
      destination = row.destination
      origin      = row.origin

      extra       =
        adults: data.extra.adults
        page: 1

      providersReady = 0
      totalProviders = providers.flightProviders.length + providers.hotelProviders.length

      for flightProvider in providers.flightProviders
        let rowNumber = rowNumber, signature = data.signature
          error, result <- flightProvider.search origin, destination, extra

          if result.complete or error
            providersReady += 1

          if error
            socket.emit \flights_ready ,
              flights   : []
              rowNumber : rowNumber
              signature : signature
              progress  : float(providersReady) / totalProviders
          
          else
            socket.emit \flights_ready ,
              flights   : result.results
              rowNumber : rowNumber
              signature : signature
              progress  : float(providersReady) / totalProviders

      for hotelProvider in providers.hotelProviders
        let rowNumber = rowNumber, signature = data.signature
          if not (rowNumber is (data.rows.length - 1))
            error, result <- hotelProvider.search origin, destination, extra

            if result.complete or error
              providersReady += 1

            if error
              socket.emit \hotels_ready ,
                hotels:     []
                rowNumber:  rowNumber
                signature:  signature
                progress  : float(providersReady) / totalProviders

            else
              socket.emit \hotels_ready ,
                hotels:     result.results
                rowNumber:  rowNumber
                signature:  signature
                progress  : float(providersReady) / totalProviders
         