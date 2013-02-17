SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (opts) ->
    @preRender()

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')
    @serpHeader = @serpPart.find('.p-s-header-wrap')
    @tripsContent = @serpPart.find('.p-s-t-content')

    app.on('resize', @updatePageHeight, @)
    app.socket.on('start_search_error', _.bind(@searchError, @))

    @setup(opts)

    app.log('[app.views.SERP]: initialize')

  events:
    'click .p-s-h-newsearch'      : 'showForm'
    'click .p-s-h-bookselected'   : 'showBookingOverlay'

  setup: (@opts)->
    @hash = @opts.hash
    @search = @opts.search
    @collection = @opts.collection
    @selected = @opts.selected

    @serpTrips = null

    @search.setHash(@hash).observe()
    @collection.setHash(@hash).observe()
    @selected.setHash(@hash).observe()

    @search.on('fetched', @paramsReady, @)
    @collection.on('fetched', @collectionReady, @)
    @selected.on('save', @bookingReady, @)

    if not app.user
      @prebookingOverlay = new app.views.PrebookingOverlay(
        @model = @selected
        )
      # @prebookingOverlay.show()

    app.socket.emit('search_start', hash: @hash)

    @render()

    # ============================================
    # REMOVE THIS SHIT
    # ============================================
    if app.env.debug
      window.SERP = @collection
      window.SELECTED = @selected

    app.log('[app.views.SERP]: setup with hash: ' + @hash)

  updatePageHeight: ->
    @serpPart.css('min-height': app.size.height)

  showForm: ->
    @searchPart.css('min-height': app.size.height, display: 'block')
    app.utils.scroll(app.size.height, 0)

    app.utils.scroll(0, 300, =>
      @serpPart.hide()
      app.router.navigate('', trigger: true)
      @destroy()
      )

  showBookingOverlay: ->
    if not app.user
      @prebookingOverlay.show()
    else
      @selected.save()

  bookingReady: (data)->
    app.router.navigate('/trip/' + data.hash, trigger: true)

  paramsReady: ->
    @serpHeader.html(app.templates.serp_header(@search.serialize()))
    @serpTrips.setBudget(@search.get('budget')) if @serpTrips?

  collectionReady: ->
    @serpPart.addClass('loaded')
    @serpTrips = new app.views.SERPTrips(
      el: @tripsContent
      collection: @collection
      hash: @hash
      )

    @serpTrips.setBudget(@search.get('budget'))

  searchError: ->
    @serpPart.addClass('error')

  # showSERP: ->
  #   height = app.dom.win.height()
  #   @serpPart.css('min-height': height, display: 'block')

  #   app.utils.scroll(height, 300, =>
  #     @render()
  #     )

  preRender: ->
    return if @$el.find('#part-search').length
    @$el.html(app.templates.index())

  render: ->
    @searchPart.hide()
    @serpPart.show() # who knows might be loading from a link

  destroy: ->
    @tripsContent.html('')
    @serpPart.removeClass('loaded error')

    @search.off('fetched')
    @collection.off('fetched')

    if @serpTrips
      @serpTrips.destroy()
      delete @serpTrips

    delete @hash
    delete @search
    delete @collection
    delete @selected
    delete @opts

    if not app.user
      @prebookingOverlay.destroy()
      delete @prebookingOverlay

app.views.SERP = SERP
