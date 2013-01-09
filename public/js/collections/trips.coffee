Trips = Backbone.Collection.extend(
  model: app.models.TripsStop

  initialize: ()->
    app.log('[app.collections.Trips]: initialize')
)

app.collections.Trips = Trips
