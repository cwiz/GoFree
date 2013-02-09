SERPTrips = Backbone.View.extend
  trips: {}
  el: '.p-s-trips-wrap'

  expanded: 0
  _locked: null

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
      @trips[model.cid].on('expand', _.bind(@beforeExpand, @))
      @trips[model.cid].on('collapse', _.bind(@beforeCollapse, @))
    @collection.each(iterator)

  expandFirst: ->
    _.values(@trips)[0].expand()

  beforeExpand: (cid)->
    @expanded++
    @_locked.setCollapsable(true) if @_locked

  beforeCollapse: (cid)->
    if @expanded == 1
      @_locked = @trips[cid]
      @_locked.setCollapsable(false)
    else
      @expanded--


  render: ->
    @$el.html(app.templates.serp_trips())

app.views.SERPTrips = SERPTrips
