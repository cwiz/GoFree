SERPTripFlight = Backbone.Model.extend
  defaults:
    price: 0

    # origin:
    #   date: null
    #   place:
    #     name: null

    # destination:
    #   date: null
    #   place:
    #     name: null

    departure: null
    arrival: null
    duration: null

    airline: null
    stops: 0

  initialize: ->
    app.log('[app.models.SERPTripFlight]: initialize')

app.models.SERPTripFlight = SERPTripFlight
