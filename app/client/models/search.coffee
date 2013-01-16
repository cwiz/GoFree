Search = Backbone.Model.extend
  defaults:
    adults    : 1
    budget    : 100000
    trips     : null
    signature : null

  initialize: ()->
    app.log('[app.models.Search]: initialize')

  sync: ()->    
    data = _.extend(@toJSON(), trips: @get('trips').toJSON())
    app.socket.emit('start_search', data)
    
    app.log('[app.models.Search]: emit', data)

app.models.Search = Search
