// Dependencies
var express = require('express')
  , routes  = require('./server')
  , http    = require('http')
  , socket  = require('socket.io')
  , path    = require('path')
  , rack    = require('asset-rack');

// Globals
var app     = express();
var server  = http.createServer(app);
var io      = socket.listen(server);

// Assets-Rack
var assets = new rack.AssetRack([
    new rack.LessAsset({
        url: '/app.css',
        filename: __dirname + '/public/css/app.less',
        paths: [__dirname + '/public/css/includes', __dirname + '/public/css/lib', __dirname + '/public/css/'],
        compress: false
    }),
    new rack.BrowserifyAsset({
        url: '/app.js',
        filename: __dirname + '/public/js/app.coffee',
        compress: false
    }),
    new rack.JadeAsset({
        url: '/views.js',
        dirname: __dirname + '/public/views',
        separator: '_',
        clientVariable: 'app.templates',
        compress: false
    })
]);

assets.on('complete', function() {

  // Configuration
  app.configure(function() {
    app.set('port', process.env.PORT || 3000);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.set('view options', { pretty: true, compress: false });
    
    app.use(assets);
    //app.use(express.favicon('favicon.ico'));
    app.use(express.static(__dirname + '/public/assets'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
    app.use(express.compress());
    // app.use(express.static(path.join(__dirname, 'public')));
  });

  app.configure('development', function(){
    app.use(express.errorHandler());
    app.use(express.logger('dev'));
  });

  // Routes
  app.get('/', routes.index);
  app.get('/about', routes.about);
  app.get('/api/v1/autocomplete/:query', routes.autocomplete);
  app.get('/api/v1/image/:query', routes.image);

  // Stuff
  
  server.listen(app.get('port'), function(){
    console.log("Express server listening on port " + app.get('port'));
  });
  io.set('log level', 0); 
  io.sockets.on('connection', routes.search);
});



