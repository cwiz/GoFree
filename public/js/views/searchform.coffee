SearchForm = Backbone.View.extend(
  initialize: () ->
    @populateCollection() unless @collection.length > 1

    @render()

    @destinations = @$el.find('.v-s-destinations')
    @renderDestinations()

    @collection.on('add', @renderStop, @)
    @collection.on('remove', @unrenderStop, @)

    @$el.find('select.m-input-select').m_inputSelect()
    @$el.find('input.m-input-calendar').m_inputCalendar()

    app.log('[app.views.Trips]: initialize')
    @

  events:
    'click .v-s-d-add'        : 'addStop'
    'click .v-t-s-removestop' : 'removeStop'

  populateCollection: () ->
    today = new Date()
    afterTomorrow = new Date()
    afterTomorrow.setDate(today.getDate() + 2)

    @collection.add([
      { date: app.utils.dateToYMD(today) }
      { date: app.utils.dateToYMD(afterTomorrow) }
    ])

  addStop: (e) ->
    today = new Date()
    @collection.add(date: app.utils.dateToYMD(today))

  removeStop: (e) ->
    index = +$(e.target).parents('.v-t-stop').data('index')
    @collection.remove(@collection.at(index))

  renderStop: (item) ->
    newStop = $(app.templates.trips_stop(item.toJSON()))
    @destinations.append(newStop)
    newStop.find('input.m-input-calendar').m_inputCalendar()

  unrenderStop: (item) ->
    @destinations.find('.v-t-stop[data-index="' + item.get('index') + '"]').remove();

  renderDestinations: () ->
    fragment = ''
    @collection.forEach((model, index, collection)->
      fragment += app.templates.trips_stop(model.toJSON());
      )

    @destinations.html(fragment)

  render: () ->
    @$el.html(app.templates.searchform(@model.toJSON()))

)

app.views.SearchForm = SearchForm
