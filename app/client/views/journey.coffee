Journey = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @render()

    @hash = @opts.hash
    @collection.setHash(@hash).observe()
    @collection.on('fetched', @collectionReady, @)

    app.socket.emit('selected_list_fetch', hash: @hash)

    app.log('[app.views.Journey]: initialize')

  events:
    'click .p-s-h-newsearch'      : 'showForm'
    'click .p-s-h-bookselected'   : 'selectedSave'

  render: ->
    @$el.html('FETCHING ' + @hash)

  collectionReady: ->
    @$el.html('READY')

  cleanup: ->
    @collection?.off('fetched', @collectionReady, @)

app.views.Journey = Journey
