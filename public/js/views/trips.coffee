Trips = Backbone.View.extend(
  el: '#page-index .v-s-destinations'
  initialize: () ->
    @collection.add({}) unless @collection.length
    @render()
    app.log('[app.views.Trips]: initialize')
    @

  render: () ->
    fragment = ''
    @collection.forEach((model, index, collection)->
      fragment += app.templates.trip(model.toJSON());
      )

    @$el.html(fragment)
    @
)

app.views.Trips = Trips
