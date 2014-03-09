SERPTrips = Backbone.View.extend
  trips: {}
  _expandedHash: {}
  _budgetHash: {}
  
  el      : '.p-s-trips-wrap'

  progress: 0
  budget  : 0
  spent   : 0

  expanded: 0
  _locked : null

  initialize: (@opts)->
    @hash   = @opts.hash
    @budget = @opts.budget

    @subtotal = _.map(@collection, (elem) -> 0).concat([@budget])    
    @render()

    @progressMeterEl= $         '.v-s-t-p-meter'
    @budgetMeterEl  = $         '.v-s-t-b-meter'
    @container      = @$el.find '.v-serp-trips-container'
    @amountSpentEl  = $         '.v-s-t-b-spentamount'
    @amountLeftEl   = $         '.v-s-t-b-leftamount'

    app.socket.on('progress',       _.bind(@updateProgress, @))
    app.on('serp_subtotal_changed', @updateBudgetMeter,     @)

    @initTrips()

    app.log('[app.views.SERPTrips]: initialize')

  updateProgress: (data) ->
    return unless data.hash == @hash
    @progress = data.progress
    @setProgressMeter()
    app.log('[app.views.SERPTrips]: progress ' + Math.floor(@progress * 100) + '%')

  setProgressMeter: ->
    pos = app.size.width * @progress
    @progressMeterEl.animate({left: pos}, 10, 'linear')

  initBudgetMeter: ->

    cities = @collection.map (elem) -> elem.get('destination').place.name_ru

    budgetCities = []
    for i in [0...(cities.length-1)]
      budgetCities.push 0
    budgetCities.push 0
    
    cities.push 'Осталось'

    @budgetSlider = $('.slider').oxyeSlider({
      value   : budgetCities,
      labels  : cities
      max     : @budget
      step    : 1000
      minRange: 10000
      disable : true
    })

    return @budgetSlider

  updateBudgetMeter: (data) ->
    
    left = @budget 
    @subtotal[data.index] = data.total

    for i in [0...(@subtotal.length-1)]
      left -= @subtotal[i]

    @subtotal[@subtotal.length - 1] = left

    values = []
    for i in [0...(@subtotal.length-1)]
      value = 0
      for j in [0..i]
        value += @subtotal[j]

      values.push value

    @budgetSlider.setValues values

  initTrips: ->
    iterator = (model) =>
      @trips[model.cid] = new app.views.SERPTrip(
        container : @container
        model     : model
        search    : @opts.search
        index     : @collection.indexOf model
      )
    
    @collection.each(iterator)

    @initBudgetMeter()

  render: ->
    @$el.html(app.templates.serp_trips())

  destroy: ->
    @undelegateEvents()
    app.socket.removeAllListeners('progress')
    app.off('serp_subtotal_changed',  @updateBudgetMeter,   @)

    progress  = 0
    budget    = 0
    spent     = 0
  
    for k, v of @trips
      v.destroy()
      delete @trips[k]

    delete @trips
    delete @hash
    delete @_expandedHash
    delete @_budgetHash
    delete @_locked

    @budgetSlider.elem.remove()
    @budgetSlider.elem.parent().empty()
    delete @budgetSlider

    delete @container
    delete @collection

    app.log('[app.views.SERPTrips]: destroyed')

app.views.SERPTrips = SERPTrips
