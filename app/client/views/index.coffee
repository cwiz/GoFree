Index = Backbone.View.extend
  el: '#l-content'

  initialize: ->
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

    app.dom.win.on('resize', _.bind(@updatePageHeight, @))
    @collection.on('change:place', @placeChanged, @)
    @preloader.on('load', _.bind(@updateBG, @))
    @model.on('save', @showSERP, @)

    app.log('[app.views.Index]: initialize')

  updatePageHeight: ->
    @searchPart.css('min-height': app.dom.win.height())

  updateBG: (e)->
    @bg.fadeOut(200, =>
      @bg.attr('src', e.target.src)
      @bg.fadeIn(200)
      )

  placeChanged: (model, place) ->
    $.ajax
      url:  app.api.images + place.name
      success: (resp) =>
        @preloader.attr('src', resp.value.image)

  showSERP: ->
    height = app.dom.win.height()
    @serpPart.css('min-height': height, display: 'block')

    app.utils.scroll(height, 300, =>
      app.router.navigate('search/' + @model.hash, trigger: true)
      )

  showForm: ->
    height = app.dom.win.height()

    @searchPart.show()
    app.utils.scroll(height, 0)

    app.utils.scroll(0, 300, =>
      @serpPart.hide()
      )

  render: ->
    @searchPart.hide()
    @searchPart.fadeIn(500)

app.views.Index = Index
