SERPTrips = Backbone.View.extend
  trips: {}
  _expandedHash: {}
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
    first = _.values(@trips)[0]
    first.expand()

    @_locked = first
    @_locked.setCollapsable(false)

  findLastExpanded: ->
    for k, v of @_expandedHash
      if v then res = k

    res

  beforeExpand: (cid)->
    @expanded++
    @_expandedHash[cid] = true
    @_locked.setCollapsable(true) if @_locked

  beforeCollapse: (cid)->
    return if not @trips[cid]._collapsable

    @expanded--
    @_expandedHash[cid] = false

    if @expanded == 1
      @_locked = @trips[@findLastExpanded()]
      @_locked.setCollapsable(false)

  render: ->
    @$el.html(app.templates.serp_trips())

app.views.SERPTrips = SERPTrips
