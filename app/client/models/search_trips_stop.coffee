SearchTripsStop = Backbone.Model.extend
  defaults:
    place:
      name: null
      name_ru: null
      country_name_ru: null
    nearest_airport:
      name: null
    date: null
    label: null
    removable: false
    # signature: null

  initialize: ->
    app.log('[app.models.SearchTripsStop]: initialize')
    return @

app.models.SearchTripsStop = SearchTripsStop
