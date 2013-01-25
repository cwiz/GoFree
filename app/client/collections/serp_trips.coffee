SERPTrips = Backbone.Collection.extend
  hash: null

  model: app.models.SERPTrip

  initialize: () ->
    @on('add', @instantiateCollections, @)
    app.socket.on('search_started', _.bind(@fetched, @))

    app.log('[app.collections.SERPTrips]: initialize')

  fetched: (resp)->
    return unless resp.form.hash == @hash

    data = resp.trips
    @add(resp.trips)

    @trigger('fetched', data)
    app.log('[app.collections.SERPTrips]: fetched', data)

  instantiateCollections: (model) ->
    unless model.get('hotels')?
      model.set('hotels', new app.collections.SERPTripHotels())

    unless model.get('flights')?
      model.set('flights', new app.collections.SERPTripFlights())

  _dump: (json) ->
    for item in json
      item.hotels = item.hotels.toJSON()
      item.flights = item.flights.toJSON()
 
    item

  jsonify: ->
    @_dump(@toJSON())

app.collections.SERPTrips = SERPTrips
