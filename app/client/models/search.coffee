Search = Backbone.Model.extend
  defaults:
    adults: 1
    budget: 100000

    trips: null
    hash: null

  initialize: ->
    app.log('[app.models.Search]: initialize')

  observe: ->
    app.socket.on('search_started', _.bind(@fetched, @))
    app.log('[app.models.Search]: observing')

  setHash: (hash) ->
    @set('hash', hash)
    @

  fetched: (resp) ->
    return unless resp.form.hash == @get('hash')

    data = resp.form

    @set(
      adults: data.adults
      budget: data.budget
      trips: @get('trips').reset(data.trips)
    )

    app.log('[app.models.Search]: fetched', data)
    @trigger('fetched', data)

  isValid: ->
    valid = true

    iterator = (item) =>
      valid = item.get('place').name

    @get('trips').each(iterator)

    !!valid

  serialize: ->
    _.extend(@toJSON(), trips: @get('trips').toJSON())

  save: ->
    data = @serialize()
    @set('hash', data['hash'] = md5(JSON.stringify(data)))

    app.socket.emit('search', data)
    @trigger('save', data)

    app.log('[app.models.Search]: save', data)

  destroy: ->
    app.socket.removeAllListeners('search_started')
    @clear()
    app.log('[app.models.Search]: destroyed')

app.models.Search = Search
