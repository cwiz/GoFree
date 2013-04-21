(function(){
  var _, cluster, connectRedis, express, http, os, passport, passportFacebook, passportVkontakte, path, rack, redis, socket, SocketRedis, SocketSession, expressPhantom, FACEBOOK_ID, FACEBOOK_SECRET, VK_ID, VK_SECRET, SECRET, ROLE, NUM_CPUS, DOMAIN, PORT, SITE_URL, backEnd, database, app, server, io, facebookSettings, postLogin, vkSettings, assets;
  _ = require("underscore");
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
  SocketSession = require("session.socket.io");
  expressPhantom = require("express-phantom");
  FACEBOOK_ID = "109097585941390";
  FACEBOOK_SECRET = "48d73a1974d63be2513810339c7dbb3d";
  VK_ID = "3436490";
  VK_SECRET = "uMqrPONr6bxMgxgvL3he";
  SECRET = 'ironmaiden';
  ROLE = process.env.NODE_ENV || 'development';
  NUM_CPUS = ROLE === 'production' ? os.cpus().length : 1;
  DOMAIN = ROLE === 'production' ? 'gofree.ru' : 'localhost';
  PORT = ROLE === 'production' ? 80 : 3000;
  PORT = process.env.PORT || PORT;
  SITE_URL = ROLE === 'production'
    ? DOMAIN
    : DOMAIN + ":" + PORT;
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
      } else {
        return process.exit();
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
      callbackURL: "http://" + SITE_URL + "/auth/facebook/callback"
    };
    postLogin = function(accessToken, refreshToken, profile, done){
      return database.users.findOne({
        provider: profile.provider,
        id: profile.id
      }, function(err, user){
        if (profile.emails) {
          profile.email = profile.emails[0].value;
        }
        if (!user || err) {
          database.users.insert(profile);
          if (profile) {
            return done(null, profile);
          }
        } else {
          user.username = profile.username;
          user.displayName = profile.displayName;
          user.name = profile.name;
          user.gender = profile.gender;
          user.emails = profile.emails;
          user.email = profile.email;
          database.users.update({
            _id: user._id
          }, user);
          if (user) {
            return done(null, user);
          }
        }
      });
    };
    passport.use(new passportFacebook.Strategy(facebookSettings, postLogin));
    vkSettings = {
      clientID: VK_ID,
      clientSecret: VK_SECRET,
      callbackURL: "http://" + SITE_URL + "/auth/vkontakte/callback"
    };
    passport.use(new passportVkontakte.Strategy(vkSettings, postLogin));
    passport.serializeUser(function(user, done){
      return done(null, user.id);
    });
    passport.deserializeUser(function(id, done){
      return database.users.findOne({
        id: id
      }, function(error, user){
        if (user) {
          delete user._id;
          delete user._json;
          delete user._raw;
          return done(error, user);
        } else {
          return done(error, false);
        }
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
      var sessionStore, login, callback, redisStore, sessionSockets;
      sessionStore = new (connectRedis(express));
      app.configure(function(){
        app.set("port", PORT);
        app.set("views", __dirname + "/views/server");
        app.set("view engine", "jade");
        app.use(assets);
        app.use(express['static'](__dirname + "/public"));
        app.use(express.bodyParser());
        app.use(express.methodOverride());
        app.use(express.cookieParser(SECRET));
        app.use(express.session({
          store: sessionStore,
          secret: SECRET
        }));
        app.use(passport.initialize());
        app.use(passport.session());
        app.use(express.compress());
        app.use(function(req, res, next){
          var user, timestamp, cookie_user_id, user_id, session_id;
          user = req.user ? req.user : null;
          app.locals.user = user;
          if (user) {
            app.locals.user_id = user.displayName;
          } else {
            timestamp = Math.round(new Date().getTime() / 1000);
            cookie_user_id = req.cookies.user_id;
            user_id = cookie_user_id
              ? cookie_user_id
              : "user" + timestamp;
            res.cookie('user_id', user_id, {
              maxAge: 900000,
              httpOnly: false
            });
            app.locals.user_id = user_id;
          }
          session_id = req.cookies.session_id || "session" + timestamp;
          res.cookie('session_id', user_id, {
            maxAge: 60 * 60,
            httpOnly: false
          });
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
      app.get("/", backEnd.about.index);
      app.get("/search/:hash", backEnd.about.index);
      app.get("/journey/:hash", backEnd.about.index);
      app.get("/add_email", backEnd.about.add_email);
      app.get("/about", backEnd.about.about);
      app.get("/city", backEnd.content.city);
      app.get("/api/v2/autocomplete/:query", backEnd.api.autocomplete_v2);
      app.get("/api/v2/image/:country/:city", backEnd.api.image_v2);
      app.get("/api/v2/get_location", backEnd.api.get_location);
      app.get("/api/v2/auth/add_email/:email", backEnd.api.add_email);
      app.get("/api/v2/hotels/details/:provider/:id", backEnd.api.hotels.details);
      app.get("/redirect/:hash", backEnd.redirect.redirect);
      app.get("/dashboard", backEnd.dashboard.dashboard);
      login = function(provider, req, res){
        var referer, tripHash, searchHash, redirectUrl;
        referer = req.header('Referer');
        tripHash = req.session.trip_hash;
        searchHash = req.session.search_hash;
        if (tripHash) {
          redirectUrl = "/journey/" + tripHash;
        } else if (searchHash) {
          redirectUrl = "/search/" + searchHash;
        } else if (referer) {
          redirectUrl = referer;
        } else {
          redirectUrl = '/';
        }
        req.session.postLoginRedirect = redirectUrl;
        return passport.authenticate(provider, {
          scope: ['email']
        })(req, res);
      };
      callback = function(req, res){
        if (req.session.postLoginRedirect) {
          return res.redirect(req.session.postLoginRedirect);
        } else {
          return res.redirect('/#');
        }
      };
      app.get("/auth/facebook", function(req, res){
        return login('facebook', req, res);
      });
      app.get("/auth/facebook/callback", passport.authenticate('facebook'), callback);
      app.get("/auth/vkontakte", function(req, res){
        return login('vkontakte', req, res);
      });
      app.get("/auth/vkontakte/callback", passport.authenticate('vkontakte'), callback);
      app.get("/auth/logout", function(req, res){
        req.logout();
        return res.redirect('/');
      });
      app.get("*", backEnd.about.error);
      server.listen(app.get("port"), function(){
        return console.log("Express server listening on port " + app.get("port"));
      });
      redisStore = new SocketRedis({
        redisPub: redis.createClient(),
        redisSub: redis.createClient(),
        redisClient: redis.createClient()
      });
      sessionSockets = new SocketSession(io, sessionStore, express.cookieParser(SECRET));
      io.set('store', redisStore);
      io.enable('browser client minification');
      io.enable('browser client etag');
      io.enable('browser client gzip');
      io.set('log level', 1);
      return sessionSockets.on('connection', backEnd.api.search);
    });
  }
}).call(this);
