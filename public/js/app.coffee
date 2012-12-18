console.log 'LIVE'

# FIXME: rewrite this as a normal app when start with JS fo real
app.init = ->
  $('#page-index .block-current').html(app.templates.searchform())

app.init();
