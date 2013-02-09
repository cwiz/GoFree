models = {}
collections = {}
views = {}

Router = Backbone.Router.extend
  _historyLimit: 10
  history: []

  routes:
    '':                          'index'
    'search/:hash':              'search'

  initialize: ->
    @on('all', @_manageHistory)

    app.log('[app.Router]: initialize')

  _manageHistory: (rule, params...) ->
    # if (rule.indexOf('route') > - 1)

    @history.unshift(window.location.href)

    if @history.length > @_historyLimit
      @history.length = @_historyLimit

  index: ->
    app.log('[app.Router]: match "index"')

    if views['index']
      views['index'].showForm()
    else
      models['search'] = new app.models.Search(trips: new app.collections.SearchTrips()) unless models['search']

      views['index'] = new app.views.Index(
        model: models['search']
      )

  search: (hash) ->
    app.log('[app.Router]: match "search", hash: "' + hash + '"')

    if views['serp'] and views['serp'].hash is hash
      views['serp'].showSERP()
    else
      models['search'] = new app.models.Search()

      if views['serp']
        views['serp'].setup(
          hash: hash
          search: models['search']
          collection: new app.collections.SERPTrips()
          selected: new app.collections.SERPTripsSelected()
          )
      else       
        views['serp'] = new app.views.SERP(
          hash: hash
          search: models['search']
          collection: new app.collections.SERPTrips()
          selected: new app.collections.SERPTripsSelected()
        )

app.Router = Router
