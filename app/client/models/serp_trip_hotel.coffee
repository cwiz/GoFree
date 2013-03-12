SERPTripHotel = Backbone.Model.extend
  defaults:
    price		: 0
    name		: null
    stars		: 0
    photo		: null
    description	: null
    images		: []
    latitude	: null
    longitude	: null
    address     : null

  initialize: ->
    app.log('[app.models.SERPTripHotel]: initialize')

app.models.SERPTripHotel = SERPTripHotel
