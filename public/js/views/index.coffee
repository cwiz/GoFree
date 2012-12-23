Index = Backbone.View.extend(
  initialize: () ->
    @render()
    @

  render: () ->
    $('#page-index .block-current').hide()
    $('#page-index .block-current').html(app.templates.searchform(@model.toJSON()))
    $('#page-index .block-current').fadeIn(500)
    @
)

app.views.index = Index
