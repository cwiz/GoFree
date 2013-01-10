TripsStop = Backbone.Model.extend(
  defaults:
    place:
      name: null
    date: null

  initialize: ()->
    app.log('[app.models.TripsStop]: initialize')
    @

  # sync: ()->
  #   # socket magic goes here
  #   @

)

app.models.TripsStop = TripsStop
