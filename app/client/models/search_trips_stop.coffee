SearchTripsStop = Backbone.Model.extend
  defaults:
    place:
      name: null
      name_ru: null
      country_name_ru: null
    nearest_airport:
      name: null
    date: null
    # signature: null

  initialize: ->
    # @on('change', @sign, @)
    app.log('[app.models.SearchTripsStop]: initialize')
    @

  # sign: ->
  #   @set('signature', md5(JSON.stringify(@toJSON())))

app.models.SearchTripsStop = SearchTripsStop
