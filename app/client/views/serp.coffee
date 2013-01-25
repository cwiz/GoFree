SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @params = @opts.params
    @hash = @opts.hash

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    @render()

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))

    @params.on('fetched', @paramsReady, @)
    @collection.on('fetched', @collectionReady, @)

    @params.hash = @hash
    @collection.hash = @hash

    app.socket.emit('search_start', hash: @hash)

    app.log('[app.views.SERP]: initialize')

  updatePageHeight: ->
    @serpPart.css('min-height': app.dom.win.height())

  paramsReady: ->
    @serpPart.html('LOADING SHITS!')
    console.warn('PARAMS!!!', @params)

  paramsReady: ->
    console.warn('COLLEKTEON!!!', @collection)

  showSERP: ->
    height = app.dom.win.height()
    @serpPart.css('min-height': height, display: 'block')

    app.utils.scroll(height, 300, =>
      @render()
      )

  render: ->
    @searchPart.hide()
    @serpPart.show() # who knows might be loading from a link

app.views.SERP = SERP
