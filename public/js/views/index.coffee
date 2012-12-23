Index = Backbone.View.extend(
  initialize: ()->
    @render()
    @

  render: ()->
    $('#page-index .block-current').html(app.templates.searchform(@model.toJSON()))
    @
)

app.views.index = Index
