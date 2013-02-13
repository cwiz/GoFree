(function(){
  var express, backEnd, http, socket, path, rack, app, server, io, assets;
  express = require("express");
  backEnd = require("./app/server");
  http = require("http");
  socket = require("socket.io");
  path = require("path");
  rack = require("asset-rack");
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
    app.get("/", backEnd.about.index);
    app.get("/search/:hash", backEnd.about.index);
    app.get("/about", backEnd.about.about);
    app.get("/api/v2/autocomplete/:query", backEnd.api.autocomplete_v2);
    app.get("/api/v2/image/:country/:city", backEnd.api.image_v2);
    io.sockets.on("connection", backEnd.api.search);
    server.listen(app.get("port"), function(){
      return console.log("Express server listening on port " + app.get("port"));
    });
    return io.set("log level", 1);
  });
}).call(this);
