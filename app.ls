# Dependencies
auth        = require "http-auth"
backEnd     = require "./app/server"
cluster     = require "cluster"
express     = require "express"
http        = require "http"
os          = require "os"
path        = require "path"
rack        = require "asset-rack"
redis       = require "socket.io/node_modules/redis"
RedisStore  = require "socket.io/lib/stores/redis"
socket      = require "socket.io"

numCPUs = os.cpus().length
 
if cluster.isMaster
  
  processNumber = 0
  while processNumber < numCPUs
    cluster.fork()
    processNumber += 1
  
  cluster.on 'exit', (worker, code, signal) ->
    console.log "worker #{worker.process.pid} died"
    cluster.fork()

else
  # Globals
  app     = express()
  server  = http.createServer app
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
      app.locals.__debug = false

    app.configure "development", ->
      app.use express.errorHandler()
      app.use express.logger          "dev"
      app.locals.__debug = true

    # Routes

    # --- auth

    basic = auth({
      authRealm : "SHTO?",
      authList  : ['anus:pes'],
      proxy     : false
    })
    
    # --- static
    app.get "/",                            (req, res) -> basic.apply req, res, (username) -> backEnd.about.index req, res
    app.get "/search/:hash",                (req, res) -> basic.apply req, res, (username) -> backEnd.about.index req, res
    
    # --- api
    app.get "/api/v2/autocomplete/:query",  backEnd.api.autocomplete_v2
    app.get "/api/v2/image/:country/:city", backEnd.api.image_v2
    
    # --- socket
    io.sockets.on "connection",             backEnd.api.search

    # Stuff
    server.listen app.get("port"), ->
      console.log "Express server listening on port " + app.get("port")

    # --- Socket.IO settings

    pub    = redis.createClient()
    sub    = redis.createClient()
    client = redis.createClient()

    io.set 'store', new RedisStore({
      redisPub    : pub,
      redisSub    : sub,
      redisClient : client,
    })

    io.enable 'browser client minification'
    io.enable 'browser client etag'
    io.enable 'browser client gzip'
    io.set    'log level', 1
