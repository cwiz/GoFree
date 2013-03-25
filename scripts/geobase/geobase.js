(function(){
  var _, async, csv, database, exec, progressBar, importFile, valid_geo_ids, importBaseGeonames, importRuGeonames, importRuCountries, importEnCountries, syncWithAirports, addInflectedNames;
  _ = require("underscore");
  async = require("async");
  csv = require("csv");
  database = require("./../../app/server/database.ls");
  exec = require("child_process").exec;
  progressBar = require("progress-bar");
  String.prototype.capitalize = function(){
    return this.charAt(0).toUpperCase() + this.slice(1);
  };
  String.prototype.replaceAll = function(search, replace){
    return this.split(search).join(replace);
  };
  String.prototype.trim = function(){
    return this.replace(/^\s+|\s+$/g, "");
  };
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
  importBaseGeonames = function(callback){
    return importFile("/cities1000.txt", function(data, index){
      var object;
      object = {
        geoname_id: parseInt(data[0]),
        name: data[1],
        name_ru_collection: [],
        name_lower_collection: [],
        longitude: parseFloat(data[4] || 0),
        latitude: parseFloat(data[4] || 0),
        population: parseInt(data[14] || 0),
        timezone: data[17],
        country_code: data[8],
        country_name_ru: null,
        country_name: null
      };
      object.name_lower = object.name.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
      valid_geo_ids[object.geoname_id] = true;
      if (object.population <= 10000) {
        return null;
      }
      return object;
    }, function(operations){
      database.geonames.insert(operations);
      console.log('Done!');
      return callback(null, operations.length);
    });
  };
  importRuGeonames = function(callback){
    var bar;
    bar = progressBar.create(process.stdout);
    return importFile("/ruNames.txt", function(data, index){
      var ruName, geoname, operation;
      ruName = data[3].toLowerCase();
      ruName = _.map(ruName.split('-'), function(elem){
        return elem.capitalize();
      }).join('-');
      ruName = _.map(ruName.split(' '), function(elem){
        return elem.capitalize();
      }).join(' ');
      geoname = {
        geoname_id: parseInt(data[1]),
        name_ru: ruName
      };
      if (!valid_geo_ids[geoname.geoname_id]) {
        return null;
      }
      geoname.name_ru_lower = geoname.name_ru.toLowerCase().replace('-', '_').replace(' ', '_');
      console.log(ruName);
      return operation = function(total, cb){
        return database.geonames.update({
          geoname_id: geoname.geoname_id
        }, {
          $push: {
            name_ru_collection: geoname.name_ru,
            name_ru_lower_collection: geoname.name_ru_lower
          }
        }, function(error, result){
          bar.update(Math.min(index.toFixed(2) / total, 1));
          return cb(error, result);
        });
      };
    }, function(operations){
      return async.series(_.map(operations, function(operation){
        return function(callback){
          return operation(operations.length, callback);
        };
      }), function(err, result){
        console.log('Done!');
        console.log(err + " | " + result.length);
        return callback(err, result);
      });
    });
  };
  importRuCountries = function(callback){
    var bar;
    bar = progressBar.create(process.stdout);
    return importFile("/countryCodes-ru.txt", function(data, index){
      var country, operation;
      country = {
        code: data[0],
        name_ru: data[4],
        geoname_id: parseInt(data[11])
      };
      if (!country) {
        return null;
      }
      return operation = function(total, cb){
        return database.geonames.update({
          country_code: country.code
        }, {
          $set: {
            country_name_ru: country.name_ru
          }
        }, true, true, function(error, result){
          bar.update(index.toFixed(2) / total);
          return cb(error, result);
        });
      };
    }, function(operations){
      return async.series(_.map(operations, function(operation){
        return function(callback){
          return operation(operations.length, callback);
        };
      }), function(err, result){
        console.log('Done!');
        console.log(err + " | " + result.length);
        return callback(err, result);
      });
    });
  };
  importEnCountries = function(callback){
    var bar;
    bar = progressBar.create(process.stdout);
    return importFile("/countryCodes-en.txt", function(data, index){
      var country, operation;
      country = {
        code: data[0],
        name: data[4],
        geoname_id: parseInt(data[11])
      };
      if (!country.code) {
        return null;
      }
      country.name_lower = country.name.toLowerCase().replace('-', '_').replace(' ', '_');
      return operation = function(total, cb){
        return database.geonames.update({
          country_code: country.code
        }, {
          $set: {
            country_name: country.name,
            country_name_lower: country.name_lower
          }
        }, true, true, function(error, result){
          bar.update(index.toFixed(2) / total);
          return cb(error, result);
        });
      };
    }, function(operations){
      return async.series(_.map(operations, function(operation){
        return function(callback){
          return operation(operations.length, callback);
        };
      }), function(err, result){
        console.log('Done!');
        console.log(err + " | " + result.length);
        return callback(err, result);
      });
    });
  };
  syncWithAirports = function(callback){
    var bar;
    console.log('Syncing with airports');
    bar = progressBar.create(process.stdout);
    return database.airports.find({
      iata: {
        $ne: [null, '']
      }
    }).toArray(function(err, airports){
      var complete, operations;
      complete = 0;
      operations = _.map(airports, function(airport){
        var operation;
        return operation = function(cb){
          var country, city;
          country = airport.country.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
          city = airport.city.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
          airport.iata = airport.iata.trim();
          if (!airport.iata) {
            return cb({
              message: 'no airport found'
            }, null);
          }
          complete += 1;
          return database.geonames.update({
            country_name_lower: country,
            name_lower: city
          }, {
            $set: {
              iata: airport.iata
            }
          }, function(error, result){
            bar.update(complete.toFixed(2) / airports.length);
            return cb(error, result);
          });
        };
      });
      console.log("Performing DB operation on " + operations.length + " operations.");
      return async.series(operations, callback);
    });
  };
  addInflectedNames = function(callback){
    var bar, done, q;
    console.log('Inflecting');
    bar = progressBar.create(process.stdout);
    done = 0;
    q = async.queue(function(task, cb){
      return task(cb);
    }, 4);
    q.drain = function(){
      return callback(null, 'done');
    };
    return database.geonames.find({
      name_ru_collection: {
        $ne: []
      }
    }).toArray(function(err, results){
      var callbacks;
      return callbacks = _.map(results, function(result){
        var opearation;
        opearation = function(cb){
          var operations;
          operations = _.map(result.name_ru_collection, function(name_ru){
            return function(callback){
              var command;
              command = "python " + __dirname + "/python/inflect.py -d " + __dirname + "/python/dicts/ -w " + name_ru;
              return exec(command, function(error, stdout, stderr){
                var name_ru_inflected;
                if (stdout && stdout.toLowerCase().capitalize().replace('\n', '')) {
                  name_ru_inflected = stdout.toLowerCase().capitalize().replaceAll('\n', '');
                } else {
                  name_ru_inflected = "городе " + result.name_ru;
                }
                return callback(null, name_ru_inflected);
              });
            };
          });
          return async.parallel(operations, function(error, name_ru_inflected_collection){
            return database.geonames.update({
              geoname_id: result.geoname_id
            }, {
              $set: {
                name_ru_inflected_collection: name_ru_inflected_collection
              }
            }, function(error, result){
              bar.update(done.toFixed(2) / results.length);
              done += 1;
              return cb(error, result);
            });
          });
        };
        return q.push(opearation);
      });
    });
  };
  setTimeout(function(){
    return async.series([
      function(callback){
        return database.geonames.drop(callback);
      }, importBaseGeonames, importRuGeonames, importRuCountries, importEnCountries, syncWithAirports, addInflectedNames, function(callback){
        return process.exit();
      }
    ]);
  }, 1000);
}).call(this);
