SearchForm = Backbone.View.extend(
  initialize: () ->
    @today = app.utils.pureDate(app.now)
    @lastDate = app.utils.pureDate(app.now)

    @populateCollection() unless @collection.length > 1

    @render()

    @destinations = @$el.find('.v-s-destinations')
    @renderDestinations()

    @collection.on('add', @renderStop, @)
    # @collection.on('remove', @unrenderStop, @)

    @$el.find('select.m-input-select').m_inputSelect()
    @$el.find('input.m-input-calendar').m_inputCalendar()

    app.log('[app.views.Trips]: initialize')
    @

  events:
    'click .v-s-d-add'        : 'addStop'
    'click .v-t-s-removestop' : 'removeStop'

  populateCollection: () ->
    @lastDate.setDate(@lastDate.getDate() + 2)

    @collection.add([
      { date: app.utils.dateToYMD(@today) }
      { date: app.utils.dateToYMD(@lastDate) }
    ])

  addStop: (e) ->
    @lastDate.setDate(@lastDate.getDate() + 2)
    @collection.add(date: app.utils.dateToYMD(@lastDate))

  removeStop: (e) ->
    stop = $(e.target).parents('.v-t-stop')
    item = @collection.get(stop.data('id'))

    if (+app.utils.YMDToDate(item.get('date')) == +@lastDate)
      @lastDate.setDate(@lastDate.getDate() - 2)

    @collection.remove(item)
    stop.remove()

  renderStop: (item) ->
    newStop = $(app.templates.trips_stop(_.extend(item.toJSON(), id: item.cid, removable: true)))
    @destinations.append(newStop)
    newStop.find('input.m-input-calendar').m_inputCalendar()

  renderDestinations: () ->
    fragment = ''
    @collection.forEach((model, index, collection)->
      fragment += app.templates.trips_stop(_.extend(model.toJSON(), id: model.cid, removable: false))
      )

    @destinations.html(fragment)

  render: () ->
    @$el.html(app.templates.searchform(@model.toJSON()))

)

app.views.SearchForm = SearchForm
