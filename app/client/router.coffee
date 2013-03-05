models = {}
collections = {}
views = {}

Router = Backbone.Router.extend
  _historyLimit: 10
  history: []

  routes:
    '':                          'index'
    'search/:hash':              'search'
    'journey/:hash':             'journey'
    'add_email':                 'addemail'

  initialize: ->
    @on('route', @_manageHistory)

    app.log('[app.Router]: initialize')

  _manageHistory: (rule, params...) ->
    @history.unshift(window.location.href)
    @history.length = _.min [@history.length, @_historyLimit]
      

  index: ->
    app.log('[app.Router]: match "index"')

    if collections['serp_trips']
      collections['serp_trips'].destroy()
      delete collections['serp_trips']

    if collections['selected']
      collections['selected'].destroy()
      delete collections['selected']

    unless views['index']
      models['search'] = new app.models.Search(
        trips   : new app.collections.SearchTrips()
        initial : new app.models.SearchTripsStop()
        final   : new app.models.SearchTripsStop()
      ) unless models['search']

      views['index'] = new app.views.Index(
        model: models['search']
      )

  search: (hash) ->
    app.log('[app.Router]: match "search", hash: "' + hash + '"')

    if collections['serp_trips']
      collections['serp_trips'].destroy()
      delete collections['serp_trips']

    if collections['selected']
      collections['selected'].destroy()
      delete collections['selected']

    if collections['journey']
      collections['journey'].destroy()
      delete collections['journey']

    models['search'] = new app.models.Search(
      trips   : new app.collections.SearchTrips()
      final   : new app.models.SearchTripsStop()
      initial : new app.models.SearchTripsStop()
    )
    
    collections['serp_trips'] = new app.collections.SERPTrips()
    collections['selected']   = new app.collections.SERPTripsSelected()

    if views['serp']
      views['serp'].setup(
        hash: hash
        search: models['search']
        collection: collections['serp_trips']
        selected: collections['selected']
        )
    else       
      views['serp'] = new app.views.SERP(
        hash: hash
        search: models['search']
        collection: collections['serp_trips']
        selected: collections['selected']
      )

  journey: (hash)->
    app.log('[app.Router]: match "journey", hash: "' + hash + '"')

    delete views['index'] if views['index']
    delete views['serp'] if views['serp']

    if collections['serp_trips']
      collections['serp_trips'].destroy()
      delete collections['serp_trips']

    if collections['selected']
      collections['selected'].destroy()
      delete collections['selected']

    if collections['journey']
      collections['journey'].destroy()
      delete collections['journey']

    collections['journey'] = new app.collections.Journey()

    views['journey'] = new app.views.Journey(
      hash: hash
      collection: collections['journey']
    )

  addemail: ->
    app.log('[app.Router]: match "addemail"')

    views['addemail'] = new app.views.AddEmail()

app.Router = Router
