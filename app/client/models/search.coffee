Search = Backbone.Model.extend
  defaults:
    adults        : 2
    budget        : 100000

    initial       : null
    final         : null
   
    trips         : null
    hash          : null

  initialize: ->
    app.log('[app.models.Search]: initialize')

  observe: ->
    app.socket.on('search_started', _.bind(@fetched, @))
    app.log('[app.models.Search]: observing')

  setHash: (hash) ->
    @set('hash', hash)
    return @

  fetched: (resp) ->
    return unless resp.form.hash is @get('hash')

    data = resp.form

    @set(
      adults  : data.adults
      budget  : data.budget
      trips   : @get('trips').reset(data.originalForm.trips)
      initial : new app.models.SearchTripsStop data.originalForm.initial
      final   : new app.models.SearchTripsStop data.originalForm.final
    )

    app.log('[app.models.Search]: fetched', data)
    @trigger('fetched', data)

  isValid: ->
    valid = true

    @get('trips').each (item) ->
      valid = valid and item.get('place').name
      valid = valid and item.get('date')

    valid = valid and @get('initial').get('place').name
    valid = valid and @get('final'  ).get('date')

    !!valid

  serialize: ->
    json = @toJSON()
    trips = @get('trips').toJSON()

    originalForm = 
      trips   : _.clone @get('trips').toJSON()
      initial : _.clone @get('initial').toJSON()
      final   : _.clone @get('final').toJSON()

    trips.unshift 
      place : @get('initial').get('place')
      date  : trips[0].date

    for tripNumber in [1..trips.length-1]
      if (tripNumber + 1) is trips.length
        date = @get('final').get('date')
      else
        date = trips[tripNumber+1].date

      trips[tripNumber].date = date

    _.extend @toJSON(), 
      trips         : trips
      originalForm  : originalForm

  preSave: ->
    data = @serialize()
    @set('hash', data['hash'] = md5(JSON.stringify(data)))

    app.socket.emit('pre_search', data)
    @trigger('pre_save', data)

    app.log('[app.models.Search]: pre_save', data)

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
