SERPTrip = Backbone.Model.extend
  defaults:
    from: 
      name: null
    to: 
      name: null

    arrival: null
    departure: null

    hotels_signature: null
    hotels: null

    flights_signature: null
    flights: null

  initialize: ->
    app.log('[app.models.SERPTrip]: initialize')

app.models.SERPTrip = SERPTrip
