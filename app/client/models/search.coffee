Search = Backbone.Model.extend
  defaults:
    adults: 1
    budget: 100000
    trips: null

  initialize: ->
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
      trips: new app.collections.SearchTrips(data.trips)
      )

    @trigger('fetched')

  isValid: ->
    valid = true

    iterator = (item) =>
      valid = item.get('place').name

    @get('trips').each(iterator)

    !!valid

  save: ->
    data = _.extend(@toJSON(), trips: @get('trips').toJSON())
    data['hash'] = md5(data)

    @hash = data['hash']

    app.socket.emit('search', data)
    @trigger('save', data)

    app.log('[app.models.Search]: save', data)

app.models.Search = Search
