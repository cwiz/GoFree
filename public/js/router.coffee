Router = Backbone.Router.extend(
  routes:
    '':                     'index'
    'search':               'search'

  index: () ->
    app.log('[app.Router.index]: match')
    new app.views.Index(
      model: new app.models.Search(trips: new app.collections.Trips())
    )
  search: () ->
    app.log('[app.Router.search]: match')
)

app.Router = Router
