Journey = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @hash = @opts.hash

    @render()
    
    @collection.setHash(@hash).observe()
    @collection.on('fetched', @collectionReady, @)

    app.socket.emit('selected_list_fetch', hash: @hash)

    app.log('[app.views.Journey]: initialize with hash: ' + @hash)

  render: ->
    @$el.html('FETCHING ' + @hash)

  collectionReady: ->
    @$el.html('READY')

  cleanup: ->
    @collection?.off('fetched', @collectionReady, @)

app.views.Journey = Journey
