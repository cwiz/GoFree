providers = require "./providers"

exports.search = !(socket) ->
  socket.on \start_search, !(data) ->

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

      for flightProvider in providers.flightProviders
        let rowNumber = rowNumber, signature = data.signature
          flightResult  <- flightProvider.query origin, destination, extra
          flights <- flightProvider.process flightResult
          socket.emit \flights_ready ,
            flights:   flights
            rowNumber: rowNumber
            signature: signature

      for hotelProvider in providers.hotelProviders
        let rowNumber = rowNumber, signature = data.signature
          if not (rowNumber is (data.rows.length - 1))
            hotelResult <- hotelProvider.query origin, destination, extra
            hotels <- hotelProvider.process hotelResult
            socket.emit \hotels_ready ,
              hotels:     hotels
              rowNumber:  rowNumber
              signature:  signature
         