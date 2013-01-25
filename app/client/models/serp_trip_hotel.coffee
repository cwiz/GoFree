SERPTripHotel = Backbone.Model.extend
  defaults:
    price: 0
    # nights: 0

    name: null
    stars: 0

    photo: null

  initialize: ->
    app.log('[app.models.SERPTripHotel]: initialize')

app.models.SERPTripHotel = SERPTripHotel
