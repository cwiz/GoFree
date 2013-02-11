SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (opts) ->
    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')
    @serpHeader = @serpPart.find('.p-s-header-wrap')
    @tripsContent = @serpPart.find('.p-s-t-content')

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))
    # app.socket.on('progress', _.bind(@progress, @))
    app.socket.on('start_search_error', _.bind(@searchError, @))

    @setup(opts)

    app.log('[app.views.SERP]: initialize')

  events:
    'click .p-s-h-changetripparams'      : 'changeSearchParams'

  setup: (@opts)->
    @collection = @opts.collection
    @search = @opts.search
    @selected = @opts.selected
    @hash = @opts.hash

    @progress = 0
    @serpTrips = null

    @search.setHash(@hash).observe()
    @collection.setHash(@hash).observe()
    @selected.setHash(@hash).observe()

    @search.on('fetched', @paramsReady, @)
    @collection.on('fetched', @collectionReady, @)

    @tripsContent.html('')
    @serpPart.removeClass('loaded error')

    app.socket.emit('search_start', hash: @hash)

    @render()

    # ============================================
    # REMOVE THIS SHIT
    # ============================================
    if app.env.debug
      window.SERP = @collection
      window.SELECTED = @selected

  updatePageHeight: ->
    @serpPart.css('min-height': app.dom.win.height())

  changeSearchParams: ->
    app.router.navigate('', trigger: true)

  # progress: (data) ->
  #   return unless data.hash == @hash
  #   @progress = data.progress
  #   app.log('[app.views.SERP]: progress ' + Math.floor(@progress * 100) + '%')

  paramsReady: ->
    @serpHeader.html(app.templates.serp_header(@search.serialize()))

  collectionReady: ->
    @serpPart.addClass('loaded')
    @serpTrips = new app.views.SERPTrips(
      el: @tripsContent
      collection: @collection
      )

  searchError: ->
    @serpPart.addClass('error')

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
