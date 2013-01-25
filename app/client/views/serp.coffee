SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @search = @opts.search
    @hash = @opts.hash

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))

    @search.setHash(@hash)
    @collection.setHash(@hash)

    @search.on('fetched', @paramsReady, @)
    @collection.on('fetched', @collectionReady, @)

    # ============================================
    # REMOVE THIS SHIT
    # ============================================
    window.SERP = @collection

    app.socket.emit('search_start', hash: @hash)

    @render()

    app.log('[app.views.SERP]: initialize')

  updatePageHeight: ->
    @serpPart.css('min-height': app.dom.win.height())

  paramsReady: ->
    @serpPart.html('LOADING SHITS!')

  collectionReady: ->
    @serpPart.html('LOADING SHITS!!!')

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
