SERPTrip = Backbone.Model.extend
  defaults:
    origin:
      date: null
      place:
        name: null

    destination:
      date: null
      place:
        name: null

    hotels_signature: null
    hotels: null

    flights_signature: null
    flights: null

  initialize: ->
    @listen()
    app.log('[app.models.SERPTrip]: initialize')

  listen: ->
    if @get('hotels_signature')? then app.socket.on('hotels_ready', _.bind(@receivedHotels, @))
    if @get('flights_signature')? then app.socket.on('flights_ready', _.bind(@receivedFlights, @))

  receivedHotels: (data) ->
    if @get('hotels_signature') == data.signature
      @get('hotels').add(data.items)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' hotels')

  receivedFlights: (data) ->
    if @get('flights_signature') == data.signature
      @get('flights').add(data.items)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' flights')


app.models.SERPTrip = SERPTrip
