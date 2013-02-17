Index = Backbone.View.extend
  el: '#l-content'

  initialize: ->
    @preRender()
    @searchPart = @$el.find('#part-search')
    @serpPart = @$el.find('#part-serp')

    @bg = @searchPart.find('.p-i-bg-img')
    @preloader = $('<img/>')

    @collection = @model.get('trips')

    @updatePageHeight()
    @render()

    @searchFormView = new app.views.SearchForm
      el : @searchPart.find('.block-form')[0]
      model : @model
      collection : @collection

    app.on('resize', @updatePageHeight, @)
    @collection.on('change:place', @placeChanged, @)
    @preloader.on('load', _.bind(@updateBG, @))
    @model.on('save', @showSERP, @)

    app.log('[app.views.Index]: initialize')

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
          @preloader.attr('src', resp.value.sharp)

  showSERP: ->
    @serpPart.css('min-height': app.size.height, display: 'block')

    app.utils.scroll(app.size.height, 300, =>
      @searchPart.hide()
      app.router.navigate('search/' + @model.get('hash'), trigger: true)
      )

  preRender: ->
    return if @$el.find('#part-search').length
    @$el.html(app.templates.index())

  render: ->
    @searchPart.hide()
    @serpPart.hide()

    @searchPart.fadeIn(500)

app.views.Index = Index
