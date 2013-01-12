SearchForm = Backbone.View.extend(
  stops: {}

  initialize: () ->
    @render()

    @stopsEl = @$el.find('.v-s-destinations')

    @collection.on('add', @initStop, @)
    @collection.on('delete', @deleteStop, @)
    @collection.on('change:date', @dateChanged, @)

    @$el.find('select.m-input-select').m_inputSelect()
    @restrictBudget()

    @populateCollection() unless @collection.length > 1

    app.log('[app.views.SearchForm]: initialize')
    @

  events:
    'click .v-s-d-add'        : 'addStop'
    'change .m-i-s-select'    : 'adultsChanged'
    'change .v-s-amount'      : 'budgetChanged'
    'submit form'             : 'handleSubmit'

  render: () ->
    @$el.html(app.templates.searchform(@model.toJSON()))

  restrictBudget: () ->
    validate = (e) ->
      if (e.keyCode < 48 or e.keyCode > 57)
         app.e(e)

    @$el.find('.v-s-amount').on('keypress input', validate)

  populateCollection: () ->
    @collection.add([
      { date: app.utils.dateToYMD(app.now), removable: false }
      { date: null, removable: false }
    ])

  initStop: (item) ->
    index = @collection.indexOf(item)
    prev = @collection.at(index - 1)

    @stops[item.cid] = new app.views.TripsStop(
      list: @stopsEl
      model: item
      minDate: if prev then prev.get('date') else null
    )

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
    @collection.add(date: null, removable: true)

  dateChanged: (model, date) ->
    index = @collection.indexOf(model)
    prev = @collection.at(index - 1)
    next = @collection.at(index + 1)

    if (prev) then @stops[prev.cid].setMaxDate(date)
    if (next) then @stops[next.cid].setMinDate(date)

  adultsChanged: (e) ->
    @model.set('adults', e.target.value)

  budgetChanged: (e) ->
    @model.set('budget', parseInt(e.target.value, 10))

  handleSubmit: (e) ->
    app.e(e)

    @model.save()
)

app.views.SearchForm = SearchForm
