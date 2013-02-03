# Dependencies
express = require "express"
backEnd = require "./app/server"
http    = require "http"
socket  = require "socket.io"
path    = require "path"
rack    = require "asset-rack"

# Globals
app     = express()
server  = http.createServer app
#io      = socket.listen server
io      = socket.listen server

# Assets-Rack
assets = new rack.AssetRack([
  new rack.LessAsset({
    url: "/app.css"
    filename: __dirname + "/public/css/app.less"
    paths: [__dirname + "/public/css"]
    compress: false
  }), 

  new rack.SnocketsAsset({
    url: "/libs.js"
    filename: __dirname + "/app/client/libs.js"
    compress: false
  }), 

  new rack.SnocketsAsset({
    url: "/app.js"
    filename: __dirname + "/app/client/app.coffee"
    compress: false
  }), 

  new rack.JadeAsset({
    url: "/views.js"
    dirname: __dirname + "/views/client"
    separator: "_"
    clientVariable: "app.templates"
    compress: false
  })
])

assets.on "complete", ->  
  
  # Configuration
  app.configure ->
    app.set "port",                 (process.env.PORT or 3000)
    app.set "views",                __dirname + "/views/server"
    app.set "view engine",          "jade"
    
    app.use assets
    app.use express.static          __dirname + "/public"
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use app.router
    app.use express.compress()

    app.locals.pretty = true

  app.configure "development", ->
    app.use express.errorHandler()
    app.use express.logger          "dev"

  # Routes
  # --- static
  app.get "/",                            backEnd.about.index
  app.get "/search/:hash",                backEnd.about.index
  app.get "/about",                       backEnd.about.about
  # --- api
  app.get "/api/v1/autocomplete/:query",  backEnd.api.autocomplete
  app.get "/api/v2/autocomplete/:query",  backEnd.api.autocomplete_v2
  app.get "/api/v1/image/:query",         backEnd.api.image
  app.get "/api/v2/image/:country/:city", backEnd.api.image_v2
  # --- socket
  io.sockets.on "connection",             backEnd.api.search

  # Stuff
  server.listen app.get("port"), ->
    console.log "Express server listening on port " + app.get("port")

  io.set        "log level",  1
  
