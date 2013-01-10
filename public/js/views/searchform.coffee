SearchForm = Backbone.View.extend(
  stops: {}

  initialize: () ->
    @render()

    @stopsEl = @$el.find('.v-s-destinations')

    @collection.on('add', @initStop, @)
    @collection.on('destroy', @destroyStop, @)

    @$el.find('select.m-input-select').m_inputSelect()

    @today = app.utils.pureDate(app.now)
    @lastDate = app.utils.pureDate(app.now)

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

  addStop: (e) ->
    @lastDate.setDate(@lastDate.getDate() + 2)
    @collection.add(date: app.utils.dateToYMD(@lastDate), removable: true)

  adultsChanged: (e) ->
    @model.set('adults', e.target.value)

  budgetChanged: (e) ->
    @model.set('budget', parseInt(e.target.value, 10))

  handleSubmit: (e) ->
    app.e(e)

    @model.save()

  populateCollection: () ->
    @lastDate.setDate(@lastDate.getDate() + 2)

    @collection.add([
      { date: app.utils.dateToYMD(@today), removable: false }
      { date: app.utils.dateToYMD(@lastDate), removable: false }
    ])

  initStop: (item) ->
    @stops[item.cid] = new app.views.TripsStop(
      list: @stopsEl
      model: item
    )

  destroyStop: (item) ->
    if (+app.utils.YMDToDate(item.get('date')) == +@lastDate)
      @lastDate.setDate(@lastDate.getDate() - 2)

    @collection.remove(item)
    delete @stops[item.cid]
)

app.views.SearchForm = SearchForm
