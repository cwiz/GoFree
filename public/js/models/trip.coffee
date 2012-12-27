Trip = Backbone.Model.extend(
  defaults:
    from:
      name: ''
      id: 0
    to:
      name: ''
      id: 0

    departure: ''
    arrival: ''
    index: 0

  initialize: ()->
    app.log('[app.models.Trip]: initialize')
    @
)

app.models.Trip = Trip
