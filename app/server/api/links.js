(function(){
  var database, md5;
  database = require("./../database");
  md5 = require("MD5");
  exports.getLinkHash = function(result){
    var hash;
    hash = md5(JSON.stringify(result));
    database.links.insert({
      hash: hash,
      result: result
    });
    return hash;
  };
}).call(this);
