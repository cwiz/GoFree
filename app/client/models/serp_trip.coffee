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

    flights_signature: null
    flights: null

    hotels_signature: null
    hotels: null

  initialize: ->
    app.log('[app.models.SERPTrip]: initialize')

  observe: ->
    if @get('flights_signature')? then app.socket.on('flights_ready', _.bind(@receivedFlights, @))
    if @get('hotels_signature')? then app.socket.on('hotels_ready', _.bind(@receivedHotels, @))

  receivedFlights: (data) ->
    if @get('flights_signature') == data.signature
      @get('flights').add(data.items).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' flights, signed ' + data.signature)

  receivedHotels: (data) ->
    if @get('hotels_signature') == data.signature
      @get('hotels').add(data.items).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' hotels, signed ' + data.signature)

app.models.SERPTrip = SERPTrip
