SERPTrip = Backbone.Model.extend
  defaults:
    from: 
      name: null
    to: 
      name: null

    arrival: null
    departure: null

    hotels_signature: null
    hotels: new app.collections.SERPTripHotels()

    flights_signature: null
    flights: new app.collections.SERPTripFlights()

  initialize: ->
    app.log('[app.models.SERPTrip]: initialize')

app.models.SERPTrip = SERPTrip
