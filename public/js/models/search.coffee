Search = Backbone.Model.extend(

  initialize: ()->
    console.log('model ready bitchiz')
    @

  sync: ()->
    # socket magic goes here
    @
)

app.models.search = Search
