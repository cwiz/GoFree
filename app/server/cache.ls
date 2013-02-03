database 	= require "./database"

exports.get = (hash, cb)     -> database.cache.findOne {hash: hash}, cb
exports.set = (hash, result) -> database.cache.insert {hash: hash, result: result}
