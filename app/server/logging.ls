winston = require "winston"

exports.getLogger = (name) ->


    logger = new (winston.Logger)({
        transports: [
          new (winston.transports.Console)( { colorize: true, timestamp: true }),
          new (winston.transports.File)(    { filename: __dirname + "/../../logs/#{name}.log", timestamp: true })
        ]
    })

    return logger