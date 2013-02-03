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
      collection: @model.get('flights')
      template: app.templates.serp_trip_flight
      )

    @hotelsRow = new app.views.SERPTripRow(
      el: @$el.find('.v-s-t-hotels')
      model: @model
      collection: @model.get('hotels')
      template: app.templates.serp_trip_hotel
      )

    @preloader.on('load', _.bind(@showTrip, @))

    @initialCollapse()
    # @fetchBackground()
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
      url:  app.api.images + @model.get('destination').place.name
      success: (resp) =>
        if resp and resp.value
          @preloader.attr('src', resp.value.image)
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
    @$el.animate(height: @heightFull, 500)

  collapse: ->
    return if @collapsed
    @collapsed = true
    @$el.addClass('collapsed')
    @$el.animate(height: @heightCollapsed, 500)

  render: ->
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

app.views.SERPTrip = SERPTrip
