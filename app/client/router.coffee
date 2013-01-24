models = {}
collections = {}
views = {}

Router = Backbone.Router.extend(
  routes:
    '':                          'index'
    'search/:hash':              'search'

  index: ->
    if views['index']
      views['index'].showForm()
    else
      models['search'] = new app.models.Search(trips: new app.collections.SearchTrips())
      views['index'] = new app.views.Index(
        model: models['search']
      )

    app.log('[app.Router.index]: match')

  search: (hash) ->
    if views['serp']
      views['serp'].showSERP()
    else
      models['search'] = new app.models.Search() unless models['search']
      views['serp'] = new app.views.SERP(
        hash: hash
        params: models['search']
      )

    app.log('[app.Router.search]: match, hash: ' + hash)
)

app.Router = Router
