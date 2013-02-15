(function(){
  var cluster, numCPUs, processNumber, auth, backEnd, express, http, os, path, rack, redis, RedisStore, socket, app, server, io, assets;
  cluster = require("cluster");
  numCPUs = 1;
  if (cluster.isMaster) {
    processNumber = 0;
    while (processNumber < numCPUs) {
      cluster.fork();
      processNumber += 1;
    }
    cluster.on('exit', function(worker, code, signal){
      console.log("worker " + worker.process.pid + " died");
      return cluster.fork();
    });
  } else {
    auth = require("http-auth");
    backEnd = require("./app/server");
    cluster = require("cluster");
    express = require("express");
    http = require("http");
    os = require("os");
    path = require("path");
    rack = require("asset-rack");
    redis = require("socket.io/node_modules/redis");
    RedisStore = require("socket.io/lib/stores/redis");
    socket = require("socket.io");
    app = express();
    server = http.createServer(app);
    io = socket.listen(server);
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
      var basic, pub, sub, client;
      app.configure(function(){
        app.set("port", process.env.PORT || 3000);
        app.set("views", __dirname + "/views/server");
        app.set("view engine", "jade");
        app.use(assets);
        app.use(express['static'](__dirname + "/public"));
        app.use(express.bodyParser());
        app.use(express.methodOverride());
        app.use(app.router);
        app.use(express.compress());
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
      io.sockets.on("connection", backEnd.api.search);
      server.listen(app.get("port"), function(){
        return console.log("Express server listening on port " + app.get("port"));
      });
      pub = redis.createClient();
      sub = redis.createClient();
      client = redis.createClient();
      io.set('store', new RedisStore({
        redisPub: pub,
        redisSub: sub,
        redisClient: client
      }));
      io.enable('browser client minification');
      io.enable('browser client etag');
      io.enable('browser client gzip');
      return io.set('log level', 1);
    });
  }
}).call(this);
