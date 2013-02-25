Index = Backbone.View.extend
  el: '#l-content'

  initialize: ->
    @render()

    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    @searchForm = @searchPart.find('.p-s-formwrap')

    @bg = @searchPart.find('.p-s-bg-img')
    @preloader = $('<img/>')

    @collection = @model.get('trips')

    @updatePageHeight()

    @searchFormView = new app.views.SearchForm(
      el: @searchForm
      model: @model
      collection: @collection
    )

    @show()

    app.on('resize', @updatePageHeight, @)
    @collection.on('change:place', @placeChanged, @)
    @preloader.on('load', _.bind(@updateBG, @))
    @model.on('save', @showSERP, @)

    app.log('[app.views.Index]: initialize')

  showSERP: (data)->
    @serpPart.css('min-height': app.size.height, display: 'block')

    app.utils.scroll(app.size.height, 300, =>
      @searchPart.hide()
      app.router.navigate('search/' + data.hash, trigger: true)
      )

  render: ->
    return if @$el.find('#part-search').length
    @$el.html(app.templates.index())

  show: ->
    @searchForm.hide()
    @serpPart.hide()

    @searchForm.fadeIn(500)

  updatePageHeight: ->
    @searchPart.css('min-height': app.size.height)

  updateBG: (e)->
    @bg.fadeOut(200, =>
      @bg.attr('src', e.target.src)
      @bg.fadeIn(200)
      )

  placeChanged: (model, place) ->
    $.ajax
      url:  "#{app.api.images}#{place.country_code}/#{place.name}"
      success: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.blured)

  destroy: ->
    @undelegateEvents()

    if @searchFormView
      @searchFormView.destroy()
      delete @searchFormView

    app.off('resize', @updatePageHeight, @)
    @collection.off('change:place', @placeChanged, @)
    @preloader.off('load', _.bind(@updateBG, @))
    @model.off('save', @showSERP, @)

    delete @collection
    delete @preloader
    delete @model

    app.log('[app.views.Index]: destroy')

app.views.Index = Index
