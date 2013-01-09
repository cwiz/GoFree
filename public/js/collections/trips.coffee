Trips = Backbone.Collection.extend(
  model: app.models.TripsStop

  initialize: ()->
    @on('add', @handleAdd)
    app.log('[app.collections.Trips]: initialize')

  handleAdd: (item)->
    item.set('index', _.indexOf(@models, item))
  
)

app.collections.Trips = Trips
