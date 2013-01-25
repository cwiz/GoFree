SearchTripsStop = Backbone.Model.extend
  defaults:
    place:
      name: null
    date: null
    # signature: null

  initialize: ->
    # @on('change', @sign, @)
    app.log('[app.models.SearchTripsStop]: initialize')
    @

  # sign: ->
  #   @set('signature', md5(@toJSON()))

app.models.SearchTripsStop = SearchTripsStop
