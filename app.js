
// Dependencies

var express = require('express')
  , routes  = require('./routes')
  , http    = require('http')
  , socket  = require('socket.io')
  , path    = require('path');

// Globals

var app     = express();
var server  = http.createServer(app);
var io      = socket.listen(server);
var io      = socket.listen(1488);

// Configuration

app.configure(function(){
  app.set('port', process.env.PORT || 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon('favicon.ico'));
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(express.compress());
  app.use(express.static(path.join(__dirname, 'public')));
});

app.configure('development', function(){
  app.use(express.errorHandler());
});

// app.configure('production', function(){
//   app.use(express.errorHandler());
// });

// Routes

app.get('/', routes.index);
app.get('/about', routes.about);
app.get('/api/v1/autocomplete/:query', routes.autocomplete);
app.get('/api/v1/image/:query', routes.image);

server.listen(app.get('port'), function(){
  console.log("Express server listening on port " + app.get('port'));
});
io.sockets.on('connection', routes.search);


