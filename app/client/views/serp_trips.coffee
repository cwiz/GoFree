SERPTrips = Backbone.View.extend
  trips: {}
  el: '.p-s-trips-wrap'

  initialize: ->
    @render()

    @container = @$el.find('.v-serp-trips-container')

    @initTrips()

    app.log('[app.views.SERPTrips]: initialize')

  initTrips: ->
    iterator = (model) =>
      @trips[model.cid] = new app.views.SERPTrip(
        container: @container
        model: model
        )
    @collection.each(iterator)

  render: ->
    @$el.html(app.templates.serp_trips())

app.views.SERPTrips = SERPTrips
