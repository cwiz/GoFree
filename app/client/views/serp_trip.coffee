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

    # @fetchBackground()
    @showTrip()

    @preloader.on('load', _.bind(@showTrip, @))

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

  render: ->
    @$el.hide()
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

app.views.SERPTrip = SERPTrip