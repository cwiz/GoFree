Search = Backbone.Model.extend(
  urlRoot: 'search'

  defaults:
    adults: 1
    budget: 100000
    trips: null

  url: 'search'

  initialize: ()->
    app.log('[app.models.Search]: initialize')
    @

  # sync: ()->
  #   # socket magic goes here
  #   @

)

app.models.Search = Search
