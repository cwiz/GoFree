SearchForm = Backbone.View.extend
  stops: {}
  maxDate: app.utils.pureDate(app.now)
  canAddStop: false

  initialize: ->
    @render()
    @addStopEl = @$el.find('.v-s-d-add')
    @errorEl = @$el.find('.v-s-error')
    @errorVisible = false

    @maxDate.setDate(@maxDate.getDate() + 1) # shift it to tomorrow

    @stopsEl = @$el.find('.v-s-destinations')

    @collection.on('add', @initStop, @)
    @collection.on('delete', @deleteStop, @)
    @collection.on('change:date', @dateChanged, @)
    @collection.on('change:place', @hideError, @)

    @$el.find('select.m-input-select').m_inputSelect()
    @form = @$el.find('.v-s-form').m_formValidate()[0]
    @restrictBudget()

    if @collection.length
      @initStops()
    else
      @populateCollection()

    app.log('[app.views.SearchForm]: initialize')
    @

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
      { date: null, removable: false }
    ])

  initStops: () ->
    iterator = _.bind(@initStop, @)
    @collection.each(iterator)

  initStop: (item) ->
    index     = @collection.indexOf(item)
    prevDate  = @collection.at(index - 1)?.get('date')
    minDate   = if prevDate then prevDate else app.utils.dateToYMD(@maxDate)

    @stops[item.cid] = new app.views.SearchTripsStop
      list: @stopsEl
      model: item
      minDate: if index == 0 then null else minDate

  deleteStop: (item) ->
    index = @collection.indexOf(item)
    prev = @collection.at(index - 1)
    next = @collection.at(index + 1)

    if (prev and next)
      @stops[prev.cid].setMaxDate(next.get('date'))
      @stops[next.cid].setMinDate(prev.get('date'))
    else
      @stops[prev.cid].setMaxDate(null)

    @collection.remove(item)
    delete @stops[item.cid]

  addStop: (e) ->
    return unless @canAddStop
    @collection.add(date: null, removable: true)

    @addStopEl.addClass('disabled')
    @canAddStop = false

  dateChanged: (model, date, prevValue) ->
    index = @collection.indexOf(model)
    prev = @collection.at(index - 1)
    next = @collection.at(index + 1)

    if (prev) then @stops[prev.cid].setMaxDate(date)
    if (next) then @stops[next.cid].setMinDate(date)

    dateObj = app.utils.YMDToDate(date)
    if (+dateObj > +@maxDate) then @maxDate = dateObj

    if not prevValue
      @addStopEl.removeClass('disabled')
      @canAddStop = true

  adultsChanged: (e) ->
    @model.set('adults', e.target.value)

  budgetChanged: (e) ->
    @model.set('budget', parseInt(e.target.value, 10))

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

app.views.SearchForm = SearchForm
