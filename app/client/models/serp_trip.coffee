SERPTrip = Backbone.Model.extend
  flightsFilter: 'none'
  hotelsFilter: 'none'

  defaults:
    origin:
      date: null
      place:
        name: null

    destination:
      date: null
      place:
        name: null

    flights_signature: null
    flights_filtered: null
    flights: null

    hotels_signature: null
    hotels_filtered: null
    hotels: null

  filterFactors:
    'convenient': (src)-> _.filter(src, (model)-> return model.get('stops') == 1 and model.get('price') <= 15000)
    'cheap': (src)-> _.filter(src, (model)-> return model.get('price') <= 10000)
    'direct': (src)-> _.filter(src, (model)-> return model.get('stops') == 1)
    'luxury': (src)-> _.filter(src, (model)-> return model.get('price') >= 40000 and model.get('stars') == 5)

  initialize: ->
    app.on('serp_filter', _.bind(@setFilter, @))
    app.log('[app.models.SERPTrip]: initialize')

  setFilter: (data) ->
    if @get('flights_signature') == data.signature
      @flightsFilter = data.filter
      @get('flights_filtered').update(@filter(@get('flights'), @flightsFilter)).trigger('filtered')

    if @get('hotels_signature') == data.signature
      @hotelsFilter = data.filter
      @get('hotels_filtered').update(@filter(@get('hotels'), @hotelsFilter)).trigger('filtered')

  observe: ->
    if @get('flights_signature')? then app.socket.on('flights_ready', _.bind(@receivedFlights, @))
    if @get('hotels_signature')? then app.socket.on('hotels_ready', _.bind(@receivedHotels, @))
    app.log('[app.models.SERPTrip]: observing')

  receivedFlights: (data) ->
    if @get('flights_signature') == data.signature
      @get('flights').add(data.items)
      @get('flights_filtered').update(@filter(@get('flights'), @flightsFilter)).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' flights, signed ' + data.signature)

  receivedHotels: (data) ->
    if @get('hotels_signature') == data.signature
      @get('hotels').add(data.items)
      @get('hotels_filtered').update(@filter(@get('hotels'), @hotelsFilter)).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' hotels, signed ' + data.signature)

  filter: (source, type)->
    if type == 'none' or not type
      source.toArray()
    else
      @filterFactors[type](source.toArray())

app.models.SERPTrip = SERPTrip
