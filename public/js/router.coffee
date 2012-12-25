Router = Backbone.Router.extend(
  routes:
    '':                     'index'

  index: () ->
    new app.views.Index({
      model: new app.models.Search
    })
)

app.Router = Router
