Trip = Backbone.Model.extend(
  defaults:
    from_name: ''
    from_id: 0

    to_name: ''
    to_id: 0

    departure: ''
    arrival: ''
    index: 0

  initialize: ()->
    app.log('[app.models.Trip]: initialize')
    @

  # sync: ()->
  #   # socket magic goes here
  #   @
)

app.models.Trip = Trip
