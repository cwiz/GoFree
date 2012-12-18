# Dependencies
express = require("express")
routes  = require("./server")
http    = require("http")
socket  = require("socket.io")
path    = require("path")
rack    = require("asset-rack")

# Globals
app     = express()
server  = http.createServer(app)
io      = socket.listen(server)

# Assets-Rack
assets = new rack.AssetRack([
  new rack.LessAsset(
    url:            "/app.css"
    filename:       __dirname + "/public/css/app.less"
    paths:          [__dirname + "/public/css/includes", __dirname + "/public/css/lib", __dirname + "/public/css/"]
    compress:       false
  ), 
  new rack.BrowserifyAsset(
    url:            "/app.js"
    filename:       __dirname + "/public/js/app.coffee"
    compress:       false
  ), 
  new rack.JadeAsset(
    url:            "/views.js"
    dirname:        __dirname + "/public/views"
    separator:      "_"
    clientVariable: "app.templates"
    compress:       false)
  ]
)

assets.on "complete", ->
 
  # Configuration
  app.configure ->
    # configuration
    app.set       "port", process.env.PORT or 3000
    app.set       "views", __dirname + "/views"
    app.set       "view engine", "jade"
    app.locals.pretty = true
    
    # middleware
    app.use       assets
    app.use       express.static(__dirname + "/public/assets")
    app.use       express.bodyParser()
    app.use       express.methodOverride()
    app.use       app.router
    app.use       express.compress()

  # Development environment
  app.configure "development", ->
    app.use express.errorHandler()
    app.use express.logger("dev")

  # Routes
  app.get "/", routes.index
  app.get "/about", routes.about
  app.get "/api/v1/autocomplete/:query", routes.autocomplete
  app.get "/api/v1/image/:query", routes.image
  
  # Stuff
  server.listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")

  # Socket.io
  io.set "log level", 0
  io.sockets.on "connection", routes.search