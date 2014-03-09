(function(){
  var _, async, database, child_process, exec;
  _ = require("underscore");
  async = require("async");
  database = require("./../../app/server/database.ls");
  child_process = require("child_process");
  exec = child_process.exec;
  database.airlines.find().toArray(function(error, airlines){
    var operations;
    operations = _.map(airlines, function(ai){
      var operation;
      return operation = function(callback){
        var command;
        command = "wget https://eviterra.com/images/carriers/" + ai.iata + ".png -O icons/" + ai.iata + ".png";
        console.log(command);
        return exec(command, function(err, result){
          return callback(null, {});
        });
      };
    });
    console.log(operations);
    return async.series(operations);
  });
}).call(this);
