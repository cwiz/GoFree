SERP = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @params = @opts.params

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    @render()

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))

    @params.on('fetched', @paramsReady, @)
    @params.fetch(@opts.hash)

    app.log('[app.views.SERP]: initialize')

  updatePageHeight: ->
    @serpPart.css('min-height': app.dom.win.height())

  paramsReady: ->
    @serpPart.html('LOADING SHITS!')

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
