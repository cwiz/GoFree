TripsStop = Backbone.View.extend
  tagName: 'li'
  className: 'v-t-stop'

  initialize: (options) ->
    @list = options.list
    @minDate = if options.minDate then options.minDate else null
    @maxDate = if options.maxDate then options.maxDate else null

    @render()

    @suggestEl = @$el.find('.v-t-s-p-suggestions')
    @placeInput = @$el.find('.v-t-s-p-name')

    @calendar = @$el.find('input.m-input-calendar').m_inputCalendar()[0]

    @updateCalendar()

    window.test = @calendar

    app.log('[app.views.TripsStop]: initialize')
    @

  events:
    'click .v-t-s-removestop'                  : 'removeStop'
    'change .m-i-c-input'                      : 'dateChanged'
    # 'input .v-t-s-p-name'                    : 'placeChanged'
    'webkitspeechchange .v-t-s-p-name'         : 'placeChanged'
    'keyup .v-t-s-p-name'                      : 'placeChanged'
    'click .v-t-s-p-suggestion'                : 'placeSelected'

  dateChanged: (e) ->
    @model.set('date', e.target.value)

  setMinDate: (date) ->
    @minDate = date
    @updateCalendar()

  setMaxDate: (date) ->
    @maxDate = date
    @updateCalendar()

  updateCalendar: () ->
    @calendar.unlockDates()

    if @minDate then @calendar.lockDates(null, @minDate)
    if @maxDate then @calendar.lockDates(@maxDate, null)

  placeSelected: (e) ->
    place = @suggestions[+e.target.getAttribute('index')]

    @model.set('place', place)
    @placeInput.val(place.name)

    # так?
    $.ajax {
      url     :  app.api.images + place.name
      success : (resp) ->
        # how to access searchform variable?

        # pre-fetch image #@todo: refactor to utils
        img = new Image()
        img.src = resp.value.image
        img.onload = () -> 
            $('.bg').css('background-image', "url('#{resp.value.image}')")    
    }

    @clearSuggest()

  renderSuggest: (resp) ->
    @suggestions = resp.value
    
    list = for o, i in @suggestions
      '<li class="v-t-s-p-suggestion" data-index="' + i + '"">' + o.name + '</li>'

    @suggestEl.html(list.join(''))
    @suggestEl.addClass('active')
    
  clearSuggest: () ->
    @suggestEl.removeClass('active');
    @suggestEl.html('')

  placeChanged: _.debounce((e) ->
    place = $.trim(e.target.value)

    $.ajax
      url: app.api.places + place
      success: @renderSuggest
      error: @clearSuggest
      context: @

  , 100)

  render: () ->
    @$el.html(app.templates.trips_stop(@model.toJSON()))
    @list.append(@$el)

  removeStop: () ->
    @undelegateEvents()

    @calendar.destroy()
    delete @calendar

    @model.trigger('delete', @model)
    @remove()


app.views.TripsStop = TripsStop
