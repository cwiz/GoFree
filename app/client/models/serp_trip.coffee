SERPTrip = Backbone.Model.extend
  defaults:
    origin:
      date: null
      place:
        name: null

    destination:
      date: null
      place:
        name: null

    hotels_signature: null
    hotels: null

    flights_signature: null
    flights: null

  initialize: ->
    app.log('[app.models.SERPTrip]: initialize')

app.models.SERPTrip = SERPTrip
