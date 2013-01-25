SERPTrips = Backbone.Collection.extend
  model: app.models.SERPTrip

  initialize: ->
    app.log('[app.collections.SERPTrips]: initialize')

app.collections.SERPTrips = SERPTrips
