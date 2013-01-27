SERP = Backbone.View.extend
  el: '#l-content'
  progress: 0

  initialize: (@opts) ->
    @search = @opts.search
    @hash = @opts.hash

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    @serpHeader = @serpPart.find('.p-s-header-wrap')

    @serpTrips = null

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))

    @search.setHash(@hash).observe()
    @collection.setHash(@hash).observe()

    @search.on('fetched', @paramsReady, @)
    @collection.on('fetched', @collectionReady, @)

    app.socket.on('progress', _.bind(@progress, @))

    app.socket.emit('search_start', hash: @hash)

    @render()

    # ============================================
    # REMOVE THIS SHIT
    # ============================================
    if app.env.debug
      window.SERP = @collection

    app.log('[app.views.SERP]: initialize')

  events:
    'click .p-s-h-changetripparams'      : 'changeSearchParams'

  updatePageHeight: ->
    @serpPart.css('min-height': app.dom.win.height())

  changeSearchParams: ->
    app.router.navigate('', trigger: true)

  progress: (data) ->
    return unless data.hash == @hash
    @progress = data.progress
    app.log('[app.views.SERP]: progress ' + Math.floor(@progress * 100) + '%')

  paramsReady: ->
    @serpHeader.html(app.templates.serp_header(@search.serialize()))

  collectionReady: ->
    @serpTrips = new app.views.SERPTrips(
      el: '.p-s-trips-wrap'
      collection: @collection
      )

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
