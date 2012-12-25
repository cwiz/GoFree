Search = Backbone.Model.extend(
  defaults:
    from: ''
    from_id: ''

    to: ''
    to_id: ''

    departure: ''
    arrival: ''

  initialize: ()->
    app.log('[app.models.Trip]: initialize')
    @

  sync: ()->
    # socket magic goes here
    @
)

app.models.Trip = Trip
