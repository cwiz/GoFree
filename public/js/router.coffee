Router = Backbone.Router.extend(
  routes:
    '':                     'index'

  index: () ->
    new app.views.index({
      model: new app.models.search
    })
)

app.router = Router
