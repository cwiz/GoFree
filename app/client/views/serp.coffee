SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (opts) ->
    @render()

    @searchPart   = @$el.find '#part-search'
    @serpPart     = @$el.find '#part-serp'
    @serpHeader   = @serpPart.find '.p-s-header-wrap'
    @tripsContent = @serpPart.find '.p-s-t-content'

    app.on('resize', @updatePageHeight, @)
    app.socket.on('start_search_error', _.bind(@searchError, @))

    @setup(opts)

    # KISSMetrics
    _kmq.push ['record', 'serp view']

    app.log('[app.views.SERP]: initialize')

  events:
    'click .p-s-h-newsearch'      : 'showForm'
    'click .p-s-h-bookselected'   : 'selectedSave'

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
    @selected.on('saved', @selectedSaved, @)

    app.socket.emit('search_start', hash: @hash)

    @show()

    # ============================================
    # REMOVE THIS SHIT
    # ============================================
    if app.env.debug
      window.SERP = @collection
      window.SELECTED = @selected

    app.log('[app.views.SERP]: setup with hash: ' + @hash)

  render: ->
    return if @$el.find('#part-search').length
    @$el.html(app.templates.index())

  show: ->
    @searchPart.hide()
    @serpPart.show()

  showForm: ->
    @searchPart.css('min-height': app.size.height, display: 'block')
    app.utils.scroll(app.size.height, 0)

    app.utils.scroll(0, 300, =>
      @serpPart.hide()
      app.router.navigate('', trigger: true)
      @cleanup()
    )

  updatePageHeight: ->
    @serpPart.css('min-height': app.size.height)

  selectedSave: ->
    @selected.save()

  selectedSaved: ->
    @selectedConfirmed()
      
  selectedConfirmed: ->
    app.router.navigate('/journey/' + @selected._hash, trigger: true)
    @destroy()

  collectionReady: ->
    @serpPart.addClass('loaded')

    @serpHeader.html(app.templates.serp_header())

    @serpTrips = new app.views.SERPTrips(
      el: @tripsContent
      collection: @collection
      hash: @hash
      # search: @search
      )

    @serpTrips.setBudget(@search.get('budget'))

  paramsReady: ->
    @serpTrips.setBudget(@search.get('budget')) if @serpTrips?

  searchError: ->
    @serpPart.addClass('error')

  cleanup: ->
    @tripsContent.html('')
    @serpPart.removeClass('loaded error')

    @search?.off('fetched', @paramsReady, @)
    @collection?.off('fetched', @collectionReady, @)
    @selected?.off('saved', @selectedSaved, @)

    if @serpTrips
      @serpTrips.destroy()
      delete @serpTrips

    delete @hash
    delete @search
    delete @collection
    delete @selected
    delete @opts

    app.log('[app.views.SERP]: cleanup')

  destroy: ->
    @undelegateEvents()
    @cleanup()

    app.log('[app.views.SERP]: destroyed')

app.views.SERP = SERP
