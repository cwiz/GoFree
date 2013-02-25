SERPTripSelected = Backbone.Model.extend
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
    flight: null

    hotels_signature: null
    hotel: null

  initialize: ->
    app.log('[app.models.SERPTripSelected]: initialize')

  observe: ->
    app.on('serp_selected', @selectItem, @)
    app.on('serp_deselected', @deselectItem, @)
    app.log('[app.models.SERPTripSelected]: observing')

  selectItem: (data) ->
    if @get('flights_signature') == data.signature
      @set('flight', data.model)
      app.log('[app.models.SERPTripSelected]: selected flight, signed ' + data.signature)

    if @get('hotels_signature') == data.signature
      @set('hotel', data.model)
      app.log('[app.models.SERPTripSelected]: selected hotel, signed ' + data.signature)

  deselectItem: (data) ->
    if @get('flights_signature') == data.signature
      @set('flight', null)
      app.log('[app.models.SERPTripSelected]: deselected flight, signed ' + data.signature)

    if @get('hotels_signature') == data.signature
      @set('hotel', null)
      app.log('[app.models.SERPTripSelected]: deselected hotel, signed ' + data.signature)

  destroy: ->
    app.off('serp_selected', @selectItem, @)
    app.off('serp_deselected', @deselectItem, @)
    app.log('[app.models.SERPTripSelected]: destroyed')

app.models.SERPTripSelected = SERPTripSelected
