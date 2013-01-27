SERPTrip = Backbone.View.extend
  tagName: 'article'
  className: 'v-serp-trip'

  initialize: (@opts) ->
    @container = @opts.container
    @render()

    @bg = @$el.find('.v-s-t-bg-img')
    @preloader = $('<img/>')

    @flights = @model.get('flights')
    @hotels = @model.get('hotels')

    @fetchBackground()

    @preloader.on('load', _.bind(@showTrip, @))

    app.log('[app.views.SERPTrip]: initialize')

  fetchBackground: ->
    $.ajax
      url:  app.api.images + @model.get('destination').place.name
      success: (resp) =>
        @preloader.attr('src', resp.value.image)

  showTrip: (e)->
    # @bg.attr('src', @preloader.attr('src'))
    @$el.fadeIn(500)

  render: ->
    @$el.hide()
    @$el.html(app.templates.serp_trip(@model.toJSON()))
    @container.append(@$el)

app.views.SERPTrip = SERPTrip
