SearchTripsStop = Backbone.View.extend
  tagName: 'li'
  className: 'v-s-t-stop'

  initialize: (options) ->
    @list = options.list
    @minDate = if options.minDate then options.minDate else null
    @maxDate = if options.maxDate then options.maxDate else null

    @manageKeypress = _.bind(@manageKeypress, @)
    @manageClick = _.bind(@manageClick, @)

    @render()

    @suggestActive = false
    @suggestEl = @$el.find('.v-s-t-s-p-suggestions')
    @placeInput = @$el.find('.v-s-t-s-p-name')
    @suggestSelected = null
    @lastQuery = null

    @calendar = @$el.find('input.m-input-calendar').m_inputCalendar()[0]

    @model.on('change:place', @updatePlaceValue, @)

    @updateCalendar()

    app.log('[app.views.SearchTripsStop]: initialize')
    @

  events:
    'click .v-s-t-s-removestop'                  : 'removeStop'
    'change .m-i-c-input'                      : 'dateChanged'
    # 'input .v-s-t-s-p-name'                    : 'placeChanged'
    'webkitspeechchange .v-s-t-s-p-name'         : 'placeChanged'
    'keyup .v-s-t-s-p-name'                      : 'placeChanged'
    'click .v-s-t-s-p-suggestion'                : 'placeSelected'

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

    if @minDate then @calendar.lockDates(null, @minDate)
    if @maxDate then @calendar.lockDates(@maxDate, null)

  updatePlaceValue: (model, place)->
    @placeInput.val("#{place.name_ru}, #{place.country_name_ru}")

  manageKeypress: (e) ->
    switch e.keyCode
      #up
      when 38, 40
        app.e(e)

        if not @suggestSelected?.length
          @suggestSelected = @suggestEl.find(if e.keyCode == 38 then 'li:last-child' else 'li:first-child')
          @suggestSelected.addClass('selected')
        else
          next = if e.keyCode == 38 then @suggestSelected.prev() else @suggestSelected.next()
          @suggestSelected.removeClass('selected')

          if next.length            
            @suggestSelected = next
            @suggestSelected.addClass('selected')
          else
            @suggestSelected = null

      #enter
      when 13
        app.e(e)

        if @suggestSelected?.length
          place = @suggestions[+@suggestSelected.data('index')]

          @model.set('place', place)

          @suggestSelected = null

          @clearSuggest()

      # when 27
      #   @suggestSelected = null
      #   @clearSuggest()
              

  manageClick: (e) ->
    $target = $(e.target)

    if (@suggestActive and not $target.is(@suggestEl) and not $target.is(@placeInput))
      @clearSuggest()

  placeSelected: (e) ->
    place = @suggestions[+e.target.getAttribute('data-index')]

    @model.set('place', place)

    @clearSuggest()

  renderSuggest: (resp) ->
    @suggestions = resp.value
    
    list = for o, i in @suggestions
      """<li class="v-s-t-s-p-suggestion" data-index="#{i}">
            <strong>#{o.name_ru}</strong>, #{o.country_name_ru}
          </li>"""

    @suggestEl.html(list.join(''))

    if not @suggestActive
      @suggestEl.addClass('active')
      @suggestActive = true

      app.dom.doc.on('keydown', @manageKeypress)
      app.dom.doc.on('click', @manageClick)

    @suggestSelected = null

  # hideSuggest: ->
  #   @suggestEl.removeClass('active');
  #   @suggestActive = false
    
  clearSuggest: ->
    @suggestEl.removeClass('active')
    @suggestActive = false
    @suggestEl.html('')

    app.dom.doc.off('keydown', @manageKeypress);
    app.dom.doc.off('click', @manageClick);

  placeChanged: _.debounce((e) ->
    place = $.trim(e.target.value)
    return unless place.length

    if @model.get('place').name != place and (@lastQuery != place or not @suggestActive)
      $.ajax
        url: app.api.places + place
        success: @renderSuggest
        error: @clearSuggest
        context: @

      @lastQuery = place

  , 100)

  render: ->
    @$el.html(app.templates.search_trips_stop(@model.toJSON()))
    @list.append(@$el)

  removeStop: ->
    @undelegateEvents()

    @calendar.destroy()
    delete @calendar

    @model.trigger('delete', @model)
    @remove()

app.views.SearchTripsStop = SearchTripsStop
