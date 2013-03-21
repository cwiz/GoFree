SERPTrips = Backbone.View.extend
  trips: {}
  _expandedHash: {}
  _budgetHash: {}
  el: '.p-s-trips-wrap'

  progress: 0
  budget: 0
  spent: 0

  expanded: 0
  _locked: null

  initialize: (@opts)->
    @hash = @opts.hash
    @render()

    # tyt hyuta moya
    #@progressMeterEl = @$el.find('.v-s-t-p-meter')
    @progressMeterEl = $('.v-s-t-p-meter')
    
    #@budgetMeterEl = @$el.find('.v-s-t-b-meter')
    @budgetMeterEl = $('.v-s-t-b-meter')

    @container = @$el.find('.v-serp-trips-container')

    #@amountSpentEl = @$el.find('.v-s-t-b-spentamount')
    @amountSpentEl = $('.v-s-t-b-spentamount')
    
    #@amountLeftEl = @$el.find('.v-s-t-b-leftamount')
    @amountLeftEl = $('.v-s-t-b-leftamount')

    app.socket.on('progress', _.bind(@updateProgress, @))
    app.on('serp_selected',   @updateBudgetAdd, @)
    app.on('serp_deselected', @updateBudgetRemove, @)
    app.on('resize', @updateMeters, @)

    @initTrips()
    @expandFirst()
    @updateMeters()

    app.log('[app.views.SERPTrips]: initialize')

  setBudget: (num)->
    @budget = num
    @setBudgetMeter()

  updateMeters: ->
    @setProgressMeter()
    @setBudgetMeter()

  updateProgress: (data) ->
    return unless data.hash == @hash
    @progress = data.progress
    @setProgressMeter()
    app.log('[app.views.SERPTrips]: progress ' + Math.floor(@progress * 100) + '%')

  updateBudgetAdd: (data)->
    @_budgetHash[data.signature] = data.model.get('price')
    @setBudgetMeter()

  updateBudgetRemove: (data)->
    delete @_budgetHash[data.signature]
    @setBudgetMeter()

  setProgressMeter: ->
    pos = app.size.width * @progress
    @progressMeterEl.animate({left: pos}, 10, 'linear')

  setBudgetMeter: ->
    @spent = _.reduce(_.values(@_budgetHash), (memo, num)->
      memo + num
    , 0)

    diff = @budget - @spent
    perc = Math.min(@spent / @budget, 1) # in case we're going over budget
    pos = app.size.width * perc

    @amountSpentEl.html(app.utils.formatNum(@spent))
    @amountLeftEl.html(app.utils.formatNum(diff))

    @budgetMeterEl.css(left: pos)

  initTrips: ->
    iterator = (model) =>
      @trips[model.cid] = new app.views.SERPTrip(
        container: @container
        model: model
        search: @opts.search
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

  destroy: ->
    @undelegateEvents()
    app.socket.removeAllListeners('progress')
    app.off('serp_selected', @updateBudgetAdd, @)
    app.off('serp_deselected', @updateBudgetRemove, @)
    app.off('resize', @updateMeters, @)

    progress = 0
    budget = 0
    spent = 0
  
    for k, v of @trips
      v.destroy()
      delete @trips[k]

    delete @trips
    delete @hash
    delete @_expandedHash
    delete @_budgetHash
    delete @_locked

    delete @container
    delete @collection

    app.log('[app.views.SERPTrips]: destroyed')

app.views.SERPTrips = SERPTrips
