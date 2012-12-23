#= require app.utils.js

#= require router.coffee
#= require_tree models
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

app.modules = {}

app.dom.html.removeClass('no-js').addClass('js');
app.dom.html.addClass('opera') if app.browser.isOpera
app.dom.html.addClass('firefox') if app.browser.isFirefox
app.dom.html.addClass('ie ie' + app.browser.isIE) if app.browser.isIE
app.dom.html.addClass('ios ios' + app.browser.isIOS) if app.browser.isIOS
app.dom.html.addClass('android android' + app.browser.isAndroid) if app.browser.isAndroid

router = new app.router()
Backbone.history.start(pushState: true);

@app = app
