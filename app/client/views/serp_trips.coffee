SERPTrips = Backbone.View.extend
  trips: {}
  el: '.p-s-trips-wrap'

  initialize: ->
    @render()

    @container = @$el.find('.v-serp-trips-container')

    @initTrips()

    @expandFirst()

    app.log('[app.views.SERPTrips]: initialize')

  initTrips: ->
    iterator = (model) =>
      @trips[model.cid] = new app.views.SERPTrip(
        container: @container
        model: model
        )
    @collection.each(iterator)

  expandFirst: ->
    _.values(@trips)[0].expand()

  render: ->
    @$el.html(app.templates.serp_trips())

app.views.SERPTrips = SERPTrips
