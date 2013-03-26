(function(){
  var winston;
  winston = require("winston");
  exports.getLogger = function(name){
    var logger;
    logger = new (winston.Logger)({
      transports: [new (winston.transports.Console)({
        colorize: true,
        timestamp: true
      })]
    });
    return logger;
  };
}).call(this);
