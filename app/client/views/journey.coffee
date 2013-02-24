Journey = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @hash = @opts.hash

    @render()

    @wrapEl = @$el.find('.p-journey')
    
    @collection.setHash(@hash).observe()
    @collection.on('fetched', @collectionReady, @)
    @collection.on('error', @collectionFailed, @)

    app.socket.emit('selected_list_fetch', trip_hash: @hash)

    app.log('[app.views.Journey]: initialize with hash: ' + @hash)

  events:
    'click .p-j-h-newsearch':        'newSearch'
    'click .p-j-h-backtoserp':       'repeatSearch'

  render: ->
    @$el.html(app.templates.journey())

  collectionReady: ->
    @wrapEl.addClass('loaded')
    @wrapEl.find('.p-j-content').html(app.templates.selected_list(selected: @collection.serialize()))

  collectionFailed: ->
    @wrapEl.addClass('failed')

  newSearch: ->
    @destroy()
    app.router.navigate('', trigger: true)

  repeatSearch: ->
    hash = @collection._searchHash

    @destroy()
    app.router.navigate('search/' + hash, trigger: true)

  destroy: ->
    @collection?.off('fetched', @collectionReady, @)
    @collection?.off('error', @collectionFailed, @)

app.views.Journey = Journey
