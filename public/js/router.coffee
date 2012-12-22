Router = Backbone.Router.extend(
  routes:
    '':                     'index'

  index: () ->
    new app.views.index()
)

app.router = Router
