SERPTrips = Backbone.Collection.extend
  _hash: null
  _observing: false

  model: app.models.SERPTrip

  initialize: () ->
    @on('add', @instantiateCollections, @)

    app.log('[app.collections.SERPTrips]: initialize')

  observe: ->
    @_observing = true
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
      model.set('hotels_filtered', new app.collections.SERPTripHotels())

    unless model.get('flights')?
      model.set('flights', new app.collections.SERPTripFlights())
      model.set('flights_filtered', new app.collections.SERPTripFlights())

    if @_observing
      model.observe()

  _dump: (json) ->
    for item in json
      item.hotels   = item.hotels.toJSON()
      item.flights  = item.flights.toJSON()

      delete item.hotels_filtered
      delete item.flights_filtered
 
    json

  serialize: ->
    @_dump(@toJSON())

  destroy: ->
    @_hash = null
    @_observing = false
    @off('add', @instantiateCollections, @)
    app.socket.removeAllListeners('search_started')

    @each((model, index, list) =>
      model.destroy()
      )

    @reset()

    app.log('[app.collections.SERPTrips]: destroyed')

app.collections.SERPTrips = SERPTrips
