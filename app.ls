_ 					= require "underscore"
cluster     		= require "cluster"
connect-redis		= require "connect-redis"
express     		= require "express"
http        		= require "http"
os          		= require "os"
passport    		= require "passport"
passport-facebook 	= require "passport-facebook"
passport-vkontakte 	= require "passport-vkontakte"
path        		= require "path"
rack        		= require "asset-rack"
redis       		= require "socket.io/node_modules/redis"
socket      		= require "socket.io"
SocketRedis 		= require "socket.io/lib/stores/redis"

# SETTINGS

FACEBOOK_ID 		= "109097585941390"
FACEBOOK_SECRET		= "48d73a1974d63be2513810339c7dbb3d"

VK_ID				= "3436490"
VK_SECRET			= "uMqrPONr6bxMgxgvL3he"

# GLOBALS

ROLE 		= process.env.NODE_ENV or 'development'
NUM_CPUS 	= if ROLE is 'production' then os.cpus().length else 1


if cluster.isMaster

	_.map [0 to (NUM_CPUS-1)], -> cluster.fork()

	cluster.on 'exit', (worker, code, signal) ->
		console.log "worker #{worker.process.pid} died"
		cluster.fork() if ROLE is 'production'

else

	backEnd     = require "./app/server"
	database	= backEnd.database

	# Globals
	app     	= express()
	server  	= http.createServer app
	io      	= socket.listen server

	# Passport.js
	facebookSettings = 
		clientID    : FACEBOOK_ID
		clientSecret: FACEBOOK_SECRET
		callbackURL : "http://localhost:3000/auth/facebook/callback"

	postLogin = (accessToken, refreshToken, profile, done) ->
		
		(err, user) <- database.users.findOne do
			provider	: profile.provider
			id 			: profile.id
		
		profile.email = profile.emails[0].value if profile.emails

		if (not user or err)
			database.users.insert profile 
			done null, profile if profile

		else
			user.username 		= profile.username
			user.displayName 	= profile.displayName
			user.name 			= profile.name
			user.gender			= profile.gender
			user.emails			= profile.emails
			user.email			= profile.email

			database.users.update {_id: user._id}, user
			done null, user if user
		
	passport.use(new passport-facebook.Strategy(facebookSettings, postLogin))
	
	vkSettings = 
		clientID    : VK_ID
		clientSecret: VK_SECRET
		callbackURL : "http://localhost:3000/auth/vkontakte/callback"

	passport.use(new passport-vkontakte.Strategy(vkSettings, postLogin))

	passport.serializeUser 		(user, done) -> done null, user.id
	
	passport.deserializeUser 	(id,   done) -> 
		(error, user) <- database.users.findOne {id: id}

		if user
			delete user._id 	
			delete user._json	
			delete user._raw	
		
			done error, user 

		else
			done error, false
	  
	# Assets-Rack
	assets = new rack.AssetRack([
		new rack.LessAsset({
			url: "/app.css"
			filename: __dirname + "/public/css/app.less"
			paths	: [__dirname + "/public/css"]
			compress: false
		}), 

		new rack.SnocketsAsset({
			url 	: "/libs.js"
			filename: __dirname + "/app/client/libs.js"
			compress: false
		}), 

		new rack.SnocketsAsset({
			url 	: "/app.js"
			filename: __dirname + "/app/client/app.coffee"
			compress: false
		}), 

		new rack.JadeAsset({
			url 			: "/views.js"
			dirname 	 	: __dirname + "/views/client"
			separator 		: "_"
			clientVariable 	: "app.templates"
			compress		: false
		})
	])

	<- assets.on "complete" 
		
	# Configuration
	app.configure ->
		app.set "port",                 (process.env.PORT or 3000)
		app.set "views",                __dirname + "/views/server"
		app.set "view engine",          "jade"
		
		app.use assets
		app.use express.static          __dirname + "/public"
		app.use express.bodyParser!
		app.use express.methodOverride!
		
		app.use express.cookieParser!

		app.use express.session({ 
			store 	: new (connect-redis(express))
			secret  :'ironmaiden' 
		})

		app.use passport.initialize!
		app.use passport.session!
		app.use express.compress!

		app.use (req, res, next) ->
			app.locals.user = if req.user then req.user else null
			next!

		app.use app.router

		# Locals
		app.locals.pretty  = true
		app.locals.__debug = false

	app.configure "development", ->
		app.use express.errorHandler!
		app.use express.logger "dev"
		app.locals.__debug = true

	# Routes
	
	# --- static
	app.get "/",                            	backEnd.about.index
	app.get "/search/:hash",                	backEnd.about.index
	app.get "/journey/:hash",                	backEnd.about.index
	
	# --- API --- 
	app.get "/api/v2/autocomplete/:query",  	backEnd.api.autocomplete_v2
	app.get "/api/v2/image/:country/:city", 	backEnd.api.image_v2
	app.get "/api/v2/get_location", 			backEnd.api.get_location
	app.get "/api/v2/auth/add_email/:email", 	backEnd.api.add_email

	# --- login	

	login = (provider, req, res) -> 
		req.session.postLoginRedirect = req.header('Referer')
		passport.authenticate(provider, { scope: [ 'email' ]} )(req, res)

	callback = (req, res) ->
		if req.session.postLoginRedirect
			res.redirect req.session.postLoginRedirect
		else
			res.redirect '/#'

	app.get "/auth/facebook", 			(req, res) -> login('facebook', req, res)
	app.get "/auth/facebook/callback", passport.authenticate('facebook'),	callback

	app.get "/auth/vkontakte", 			(req, res) -> login('vkontakte', req, res)
	app.get "/auth/vkontakte/callback", passport.authenticate('vkontakte'), callback
	
	app.get "/auth/logout", (req, res) ->
		req.logout!
		res.redirect '/'

	# --- SocketIO
	io.sockets.on "connection",             backEnd.api.search

	# Stuff
	server.listen app.get("port"), ->
		console.log "Express server listening on port " + app.get("port")

	# --- Socket.IO settings
	redisStore = new SocketRedis do
		redisPub    : redis.createClient()
		redisSub    : redis.createClient()
		redisClient : redis.createClient()

	io.set 'store', redisStore

	io.enable 'browser client minification'
	io.enable 'browser client etag'
	io.enable 'browser client gzip'
	
	io.set    'log level', 1
