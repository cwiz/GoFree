SearchTripsStop = Backbone.View.extend
  tagName: 'li'
  className: 'v-s-t-stop'

  initialize: (options) ->

    @list = options.list
    @render()

    @autocomplete = new app.views.SearchPlaceAutocomplete 
      el        : @$el.find '.place'
      model     : @model
      dependant : @$el.find '.vs-final-place'

    @calendar     = new app.views.SearchPlaceCalendar 
      el        : @$el.find '.date'
      model     : @model
      minDate   : if options.minDate then options.minDate else null
      maxDate   : if options.maxDate then options.maxDate else null

    app.log('[app.views.SearchTripsStop]: initialize')
    return @

  render: ->    
    @$el.html(app.templates.search_trips_stop(@model.toJSON()))
    @list.append(@$el)

  removeStop: ->
    @undelegateEvents()
    @calendar.destroy()
    delete @calendar

    @autocomplete.destroy()
    delete @autocomplete

    @model.trigger('delete', @model)
    @remove()

app.views.SearchTripsStop = SearchTripsStop
