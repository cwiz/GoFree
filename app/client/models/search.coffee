Search = Backbone.Model.extend
  hash: null

  defaults:
    adults: 1
    budget: 100000
    trips: null

  initialize: ->
    app.socket.on('search_started', _.bind(@fetched, @))

    app.log('[app.models.Search]: initialize')

  fetched: (resp) ->
    return unless resp.form.hash == @hash

    data = resp.form

    @set(
      adults: data.adults
      budget: data.budget
      trips: new app.collections.SearchTrips(data.trips)
    )

    @trigger('fetched', data)
    app.log('[app.models.Search]: fetched', data)

  isValid: ->
    valid = true

    iterator = (item) =>
      valid = item.get('place').name

    @get('trips').each(iterator)

    !!valid

  save: ->
    data = _.extend(@toJSON(), trips: @get('trips').toJSON())
    @hash = data['hash'] = md5(data)

    app.socket.emit('search', data)
    @trigger('save', data)

    app.log('[app.models.Search]: save', data)

app.models.Search = Search
