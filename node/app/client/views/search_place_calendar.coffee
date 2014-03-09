SearchPlaceCalendar= Backbone.View.extend
  tagName: 'li'
  className: 'v-s-t-stop'

  initialize: (options) ->

    @minDate = if options.minDate then options.minDate else null
    @maxDate = if options.maxDate then options.maxDate else null

    @render()
    
    @calendar = @$el.find('input.m-input-calendar').m_inputCalendar()[0]
    @updateCalendar()

    app.log('[app.views.SearchPlaceCalendar]: initialize')
    return @

  events:
    'change .m-i-c-input' : 'dateChanged'

  dateChanged: (e) ->
    @model.set('date', e.target.value)
    @$el.find('.v-s-t-s-date').find('.m-validate-error').remove()

  setMinDate: (date) ->
    @minDate = date
    @updateCalendar()

  setMaxDate: (date) ->
    @maxDate = date
    @updateCalendar()

  updateCalendar: ->
    @calendar.unlockDates()

    console.log('----');
    console.log(@minDate);
    console.log(@maxDate);
    console.log('----');

    if @minDate
      @calendar.lockDates(null, @minDate)
    
    if @maxDate
      @calendar.lockDates(@maxDate, null)

  render: ->
    @$el.html(app.templates.search_place_calendar(@model.toJSON()))

app.views.SearchPlaceCalendar = SearchPlaceCalendar
