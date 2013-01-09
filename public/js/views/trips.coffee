Trips = Backbone.View.extend(
  el: '#page-index .v-s-destinations'
  initialize: () ->
    @populateCollection() unless @collection.length > 1

    @render()
    app.log('[app.views.Trips]: initialize')
    @

  populateCollection: () ->
    today = new Date()
    afterTomorrow = new Date()
    afterTomorrow.setDate(today.getDate() + 2)

    @collection.add([
      { date: app.utils.dateToYMD(today) }
      { date: app.utils.dateToYMD(afterTomorrow) }
    ])

  render: () ->
    fragment = ''
    @collection.forEach((model, index, collection)->
      fragment += app.templates.trips_stop(model.toJSON());
      )

    @$el.html(fragment)
    @$el.find('.m-input-calendar').m_inputCalendar();
    @
)

app.views.Trips = Trips
