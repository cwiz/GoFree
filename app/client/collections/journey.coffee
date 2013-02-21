Journey = Backbone.Collection.extend
  _observing: false
  _hash: null

  model: app.models.SERPTripSelected

  initialize: () ->
    @on('add', @instantiateCollections, @)

    app.log('[app.collections.Journey]: initialize')

  observe: ->
    @_observing = true
    app.socket.on('selected_list', _.bind(@fetched, @))

  setHash: (@_hash) -> @

  fetched: (resp)->
    return unless resp.hash == @_hash

    data = resp.list
    @add(data)

    @trigger('fetched', data)
    app.log('[app.collections.SERPTrips]: fetched', data)

  instantiateCollections: (model) ->
    if @_observing
      model.observe()

  _dump: (json) ->
    for item in json
      item.hotel = item.hotel?.toJSON()
      item.flight = item.flight?.toJSON()
 
    json

  serialize: ->
    @_dump(@toJSON())

app.collections.Journey = Journey
