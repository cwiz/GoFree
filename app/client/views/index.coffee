Index = Backbone.View.extend
  el: '#page-index'

  initialize: () ->
    @bg = @$el.find('.p-i-bg-img')
    @preloader = $('<img/>')

    @collection = @model.get('trips')

    @updatePageHeight()

    @render()
    
    @searchFormView = new app.views.SearchForm
      el : @$el.find('.block-form')[0]
      model : @model
      collection : @collection

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))
    @collection.on('change:place', @placeChanged, @)
    @preloader.on('load', _.bind(@updateBG, @))

    app.log('[app.views.Index]: initialize')

  updatePageHeight: () ->
    @$el.css(height: app.dom.win.height())

  updateBG: (e)->
    @bg.fadeOut(200, () =>
      @bg.attr('src', e.target.src)
      @bg.fadeIn(200)
      )

  placeChanged: (model, place) ->
    $.ajax
      url:  app.api.images + place.name
      success: (resp) =>
        @preloader.attr('src', resp.value.image)

  render: () ->
    @$el.hide()
    @$el.fadeIn(500)

app.views.Index = Index
