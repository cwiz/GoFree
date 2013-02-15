#= require app.utils.js

#= require_tree modules

#= require router.coffee
#= require_tree models
#= require_tree collections
#= require_tree views

app = _.extend(@app, Backbone.Events)

# Precached DOM elements
app.dom = {}
app.dom.win = $(window)
app.dom.doc = $(document)
app.dom.html = $('html')
app.dom.body = $('body')
app.dom.header = $('#l-header')
app.dom.content = $('#l-content')

app.size =
  width: app.dom.win.width()
  height: app.dom.win.height()

app.dom.win.on('resize', -> 
  app.size.width = app.dom.win.width()
  app.size.height = app.dom.win.height()
  app.trigger('resize')
  )

app.dom.html.removeClass('no-js').addClass('js')
app.dom.html.addClass('opera')                                   if app.browser.isOpera
app.dom.html.addClass('firefox')                                 if app.browser.isFirefox
app.dom.html.addClass('ie ie' + app.browser.isIE)                if app.browser.isIE
app.dom.html.addClass('ios ios' + app.browser.isIOS)             if app.browser.isIOS
app.dom.html.addClass('android android' + app.browser.isAndroid) if app.browser.isAndroid

app.socket = io.connect(app.api.root)
app.overlay = new app.modules.Overlay()
app.router = new app.Router()
Backbone.history.start(pushState: true)

@app = app
