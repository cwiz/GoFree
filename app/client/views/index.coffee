Index = Backbone.View.extend
  el: '#page-index'
  
  initialize: () ->
    app.dom.html.addClass('fullscreen')

    @searchFormView = new app.views.SearchForm
      el : @$el.find('.block-form')[0]
      model : @model
      collection : @model.get('trips')

    @render()
    
    app.log('[app.views.Index]: initialize')

  render: () ->
    @$el.hide()
    @$el.fadeIn(500)

app.views.Index = Index
