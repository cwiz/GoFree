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
    # flights + hotels
    'convenient': (src)-> 
      _.filter(src, (model)-> 
        if model.get('stops')?
          model.get('stops') == 0 and model.get('price') <= 15000
        else if model.get('stars')
          model.get('stars') >= 4 and model.get('price') <= 15000
        else
          model.get('price') >= 7000 and model.get('price') <= 15000
        )

    'cheap': (src)-> _.filter(src, (model)-> return model.get('price') <= 10000)
    # flights
    'direct': (src)-> _.filter(src, (model)-> return model.get('stops') == 0)
    # hotels
    'luxury': (src)-> _.filter(src, (model)-> return model.get('price') >= 40000 and model.get('stars') == 5)

  initialize: ->
    app.on('serp_filter', @setFilter, @)
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

  destroy: ->
    if @get('flights_signature')? then @set('flights_signature', null)
    if @get('hotels_signature')? then @set('hotels_signature', null)

    app.off('serp_filter', @setFilter, @)
    app.socket.removeAllListeners('flights_ready')
    app.socket.removeAllListeners('hotels_ready')

    flightsFilter = 'none'
    hotelsFilter = 'none'

    @clear()
    app.log('[app.models.SERPTrip]: destroyed')

app.models.SERPTrip = SERPTrip
