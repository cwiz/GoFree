SERPTrip = Backbone.View.extend
  tagName: 'article'
  className: 'v-serp-trip'

  _collapsable: true

  _flightPrice: 0
  _hotelPrice: 0

  initialize: (@opts) ->
    @container = @opts.container
    @render()

    @bg = @$el.find('.v-s-t-bg-img')
    @preloader = $('<img/>')

    @totalsEl = @$el.find('.v-s-t-totals')
    @resultsFlightEl = @$el.find('.v-s-t-r-flight')
    @resultsHotelEl = @$el.find('.v-s-t-r-hotel')

    if @model.get('flights_signature')
      @flightsRow = new app.views.SERPTripRow(
        el: @$el.find('.v-s-t-flights')
        model: @model
        collection: @model.get('flights_filtered')
        template: app.templates.serp_trip_flight
        signature: @model.get('flights_signature')
        )

    if @model.get('hotels_signature')
      @hotelsRow = new app.views.SERPTripRow(
        el: @$el.find('.v-s-t-hotels')
        model: @model
        collection: @model.get('hotels_filtered')
        template: app.templates.serp_trip_hotel
        signature: @model.get('hotels_signature')
        )

    @preloader.on('load', _.bind(@updateBG, @))
    app.on('serp_selected', _.bind(@updateSelected, @))
    app.on('serp_deselected', _.bind(@removeSelected, @))

    @initialCollapse()
    @showTrip()
    @fetchBackground()

    app.log('[app.views.SERPTrip]: initialize')

  events:
    'click .v-s-t-places'        : 'toggleCollapse'

  updateSelected: (data)->
    if @model.get('flights_signature') == data.signature
      @_flightPrice = data.model.get('price')
      @resultsFlightEl.addClass('picked').find('.v-s-t-r-value-num').html(app.utils.formatNum(Math.floor(@_flightPrice)))

    if @model.get('hotels_signature') == data.signature
      @_hotelPrice = data.model.get('price')
      @resultsHotelEl.addClass('picked').find('.v-s-t-r-value-num').html(app.utils.formatNum(Math.floor(@_hotelPrice)))

    if @_flightPrice or @_hotelPrice
      @totalsEl.addClass('picked').find('.v-s-t-t-value-num').html(app.utils.formatNum(Math.floor(@_flightPrice + @_hotelPrice)))

  removeSelected: (data)->
    if @model.get('flights_signature') == data.signature
      @_flightPrice = 0
      @resultsFlightEl.removeClass('picked')

    if @model.get('hotels_signature') == data.signature
      @_hotelPrice = 0
      @resultsHotelEl.removeClass('picked')

    if @_flightPrice or @_hotelPrice
      @totalsEl.addClass('picked').find('.v-s-t-t-value-num').html(app.utils.formatNum(Math.floor(@_flightPrice + @_hotelPrice)))
    else
      @totalsEl.removeClass('picked')

  initialCollapse: ->
    @heightFull = @$el.outerHeight()

    @$el.addClass('collapsed')
    @heightCollapsed = @$el.find('.v-s-t-header').height()

    @$el.hide()

    @collapsed = true
    @$el.css(height: @heightCollapsed)

  toggleCollapse: ->
    if @collapsed then @expand() else @collapse()

  fetchBackground: ->
    $.ajax
      url: "#{app.api.images}#{@model.get('destination').place.country_code}/#{@model.get('destination').place.name}"
      success: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.blured)

  updateBG: (e)->
    @bg.fadeOut(200, =>
      @bg.attr('src', e.target.src)
      @bg.fadeIn(200)
      )

  showTrip: (e)->
    @$el.fadeIn(500)

  setCollapsable: (bool)->
    @_collapsable = bool

    if @_collapsable
      @$el.removeClass('nocollapse')
    else
      @$el.addClass('nocollapse')

  expand: ->
    return unless @collapsed

    @trigger('expand', @model.cid)

    @collapsed = false
    @$el.removeClass('collapsed')
    @$el.animate({ height: @heightFull }, { duration: 500, queue: false })

    @trigger('expanding', @model.cid)

  collapse: ->
    return if @collapsed

    @trigger('collapse', @model.cid)
    return if not @_collapsable

    @collapsed = true
    @$el.addClass('collapsed')
    @$el.animate({ height: @heightCollapsed }, { duration: 500, queue: false })

    @trigger('collapsing', @model.cid)

  render: ->
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

  destroy: ->
    @undelegateEvents()

    @preloader.off('load')
    app.off('serp_selected')
    app.off('serp_deselected')

    delete @preloader

    if @model.get('flights_signature')
      @flightsRow.destroy()
      delete @flightsRow
    if @model.get('hotels_signature')
      @hotelsRow.destroy()
      delete @hotelsRow

    delete @model
    delete @collection
    delete @opts

    app.log('[app.views.SERPTrip]: destroyed')

app.views.SERPTrip = SERPTrip
