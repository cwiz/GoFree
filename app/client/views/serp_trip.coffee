SERPTrip = Backbone.View.extend
  tagName: 'article'
  className: 'v-serp-trip'

  itemsInView: 3

  initialize: (@opts) ->
    @container = @opts.container
    @render()

    @bg = @$el.find('.v-s-t-bg-img')
    @preloader = $('<img/>')

    @flightsEl = @$el.find('.v-s-t-flights')
    @hotelsEl = @$el.find('.v-s-t-hotels')

    @flightsCarouselEl = @flightsEl.find('.m-carousel')
    @hotelsCarouselEl = @hotelsEl.find('.m-carousel')
    @flightsList = @flightsEl.find('.m-c-list')
    @hotelsList = @hotelsEl.find('.m-c-list')
    @flightsCounter = @flightsEl.find('.v-s-t-c-count')
    @hotelsCounter = @hotelsEl.find('.v-s-t-c-count')

    @flightsCarousel = @flightsCarouselEl.m_carousel()[0]
    @hotelsCarousel = @hotelsCarouselEl.m_carousel()[0]

    @flightsShift = @itemsInView
    @hotelsShift = @itemsInView

    @flights = @model.get('flights')
    @hotels = @model.get('hotels')

    # @fetchBackground()
    @showTrip()

    @preloader.on('load', _.bind(@showTrip, @))

    @model.on('hotels_progress', @hotelsProgress, @)
    @model.on('flights_progress', @flightsProgress, @)

    @flightsCarouselEl.on('mod_shifted_right', _.bind(@appendFlights,@))
    @hotelsCarouselEl.on('mod_shifted_right', _.bind(@appendHotels,@))

    app.log('[app.views.SERPTrip]: initialize')

  fetchBackground: ->
    $.ajax
      url:  app.api.images + @model.get('destination').place.name
      complete: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.image)
        else
          @showTrip()

  showTrip: (e)->
    image = @preloader.attr('src')
    @bg.attr('src', @preloader.attr('src')) if image

    @$el.fadeIn(500)

  flightsProgress: (p)->
    items = if p is 1 then @itemsInView * 2 else @itemsInView
    html = for model in @flights.first(items)
      app.templates.serp_trip_flight(_.extend(model.toJSON(), { origin: @model.get('origin'), destination: @model.get('destination')}))

    @flightsList.html(html)
    @flightsCounter.html(@flightsShift + '/' + @flights.length)

    if p is 1
      @flightsCarousel.hardReset()
      @flightsEl.addClass('loaded')

  hotelsProgress: (p)->
    items = if p is 1 then @itemsInView * 2 else @itemsInView
    html = for model in @hotels.first(items)
      app.templates.serp_trip_hotel(_.extend(model.toJSON(), { origin: @model.get('origin'), destination: @model.get('destination')}))

    @hotelsList.html(html)
    @hotelsCounter.html(@hotelsShift + '/' + @hotels.length)

    if p is 1
      @hotelsCarousel.hardReset()
      @hotelsEl.addClass('loaded')

  appendFlights: ->
    length = @flights.length
    @flightsShift += @itemsInView

    if length >= @flightsShift
      start = @flightsShift - 1
      max = Math.min(length, @flightsShift + @itemsInView) - 1

      html = for i in [start..max]
        app.templates.serp_trip_flight(_.extend(@flights.at(i).toJSON(), { origin: @model.get('origin'), destination: @model.get('destination')}))

      @flightsList.append(html)
      @flightsCarousel.reset()
      @flightsCounter.html(@flightsShift + '/' + length)

  appendHotels: ->
    length = @hotels.length
    @hotelsShift += @itemsInView

    if length >= @hotelsShift
      start = @hotelsShift - 1
      max = Math.min(length, @hotelsShift + @itemsInView) - 1

      html = for i in [start..max]
        app.templates.serp_trip_hotel(_.extend(@hotels.at(i).toJSON(), { origin: @model.get('origin'), destination: @model.get('destination')}))

      @hotelsList.append(html)
      @hotelsCarousel.reset()
      @hotelsCounter.html(@hotelsShift + '/' + length)

  render: ->
    @$el.hide()
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

app.views.SERPTrip = SERPTrip
