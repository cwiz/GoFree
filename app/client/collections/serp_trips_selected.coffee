SERPTripsSelected = Backbone.Collection.extend
  _hash: null
  _observing: false

  model: app.models.SERPTripSelected

  initialize: () ->
    @on('add', @instantiateCollections, @)

    app.log('[app.collections.SERPTripsSelected]: initialize')

  observe: ->
    @_observing = true
    app.socket.on('search_started', _.bind(@fetched, @))

  setHash: (@_hash) -> @

  fetched: (resp)->
    return unless resp.form.hash == @_hash

    data = resp.trips
    @add(resp.trips)

    @trigger('fetched', data)
    app.log('[app.collections.SERPTripsSelected]: fetched', data)

  instantiateCollections: (model) ->
    if @_observing
      model.observe()

  serialize: ->
    @toJSON()

app.collections.SERPTripsSelected = SERPTripsSelected
