SERPTrip = Backbone.View.extend
  tagName: 'article'
  className: 'v-serp-trip'

  _collapsable: true

  _flightPrice: 0
  _hotelPrice: 0

  initialize: (@opts) ->
    @container        = @opts.container
    @index            = @opts.index

    @render()

    @bg               = @$el.find('.v-s-t-bg-img')
    @preloader        = $('<img/>')

    @totalsEl         = @$el.find('.v-s-t-totals')
    @resultsFlightEl  = @$el.find('.v-s-t-r-flight')
    @resultsHotelEl   = @$el.find('.v-s-t-r-hotel')

    if @model.get('flights_signature')
      @flightsRow = new app.views.SERPTripRow(
        el        : @$el.find('.v-s-t-flights')
        model     : @model
        collection: @model.get('flights_filtered')
        template  : app.templates.serp_trip_flight
        signature : @model.get('flights_signature')
      )

    if @model.get('hotels_signature')
      @hotelsRow = new app.views.SERPTripRow(
        el        : @$el.find('.v-s-t-hotels')
        model     : @model
        collection: @model.get('hotels_filtered')
        template  : app.templates.serp_trip_hotel
        signature : @model.get('hotels_signature')
      )

      @hotelOverlay = new app.views.HotelOverlay(
        signature : @model.get('hotels_signature')
        # search: @opts.search
      )

    @preloader.on('load',     _.bind(@updateBG, @))
    app.on('serp_selected',   @updateSelected,  @)
    app.on('serp_deselected', @removeSelected,  @)

    @showTrip()
    @fetchBackground()

    app.log('[app.views.SERPTrip]: initialize')

  events:
    'click .v-s-t-i-photo'          : 'loadHotelOverlay'

  loadHotelOverlay: (e)->
    id    = $(e.target).parents('.v-s-t-item').attr('data-cid')
    hotel = @model.get('hotels').get(id)

    # request hotel data, call success handler
    $.ajax
      url     : "#{app.api.hotel_info}#{hotel.get('provider')}/#{hotel.get('id')}"
      cache   : true
      success : (resp) =>
        delete resp.hotel.price
        hotel.set resp.hotel
        @showHotelOverlay hotel
          
  showHotelOverlay: (data)->
    @hotelOverlay.show(
      hotel: data
      nights: app.utils.getDaysDiff(@model.get('origin').date, @model.get('destination').date)
    )

  updateSelected: (data)->
    if @model.get('flights_signature') == data.signature
      @_flightPrice = data.model.get('price')
      @resultsFlightEl.addClass('picked').find('.v-s-t-r-value-num').html(app.utils.formatNum(Math.floor(@_flightPrice)))

    if @model.get('hotels_signature') == data.signature
      @_hotelPrice = data.model.get('price')
      @resultsHotelEl.addClass('picked').find('.v-s-t-r-value-num').html(app.utils.formatNum(Math.floor(@_hotelPrice)))

    if @_flightPrice or @_hotelPrice
      total = Math.floor(@_flightPrice + @_hotelPrice)      
      @totalsEl.addClass('picked').find('.v-s-t-t-value-num').html app.utils.formatNum Math.floor total
      console.log @index
      app.trigger 'serp_subtotal_changed', {index: @index, total: total}

  removeSelected: (data)->
    if @model.get('flights_signature') == data.signature
      @_flightPrice = 0
      @resultsFlightEl.removeClass('picked')

    if @model.get('hotels_signature') == data.signature
      @_hotelPrice = 0
      @resultsHotelEl.removeClass('picked')

    if @_flightPrice or @_hotelPrice
      total = Math.floor(@_flightPrice + @_hotelPrice)
      @totalsEl.addClass('picked').find('.v-s-t-t-value-num').html app.utils.formatNum total
      app.trigger 'serp_subtotal_changed', {index: @index, total: total}
    else
      @totalsEl.removeClass('picked')
      app.trigger 'serp_subtotal_changed', {index: @index, total: 0}

  fetchBackground: ->
    $.ajax
      url: "#{app.api.images}#{@model.get('destination').place.country_code}/#{@model.get('destination').place.name}"
      success: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.blured)

  updateBG: (e)->
    timeout = 200
    @bg.fadeOut(timeout, =>
      @bg.attr 'src', e.target.src
      @bg.fadeIn timeout
    )

  showTrip: (e)->
    @$el.fadeIn(500)

  render: ->
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

  destroy: ->
    @undelegateEvents()

    @preloader.off('load')
    app.off('serp_selected', @updateSelected, @)
    app.off('serp_deselected', @removeSelected, @)

    delete @preloader

    if @model.get('flights_signature')
      @flightsRow.destroy()
      delete @flightsRow
    if @model.get('hotels_signature')
      @hotelsRow.destroy()
      delete @hotelsRow

    if @hotelOverlay
      @hotelOverlay.destroy()
      delete @hotelOverlay

    delete @model
    delete @collection
    delete @opts

    app.log('[app.views.SERPTrip]: destroyed')

app.views.SERPTrip = SERPTrip
