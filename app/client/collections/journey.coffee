Journey = Backbone.Collection.extend
  _observing: false
  _hash: null
  _searchHash: null

  model: app.models.SERPTripSelected

  initialize: () ->
    app.log('[app.collections.Journey]: initialize')

  observe: ->
    @_observing = true
    app.socket.on('selected_list_fetch_ok', _.bind(@fetched, @))
    app.socket.on('selected_list_fetch_error', _.bind(@error, @))

  setHash: (@_hash) -> @

  fetched: (resp)->
    return unless resp.trip_hash == @_hash

    data = resp.items
    @add(data)
    @_searchHash = resp.search_hash

    @trigger('fetched', data)
    app.log('[app.collections.Journey]: fetched', data)

  error: ->
    @trigger('error')
    app.log('[app.collections.Journey]: failed to fetch')

  serialize: ->
    @toJSON()

  destroy: ->
    @_observing = false
    @_hash = null
    @_searchHash = null
    app.socket.removeAllListeners('selected_list_fetch_ok')
    app.socket.removeAllListeners('selected_list_fetch_error')

    @each((model, index, list) =>
      model.destroy()
      )

    @reset()
    app.log('[app.collections.Journey]: destroyed')

app.collections.Journey = Journey
