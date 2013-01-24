SearchTrips = Backbone.Collection.extend
  model: app.models.SearchTripsStop

  initialize: ()->
    app.log('[app.collections.SearchTrips]: initialize')

app.collections.SearchTrips = SearchTrips
