TripsStop = Backbone.Model.extend(
  defaults:
    place_name: null
    place_id: null

    date: app.utils.dateToYMD(app.now)

    index: 0

  initialize: ()->
    app.log('[app.models.TripsStop]: initialize')
    @

  # sync: ()->
  #   # socket magic goes here
  #   @

)

app.models.TripsStop = TripsStop
