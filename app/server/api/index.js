(function(){
  var controllers, socket;
  controllers = require("./controllers");
  socket = require("./socket");
  exports.autocomplete = controllers.autocomplete;
  exports.image = controllers.image;
  exports.search = socket.search;
}).call(this);
