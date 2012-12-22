Index = Backbone.View.extend(
  initialize: ()->
    @render()
    @

  render: ()->
    $('#page-index .block-current').html(app.templates.searchform())
    @
)

app.views.index = Index
