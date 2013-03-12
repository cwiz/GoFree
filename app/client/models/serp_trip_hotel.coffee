SERPTripHotel = Backbone.Model.extend
  defaults:
    price		: 0
    name		: null
    stars		: 0
    photo		: null
    description	: null
    images		: null
    latitude	: null
    longitude	: null

  initialize: ->
    app.log('[app.models.SERPTripHotel]: initialize')

app.models.SERPTripHotel = SERPTripHotel
