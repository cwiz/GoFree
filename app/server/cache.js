(function(){
  var async, exec, md5, redis, request, winston, client, TTL, setInProgress, setNotInProgress;
  async = require("async");
  exec = require("child_process").exec;
  md5 = require("MD5");
  redis = require("redis");
  request = require("request");
  winston = require("winston");
  client = redis.createClient();
  TTL = 3600;
  setInProgress = function(key){
    return exports.set("inprogress-" + md5(key), true);
  };
  setNotInProgress = function(key){
    return exports.set("inprogress-" + md5(key), false);
  };
  exports.get = function(key, cb, retry){
    var valueKey, inProgessKey;
    retry == null && (retry = 1);
    valueKey = "cache-" + md5(key);
    inProgessKey = "inprogress-" + md5(key);
    return client.get(inProgessKey, function(error, inProgess){
      winston.info("CACHE: IN PROGRESS | key: " + inProgessKey + " | status: " + !!inProgess);
      if (inProgess && retry <= 1) {
        return setTimeout(function(){
          return exports.get(key, cb, retry + 1);
        }, 1000);
      }
      return client.get(valueKey, cb, function(error, value){
        cb(error, value);
        return winston.info("CACHE: GET | key: " + valueKey + " | status: " + !!value);
      });
    });
  };
  exports.set = function(key, value){
    key = "cache-" + md5(key);
    client.set(key, value);
    return client.expire(key, TTL);
  };
  exports.request = function(url, cb){
    return exports.get(url, function(error, body){
      winston.info("CACHE: REDIS | url: " + url + " | status: " + !!body);
      if (body) {
        return cb(null, body);
      }
      setInProgress(url);
      return request(url, function(error, response, body){
        winston.info("CACHE: HTTP | url: " + url + " | status: " + !!body);
        if (error) {
          setNotInProgress(url);
          return cb(error, null);
        }
        cb(null, body);
        exports.set(url, body);
        return setNotInProgress(url);
      });
    });
  };
  exports.exec = function(command, cb){
    return exports.get(command, function(error, result){
      winston.info("CACHE: REDIS | command: " + command + " | status: " + !!result);
      if (result) {
        return cb(null, result);
      }
      return exec(command, function(error, body){
        winston.info("CACHE: EXEC | command: " + command + " | status: " + !!body);
        if (error) {
          setNotInProgress(command);
          return cb(error, null);
        }
        cb(null, body);
        exports.set(command, body);
        return setNotInProgress(command);
      });
    });
  };
}).call(this);
