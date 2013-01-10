Search = Backbone.Model.extend(
  urlRoot: 'search'

  defaults:
    adults: 1
    budget: 100000
    trips: null

    signature: _.uniqueId('search_')

  url: 'search'

  initialize: ()->
    app.log('[app.models.Search]: initialize')
    @

  sync: ()->
    # socket magic goes here
    data = _.extend(@toJSON(), trips: @get('trips').toJSON())

    app.socket.emit('search', data)

    app.log('[app.models.Search]: emit', data)
    @

)

app.models.Search = Search
