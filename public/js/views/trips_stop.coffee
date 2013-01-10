TripsStop = Backbone.View.extend(
  tagName: 'li'
  className: 'v-t-stop'

  initialize: (options) ->
    @list = options.list
    @render()

    @calendar = @$el.find('input.m-input-calendar').m_inputCalendar()

    app.log('[app.views.TripsStop]: initialize')
    @

  events:
    'click .v-t-s-removestop' : 'removeStop'

  render: () ->
    @$el.html(app.templates.trips_stop(@model.toJSON()))
    @list.append(@$el)

  removeStop: () ->
    @model.trigger('destroy', @model)
    @undelegateEvents()
    @remove()
)

app.views.TripsStop = TripsStop
