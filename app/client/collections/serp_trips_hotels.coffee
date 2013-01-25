SERPTripHotels = Backbone.Collection.extend
  model: app.models.SERPTripHotel

  initialize: ->
    app.log('[app.collections.SERPTripHotels]: initialize')

app.collections.SERPTripHotels = SERPTripHotels
