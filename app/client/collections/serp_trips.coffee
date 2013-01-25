SERPTrips = Backbone.Collection.extend
  _hash: null

  model: app.models.SERPTrip
  comparator: 'price'

  initialize: () ->
    @on('add', @instantiateCollections, @)

    app.log('[app.collections.SERPTrips]: initialize')

  observe: ->
    app.socket.on('search_started', _.bind(@fetched, @))

  setHash: (@_hash) -> @

  fetched: (resp)->
    return unless resp.form.hash == @_hash

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
 
    json

  serialize: ->
    @_dump(@toJSON())

app.collections.SERPTrips = SERPTrips
