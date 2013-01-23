Search = Backbone.Model.extend
  defaults:
    adults: 1
    budget: 100000
    trips: null

  initialize: ()->
    app.log('[app.models.Search]: initialize')

  fetch: (@hash)->
    return unless @hash

    app.socket.on('search_started', _.bind(@fetched, @))
    app.socket.emit('search_start', @hash)

  fetched: (data)->
    return unless data.hash == @hash

    @set(
      adults: data.adults
      budget: data.budget
      trips: new app.collections.Trips(data.trips)
      )

    @trigger('fetched')

  save: ()->
    data = _.extend(@toJSON(), trips: @get('trips').toJSON())
    @hash = md5(data)

    data['hash'] = @hash

    app.socket.emit('search', data)
    @trigger('save')
    
    app.log('[app.models.Search]: save', data)

app.models.Search = Search
