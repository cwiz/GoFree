cluster     = require "cluster"

numCPUs = process.env.PROCESSES or 1
 
if cluster.isMaster
	
	processNumber = 0
	while processNumber < numCPUs
		cluster.fork()
		processNumber += 1
	
	cluster.on 'exit', (worker, code, signal) ->
		console.log "worker #{worker.process.pid} died"
		cluster.fork()

else

	auth        = require "http-auth"
	backEnd     = require "./app/server"
	cluster     = require "cluster"
	express     = require "express"
	http        = require "http"
	os          = require "os"
	passport    = require "passport"
	path        = require "path"
	rack        = require "asset-rack"
	redis       = require "socket.io/node_modules/redis"
	RedisStore  = require "socket.io/lib/stores/redis"
	socket      = require "socket.io"
	
	database		= backEnd.database

	# Globals
	app     = express()
	server  = http.createServer app
	io      = socket.listen server

	# Redis
	pub    = redis.createClient()
	sub    = redis.createClient()
	client = redis.createClient()

	redisStore =  new RedisStore({
		redisPub    : pub,
		redisSub    : sub,
		redisClient : client,
	})

	# Passport.js
	FacebookStrategy = require("passport-facebook").Strategy
	app.locals.user = null
	passport.use new FacebookStrategy(
		{
			clientID    : "109097585941390",
			clientSecret: "48d73a1974d63be2513810339c7dbb3d",
			callbackURL : "http://localhost:3000/auth/facebook/callback"
		},
		(accessToken, refreshToken, profile, done) ->

			(err, user) <- database.users.findOne {
				provider: profile.provider, 
				id 			: profile.id
			}

			database.users.insert profile if not user

			done null, user if user
	)

	passport.serializeUser 		(user, done) 	-> done null, user.id
	passport.deserializeUser 	(id, done) 		-> 
		(error, user) <- database.users.findOne {id: id}
		app.locals.user = user
		done error, user
	  
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
			
			app.use express.cookieParser()

			_RedisStore = require('connect-redis')(express)
			sessionStore = new _RedisStore; 

			app.use express.session({ 
				store 	: sessionStore
				secret  :'ironmaiden' 
			})

			app.use passport.initialize!
			app.use passport.session!
			app.use express.compress!

			app.use app.router

			app.locals.pretty = true
			app.locals.__debug = false

		app.configure "development", ->
			app.use express.errorHandler()
			app.use express.logger          "dev"
			app.locals.__debug = true

		# --- auth
		basic = auth({
			authRealm : "SHTO?",
			authList  : ['anus:pes'],
			proxy     : false
		})

		# Routes
		
		# --- static
		app.get "/",                            (req, res) -> basic.apply req, res, (username) -> backEnd.about.index req, res
		app.get "/search/:hash",                (req, res) -> basic.apply req, res, (username) -> backEnd.about.index req, res
		
		# --- api
		app.get "/api/v2/autocomplete/:query",  backEnd.api.autocomplete_v2
		app.get "/api/v2/image/:country/:city", backEnd.api.image_v2

		# --- login
		app.get "/auth/login/",                 backEnd.auth.login
		app.get "/auth/facebook",               passport.authenticate('facebook')
		app.get('/auth/facebook/callback',  		passport.authenticate('facebook', 		{ successRedirect: '/', failureRedirect: '/login' }))
		
		# --- socket
		io.sockets.on "connection",             backEnd.api.search

		# Stuff
		server.listen app.get("port"), ->
			console.log "Express server listening on port " + app.get("port")

		# --- Socket.IO settings

		pub    = redis.createClient()
		sub    = redis.createClient()
		client = redis.createClient()

		io.set 'store', redisStore

		io.enable 'browser client minification'
		io.enable 'browser client etag'
		io.enable 'browser client gzip'
		io.set    'log level', 1
