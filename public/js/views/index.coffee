Index = Backbone.View.extend(
  el: '#page-index .block-current'
  initialize: () ->
    @searchFormView = new app.views.SearchForm(
      el: @el
      model: @model
      collection: @model.get('trips')
    )

    @render()
    # subview rendering
    
    app.log('[app.views.Index]: initialize')
    @

  render: () ->
    @$el.hide()
    @$el.fadeIn(500)
    @
)

app.views.Index = Index
