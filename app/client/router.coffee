models = {}
collections = {}
views = {}

Router = Backbone.Router.extend(
  routes:
    '':                          'index'
    'search/:hash':              'search'

  index: () ->
    if views['index']
      views['index'].showForm()
    else
      views['index'] = new app.views.Index(
        model: new app.models.Search(trips: new app.collections.Trips())
      )

    app.log('[app.Router.index]: match')

  search: (hash) ->
    if views['serp']
      views['serp'].showSERP()
    else
      views['serp'] = new app.views.SERP(
        hash: hash
        params: new app.models.Search()
      )

    app.log('[app.Router.search]: match, hash: ' + hash)
)

app.Router = Router
