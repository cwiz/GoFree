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
    if views['index']
      views['index'].showForm()
    else
      models['search'] = new app.models.Search(trips: new app.collections.SearchTrips()) unless models['search']

      views['index'] = new app.views.Index(
        model: models['search']
      )

    app.log('[app.Router]: match "index"')

  search: (hash) ->
    if views['serp']
      views['serp'].showSERP()
    else
      models['search'] = new app.models.Search()
      views['serp'] = new app.views.SERP(
        hash: hash
        search: models['search']
        collection: new app.collections.SERPTrips()
      )

    app.log('[app.Router]: match "search", hash: "' + hash + '"')

app.Router = Router
