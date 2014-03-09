SearchForm = Backbone.View.extend
  stops: {}
  maxDate: app.utils.pureDate(app.now)
  canAddStop: false

  initialize: ->

    @render()

    @addStopEl    = @$el.find '.v-s-d-add'
    @errorEl      = @$el.find '.v-s-error'
    @errorVisible = false

    @maxDate.setDate(@maxDate.getDate() + 2) # shift it to day after tomorrow

    dependant = @$el.find('.vs-final-place label')

    @initialPlaceAutocomplete = new app.views.SearchPlaceAutocomplete 
      el        : @$el.find('.vs-initial-place')
      model     : @model.get('initial')
      dependant : dependant

    @finalPlaceCalendar = new app.views.SearchPlaceCalendar 
      el        : @$el.find '.vs-final-date'
      model     : @model.get('final')
      minDate   : app.utils.dateToYMD @maxDate

    @stopsEl = @$el.find('.v-s-destinations')

    @collection.on('add',             @initStop,          @)
    @collection.on('delete',          @deleteStop,        @)
    @collection.on('change:date',     @dateChanged,       @)
    @collection.on('change:place',    @hideError,         @)
    @collection.on('change',          @collectionChanged, @)

    @model.get('final').on   'change:date add',   @dateChanged,       @
    @model.get('final').on   'change:date',       @collectionChanged, @

    @model.get('initial').on 'change:place',      @initialChange,     @
    @model.get('initial').on 'change:place add',  @collectionChanged, @

    @$el.find('select.m-input-select').m_inputSelect()
    @form = @$el.find('.v-s-form').m_formValidate()[0]
    @restrictBudget()

    if @collection.length
      @initStops()
      @resetDatesLimits()
    else
      @populateCollection()
      @getInitialLocation()

    app.log('[app.views.SearchForm]: initialize')

    # focusing in input 
    cid = @collection.at(0).cid
    @stops[cid].autocomplete.focus()

    # KISSMetrics
    _kmq.push ['record', 'searchform view']

    return @

  events:
    'click .v-s-d-add'        : 'addStop'
    'change .m-i-s-select'    : 'adultsChanged'
    'change .v-s-amount'      : 'budgetChanged'
    'valid form'              : 'handleSubmit'
    'click .v-s-error'        : 'hideError'

  render: ->
    @$el.html(app.templates.searchform(@model.toJSON()))

  restrictBudget: ->

    validate = (e) ->
      if (e.keyCode < 48 or e.keyCode > 57)
         app.e(e)

    @$el.find('.v-s-amount').on('keypress input', validate)

  populateCollection: ->
    @collection.add([
      { date: app.utils.dateToYMD(@maxDate), removable: false }
    ])

  initStops: () ->
    iterator = _.bind(@initStop, @)
    @collection.each(iterator)

  getInitialLocation: () ->
    $.ajax
      url: app.api.get_location
      success: (resp) =>
        if resp and resp.value
          @model.get('initial').set('place', resp.value)

  resetDatesLimits: () ->

    @collection.each (model)=> 
      @dateChanged model, model.get('date')

  initStop: (item) ->
    index     = @collection.indexOf(item)
    prevDate  = @collection.at(index - 1)?.get('date')
    minDate   = if prevDate then prevDate else app.utils.dateToYMD(@maxDate)

    @stops[item.cid] = new app.views.SearchTripsStop
      list: @stopsEl
      model: item
      minDate: if index == 0 then null else minDate
      maxDate: @model.get('final').get('date') or @minDate

  deleteStop: (item) ->
    index = @collection.indexOf(item)
    prev = @collection.at(index - 1)
    next = @collection.at(index + 1)

    if (prev and next)
      @stops[prev.cid].calendar.setMaxDate(next.get('date'))
      @stops[next.cid].calendar.setMinDate(prev.get('date'))
    else
      @stops[prev.cid].calendar.setMaxDate(null)

    @collection.remove(item)
    delete @stops[item.cid]

    if @collection.last().get('date')
      @addStopEl.removeClass('disabled')
      @canAddStop = true

  addStop: (e) ->
    return unless @canAddStop
    @collection.add(date: null, removable: true)

    @addStopEl.addClass('disabled')
    @canAddStop = false

  dateChanged: (model, date) ->

    index = @collection.indexOf model

    if index is -1
      lastCid = @collection.at(@collection.length - 1).cid
      @stops[lastCid].calendar.setMaxDate date
      return

    prev  = @collection.at(index - 1)
    next  = @collection.at(index + 1)

    if index is (@collection.length - 1)
      @finalPlaceCalendar.setMinDate date

    if prev
      @stops[prev.cid].calendar.setMaxDate(date)

    if next
      @stops[next.cid].calendar.setMinDate(date)

    dateObj = app.utils.YMDToDate(date)
    if (+dateObj > +@maxDate) then @maxDate = dateObj

    # if not model.previous('date')
    #   @addStopEl.removeClass('disabled')
    #   @canAddStop = true

  collectionChanged: (e) ->

    if @model.isSemiValid()

      if @model.get('trips').length < 5
        @addStopEl.removeClass('disabled')
        @canAddStop = true

      @model.preSave() 

  adultsChanged: (e) ->
    @model.set('adults', parseInt(e.target.value))

  budgetChanged: (e) ->
    @model.set('budget', parseInt(e.target.value, 10)*1000)

  showError: ->
    unless @errorVisible
      @errorEl.show()
      @errorVisible = true

  hideError: ->
    if @errorVisible
      @errorEl.hide()
      @errorVisible = false

  handleSubmit: (evt, e) ->
    app.e(e)
    @hideError()

    if (@model.isValid())
      @model.save()
    else
      @showError()

  destroy: ->
    @undelegateEvents()

    @collection.off('add', @initStop, @)
    @collection.off('delete', @deleteStop, @)
    @collection.off('change:date', @dateChanged, @)
    @collection.off('change:place', @hideError, @)

    delete @collection
    delete @form

    app.log('[app.views.SearchForm]: destroy')

app.views.SearchForm = SearchForm
