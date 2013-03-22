(function(){
  var winston;
  winston = require("winston");
  exports.getLogger = function(name){
    var logger;
    logger = new (winston.Logger)({
      transports: [new (winston.transports.File)({
        filename: __dirname + ("/../../logs/" + name + ".log"),
        timestamp: true
      })]
    });
    return logger;
  };
}).call(this);
