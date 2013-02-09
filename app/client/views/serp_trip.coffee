SERPTrip = Backbone.View.extend
  tagName: 'article'
  className: 'v-serp-trip'

  initialize: (@opts) ->
    @container = @opts.container
    @render()

    @bg = @$el.find('.v-s-t-bg-img')
    @preloader = $('<img/>')

    @flightsRow = new app.views.SERPTripRow(
      el: @$el.find('.v-s-t-flights')
      model: @model
      collection: @model.get('flights_filtered')
      template: app.templates.serp_trip_flight
      signature: @model.get('flights_signature')
      )

    @hotelsRow = new app.views.SERPTripRow(
      el: @$el.find('.v-s-t-hotels')
      model: @model
      collection: @model.get('hotels_filtered')
      template: app.templates.serp_trip_hotel
      signature: @model.get('hotels_signature')
      )

    @preloader.on('load', _.bind(@showTrip, @))

    @initialCollapse()
    @fetchBackground()
    @showTrip()

    app.log('[app.views.SERPTrip]: initialize')

  events:
    'click .v-s-t-places'        : 'toggleCollapse'

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
      url:  "#{app.api.images}#{@model.get('destination').place.country_code}/#{@model.get('destination').place.name}"
      success: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.blured)
        else
          @showTrip()
      error: =>
        @showTrip()

  showTrip: (e)->
    image = @preloader.attr('src')
    @bg.attr('src', @preloader.attr('src')) if image
    @$el.fadeIn(500)

  expand: ->
    return unless @collapsed
    @collapsed = false
    @$el.removeClass('collapsed')
    @$el.animate({ height: @heightFull }, { duration: 500, queue: false })

  collapse: ->
    return if @collapsed
    @collapsed = true
    @$el.addClass('collapsed')
    @$el.animate({ height: @heightCollapsed }, { duration: 500, queue: false })

  render: ->
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

app.views.SERPTrip = SERPTrip
