Index = Backbone.View.extend(
  initialize: () ->
    @render()
    app.log('[app.views.Index]: initialize')
    @

  render: () ->
    $('#page-index .block-current').hide()
    $('#page-index .block-current').html(app.templates.searchform(@model.toJSON()))
    $('#page-index .block-current').fadeIn(500)
    @
)

app.views.Index = Index
