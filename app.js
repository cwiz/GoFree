(function(){
  var _, auth, cluster, connectRedis, express, http, os, passport, passportFacebook, passportVkontakte, path, rack, redis, socket, SocketRedis, FACEBOOK_ID, FACEBOOK_SECRET, VK_ID, VK_SECRET, ROLE, NUM_CPUS, backEnd, database, app, server, io, facebookSettings, vkSettings, assets;
  _ = require("underscore");
  auth = require("http-auth");
  cluster = require("cluster");
  cluster = require("cluster");
  connectRedis = require("connect-redis");
  express = require("express");
  http = require("http");
  os = require("os");
  passport = require("passport");
  passportFacebook = require("passport-facebook");
  passportVkontakte = require("passport-vkontakte");
  path = require("path");
  rack = require("asset-rack");
  redis = require("socket.io/node_modules/redis");
  socket = require("socket.io");
  SocketRedis = require("socket.io/lib/stores/redis");
  FACEBOOK_ID = "109097585941390";
  FACEBOOK_SECRET = "48d73a1974d63be2513810339c7dbb3d";
  VK_ID = "3436490";
  VK_SECRET = "uMqrPONr6bxMgxgvL3he";
  ROLE = process.env.NODE_ENV || 'dev';
  NUM_CPUS = ROLE === 'production' ? os.cpus().length : 1;
  if (cluster.isMaster) {
    _.map((function(){
      var i$, to$, results$ = [];
      for (i$ = 0, to$ = NUM_CPUS - 1; i$ <= to$; ++i$) {
        results$.push(i$);
      }
      return results$;
    }()), function(){
      return cluster.fork();
    });
    cluster.on('exit', function(worker, code, signal){
      console.log("worker " + worker.process.pid + " died");
      if (ROLE === 'production') {
        return cluster.fork();
      }
    });
  } else {
    backEnd = require("./app/server");
    database = backEnd.database;
    app = express();
    server = http.createServer(app);
    io = socket.listen(server);
    facebookSettings = {
      clientID: FACEBOOK_ID,
      clientSecret: FACEBOOK_SECRET,
      callbackURL: "http://localhost:3000/auth/facebook/callback"
    };
    passport.use(new passportFacebook.Strategy(facebookSettings, function(accessToken, refreshToken, profile, done){
      return database.users.findOne({
        provider: profile.provider,
        id: profile.id
      }, function(err, user){
        if (!user || err) {
          database.users.insert(profile);
        }
        if (user) {
          return done(null, user);
        }
      });
    }));
    vkSettings = {
      clientID: VK_ID,
      clientSecret: VK_SECRET,
      callbackURL: "http://localhost:3000/auth/vkontakte/callback"
    };
    passport.use(new passportVkontakte.Strategy(vkSettings, function(accessToken, refreshToken, profile, done){
      return database.users.findOne({
        provider: profile.provider,
        id: profile.id
      }, function(err, user){
        if (!user || err) {
          database.users.insert(profile);
        }
        if (user) {
          return done(null, user);
        }
      });
    }));
    passport.serializeUser(function(user, done){
      return done(null, user.id);
    });
    passport.deserializeUser(function(id, done){
      return database.users.findOne({
        id: id
      }, function(error, user){
        if (user) {
          delete user._id;
        }
        if (user) {
          delete user._json;
        }
        if (user) {
          delete user._raw;
        }
        return done(error, user);
      });
    });
    assets = new rack.AssetRack([
      new rack.LessAsset({
        url: "/app.css",
        filename: __dirname + "/public/css/app.less",
        paths: [__dirname + "/public/css"],
        compress: false
      }), new rack.SnocketsAsset({
        url: "/libs.js",
        filename: __dirname + "/app/client/libs.js",
        compress: false
      }), new rack.SnocketsAsset({
        url: "/app.js",
        filename: __dirname + "/app/client/app.coffee",
        compress: false
      }), new rack.JadeAsset({
        url: "/views.js",
        dirname: __dirname + "/views/client",
        separator: "_",
        clientVariable: "app.templates",
        compress: false
      })
    ]);
    assets.on("complete", function(){
      var basic, redisStore;
      app.configure(function(){
        app.set("port", process.env.PORT || 3000);
        app.set("views", __dirname + "/views/server");
        app.set("view engine", "jade");
        app.use(assets);
        app.use(express['static'](__dirname + "/public"));
        app.use(express.bodyParser());
        app.use(express.methodOverride());
        app.use(express.cookieParser());
        app.use(express.session({
          store: new (connectRedis(express)),
          secret: 'ironmaiden'
        }));
        app.use(passport.initialize());
        app.use(passport.session());
        app.use(express.compress());
        app.use(function(req, res, next){
          app.locals.user = req.user ? req.user : null;
          return next();
        });
        app.use(app.router);
        app.locals.pretty = true;
        return app.locals.__debug = false;
      });
      app.configure("development", function(){
        app.use(express.errorHandler());
        app.use(express.logger("dev"));
        return app.locals.__debug = true;
      });
      basic = auth({
        authRealm: "SHTO?",
        authList: ['anus:pes'],
        proxy: false
      });
      app.get("/", function(req, res){
        return basic.apply(req, res, function(username){
          return backEnd.about.index(req, res);
        });
      });
      app.get("/search/:hash", function(req, res){
        return basic.apply(req, res, function(username){
          return backEnd.about.index(req, res);
        });
      });
      app.get("/api/v2/autocomplete/:query", backEnd.api.autocomplete_v2);
      app.get("/api/v2/image/:country/:city", backEnd.api.image_v2);
      app.get("/auth/facebook", function(req, res){
        req.session.postLoginRedirect = req.header('Referer');
        return passport.authenticate('facebook')(req, res);
      });
      app.get("/auth/facebook/callback", passport.authenticate('facebook'), function(req, res){
        if (req.session.postLoginRedirect) {
          return res.redirect(req.session.postLoginRedirect);
        }
      });
      app.get("/auth/vkontakte", function(req, res){
        req.session.postLoginRedirect = req.header('Referer');
        return passport.authenticate('vkontakte')(req, res);
      });
      app.get("/auth/vkontakte/callback", passport.authenticate('vkontakte'), function(req, res){
        if (req.session.postLoginRedirect) {
          return res.redirect(req.session.postLoginRedirect);
        }
      });
      app.get("/auth/logout", function(req, res){
        req.logout();
        return res.redirect('/');
      });
      io.sockets.on("connection", backEnd.api.search);
      server.listen(app.get("port"), function(){
        return console.log("Express server listening on port " + app.get("port"));
      });
      redisStore = new SocketRedis({
        redisPub: redis.createClient(),
        redisSub: redis.createClient(),
        redisClient: redis.createClient()
      });
      io.set('store', redisStore);
      io.enable('browser client minification');
      io.enable('browser client etag');
      io.enable('browser client gzip');
      return io.set('log level', 1);
    });
  }
}).call(this);
