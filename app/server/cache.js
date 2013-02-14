(function(){
  var md5, redis, request, client, TTL;
  md5 = require("MD5");
  redis = require("redis");
  request = require("request");
  client = redis.createClient();
  TTL = 3600;
  exports.get = function(key, cb){
    return client.get(key, cb);
  };
  exports.set = function(key, value){
    client.set(key, value);
    return client.expire(key, TTL);
  };
  exports.request = function(url, cb){
    return exports.get(url, function(error, body){
      console.log("CACHE: REDIS | " + url + " | status: " + !!body);
      if (body) {
        return cb(null, body);
      }
      return request(url, function(error, response, body){
        console.log("CACHE: HTTP | " + url + " | status: " + !!body);
        if (error) {
          return cb(error, null);
        }
        cb(null, body);
        return exports.set(url, body);
      });
    });
  };
}).call(this);
