SERPTripFlights = Backbone.Collection.extend
  comparator: 'price'
  model: app.models.SERPTripFlight

  initialize: ->
    app.log('[app.collections.SERPTripFlights]: initialize')

app.collections.SERPTripFlights = SERPTripFlights
