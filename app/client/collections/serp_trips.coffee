SERPTrips = Backbone.Collection.extend
  model: app.models.SERPTrip

  initialize: ->
    @on('add', @instantiateCollections, @)

    app.log('[app.collections.SERPTrips]: initialize')

  instantiateCollections: (model) ->
    unless model.get('hotels')?
      model.set('hotels', new app.collections.SERPTripHotels())

    unless model.get('flights')?
      model.set('flights', new app.collections.SERPTripFlights())

  _dump: (json) ->
    for item in json
      item.hotels = item.hotels.toJSON()
      item.flights = item.flights.toJSON()
 
    item

  jsonify: ->
    @_dump(@toJSON())

app.collections.SERPTrips = SERPTrips
