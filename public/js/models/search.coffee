Search = Backbone.Model.extend(
  defaults:
    adults: 1
    children: 0
    budget: 100000

  initialize: ()->
    console.log('model ready bitchiz')
    @

  sync: ()->
    # socket magic goes here
    @
)

app.models.search = Search
