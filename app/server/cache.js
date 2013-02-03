(function(){
  var database;
  database = require("./database");
  exports.get = function(hash, cb){
    return database.cache.findOne({
      hash: hash
    }, cb);
  };
  exports.set = function(hash, result){
    return database.cache.insert({
      hash: hash,
      result: result
    });
  };
}).call(this);
