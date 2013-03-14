SERPTrip = Backbone.Model.extend
  flightsFilter   : 'none'
  hotelsFilter    : 'none'

  flightsPreFilter: 'none'
  hotelsPreFilter : 'none'

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

      # ugly way to check hotel or flight
      firstElement = src[0]
      return unless firstElement

      if firstElement.get('type') is 'flight'
        minDuration = _.min(src, (elem) -> elem.get('duration')).get('duration')
        
        return _.sortBy(
          _.filter(src, (model) -> 
            model.get('stops') <= 1 and model.get('duration') <= 24*60*60
          ), 
          (elem) -> minDuration / elem.get('duration')
        )

      return _.filter src, (model) -> 
        model.get('stars') >= 4 or model.get('reviews_count') > 10

    'cheap':      (src) -> 
      minPrice = _.min(src, (elem) -> elem.get('price')).get('price')
      return _.filter(src, (model)-> model.get('price') <= minPrice * 1.2)
    
    # flights
    'direct':     (src) -> _.sortBy(_.filter(src, (model)-> model.get('stops') == 0), (elem) -> elem.duration)
    
    # hotels
    'luxury':     (src) -> 
      apartments  = _.filter(src,        (model) -> model.get('type') is 'apartment')
      meanPrice   = 0.0

      for a in apartments
        meanPrice += a.get 'price'

      meanPrice /= apartments.length

      return _.filter src, (model)-> 
        if model.get('type') is 'hotel'
          return model.get('stars') is 5 
        else
          return model.get('price') >=  1.5 * meanPrice
    
    'hotels':     (src) -> _.filter(src, (model)-> model.get('type') is 'hotel')
    'apartments': (src) -> _.filter(src, (model)-> model.get('type') is 'apartment')

  initialize: ->
    app.on('serp_prefilter', @setPreFilter, @)
    app.on('serp_filter', @setFilter, @)
    app.log('[app.models.SERPTrip]: initialize')

  setPreFilter: (data) ->
    if @get('flights_signature') is data.signature
      @flightsPreFilter = data.filter
      @get('flights_filtered').update(@filter('flights')).trigger('filtered')

    if @get('hotels_signature') is data.signature
      @hotelsPreFilter = data.filter
      @get('hotels_filtered').update(@filter('hotels')).trigger('filtered')

  setFilter: (data) ->
    if @get('flights_signature') is data.signature
      @flightsFilter = data.filter
      @get('flights_filtered').update(@filter('flights')).trigger('filtered')

    if @get('hotels_signature') is data.signature
      @hotelsFilter = data.filter
      @get('hotels_filtered').update(@filter('hotels')).trigger('filtered')

  observe: ->
    if @get('flights_signature')? then app.socket.on('flights_ready', _.bind(@receivedFlights, @))
    if @get('hotels_signature')? then app.socket.on('hotels_ready', _.bind(@receivedHotels, @))
    app.log('[app.models.SERPTrip]: observing')

  receivedFlights: (data) ->
    if @get('flights_signature') == data.signature
      @get('flights').add(data.items)
      @get('flights_filtered').update(@filter('flights')).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' flights, signed ' + data.signature)

  receivedHotels: (data) ->
    if @get('hotels_signature') == data.signature
      @get('hotels').add(data.items)
      @get('hotels_filtered').update(@filter('hotels')).trigger('progress', data.progress)
      app.log('[app.models.SERPTrip]: received ' + data.items.length + ' hotels, signed ' + data.signature)

  filter: (type)->
    if type == 'flights'
      source = @get('flights')
      preFilter = @flightsPreFilter
      filter = @flightsFilter
    else
      source = @get('hotels')
      preFilter = @hotelsPreFilter
      filter = @hotelsFilter

    result = source.toArray()

    if preFilter != 'none'
      result = @filterFactors[preFilter](result)

    if filter != 'none'
      result = @filterFactors[filter](result)
    
    result

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
