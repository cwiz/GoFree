Search = Backbone.Model.extend(
  urlRoot: 'search'

  defaults:
    adults: 1
    children: 0
    budget: 100000
    trips: null

  initialize: ()->
    app.log('[app.models.Search]: initialize')
    @
)

app.models.Search = Search
