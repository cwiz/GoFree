Index = Backbone.View.extend(
  el: '#page-index .block-current'
  initialize: () ->
    @render()
    # subview rendering
    @tripsView = new app.views.Trips(collection: @model.get('trips'))
    app.log('[app.views.Index]: initialize')
    @

  render: () ->
    @$el.hide()
    @$el.html(app.templates.searchform(@model.toJSON()))
    @$el.fadeIn(500)
    @
)

app.views.Index = Index
