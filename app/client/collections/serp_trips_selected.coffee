SERPTripsSelected = Backbone.Collection.extend
  _searchHash: null
  _observing: false
  _hash: null

  model: app.models.SERPTripSelected

  initialize: () ->
    @on('add', @instantiateCollections, @)

    app.socket.on('serp_selected_ok', _.bind(@saved, @))

    app.log('[app.collections.SERPTripsSelected]: initialize')

  observe: ->
    @_observing = true
    app.socket.on('search_started', _.bind(@fetched, @))

  setHash: (@_searchHash) -> @

  fetched: (resp)->
    return unless resp.form.hash == @_searchHash

    data = resp.trips
    @add(resp.trips)

    @trigger('fetched', data)
    app.log('[app.collections.SERPTripsSelected]: fetched', data)

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

  save: ->
    data = @serialize()
    @_hash = md5(JSON.stringify(data))

    app.socket.emit('serp_selected',
      trip_hash   : @_hash
      search_hash : @_searchHash
      items       : data
    )

    @trigger('save', data)

    app.log('[app.models.SERPTripSelected]: save', data)
    @_hash

  saved: ->
    @trigger('saved', @_hash)

  destroy: ->
    @_searchHash = null
    @_observing = false
    @_hash = null

    @off('add', @instantiateCollections, @)

    app.socket.removeAllListeners('serp_selected_ok')
    app.socket.removeAllListeners('search_started')

    @reset()

    app.log('[app.collections.SERPTripsSelected]: destroy')

app.collections.SERPTripsSelected = SERPTripsSelected
