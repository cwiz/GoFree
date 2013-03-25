(function(){
  var _, async, csv, database, progressBar, importFile, valid_geo_ids, syncAirlines;
  _ = require("underscore");
  async = require("async");
  csv = require("csv");
  database = require("./../../app/server/database.ls");
  progressBar = require("progress-bar");
  importFile = function(filename, singleOperation, collectionOperation, callback){
    var operations;
    operations = [];
    console.log("Importing: " + filename);
    return csv().from.path(__dirname + filename, {
      delimiter: "\t",
      columns: null,
      escape: null,
      quote: null
    }).transform(function(data){
      return data;
    }).on("record", function(data, index){
      var operation;
      operation = singleOperation(data, operations.length);
      if (operation) {
        return operations.push(operation);
      }
    }).on("error", function(err){
      return console.log(err);
    }).on("end", function(count){
      console.log("Performing DB operation on " + operations.length + " operations.");
      return collectionOperation(operations);
    });
  };
  valid_geo_ids = {};
  syncAirlines = function(callback){
    return importFile("/airlines.csv", function(data, index){
      var object;
      object = {
        iata: data[0],
        name: data[2]
      };
      return object;
    }, function(operations){
      database.airlines.insert(operations);
      console.log('Done!');
      return callback(null, operations.length);
    });
  };
  setTimeout(function(){
    return async.series([
      function(callback){
        return database.airlines.drop(callback);
      }, syncAirlines, function(callback){
        return process.exit();
      }
    ]);
  }, 1000);
}).call(this);
