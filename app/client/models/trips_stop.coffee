TripsStop = Backbone.Model.extend(
  defaults:
    place:
      name: null
    date: null
    signature: null

  initialize: ()->
    @on('change', @sign, @)
    app.log('[app.models.TripsStop]: initialize')
    @

  sign: ->
    @set('signature', md5(@toJSON()))

)

app.models.TripsStop = TripsStop
