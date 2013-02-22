(function(){
  var exec, md5, redis, request, client, TTL;
  exec = require("child_process").exec;
  md5 = require("MD5");
  redis = require("redis");
  request = require("request");
  client = redis.createClient();
  TTL = 3600;
  exports.get = function(key, cb){
    key = "cache-" + md5(key);
    return client.get(key, cb);
  };
  exports.set = function(key, value){
    key = "cache-" + md5(key);
    client.set(key, value);
    return client.expire(key, TTL);
  };
  exports.request = function(url, cb){
    return exports.get(url, function(error, body){
      console.log("CACHE: REDIS | url: " + url + " | status: " + !!body);
      if (body) {
        return cb(null, body);
      }
      return request(url, function(error, response, body){
        console.log("CACHE: HTTP | url: " + url + " | status: " + !!body);
        if (error) {
          return cb(error, null);
        }
        cb(null, body);
        return exports.set(url, body);
      });
    });
  };
  exports.exec = function(command, cb){
    return exports.get(command, function(error, body){
      console.log("CACHE: REDIS | command: " + command + " | status: " + !!body);
      if (body) {
        return cb(null, body);
      }
      return exec(command, function(error, body){
        console.log("CACHE: EXEC | command: " + command + " | status: " + !!body);
        if (error) {
          return cb(error, null);
        }
        cb(null, body);
        return exports.set(command, body);
      });
    });
  };
}).call(this);
