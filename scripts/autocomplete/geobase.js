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
        name_ru: null,
        longitude: parseFloat(data[4] || 0),
        latitude: parseFloat(data[4] || 0),
        population: parseInt(data[14] || 0),
        timezone: data[17],
        country_code: data[8],
        country_name_ru: null,
        country_name: null
      };
      object.name_lower = object.name.toLowerCase().replace('-', '_').replace(' ', '_');
      valid_geo_ids[object.geoname_id] = true;
      if (population <= 10000) {
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
      var geoname, operation;
      geoname = {
        geoname_id: parseInt(data[1]),
        name_ru: data[3]
      };
      if (!valid_geo_ids[geoname.geoname_id]) {
        return null;
      }
      geoname.name_ru_lower = geoname.name_ru.toLowerCase().replace('-', '_').replace(' ', '_');
      return operation = function(total, cb){
        return database.geonames.update({
          geoname_id: geoname.geoname_id
        }, {
          $set: {
            name_ru: geoname.name_ru,
            name_ru_lower: geoname.name_ru_lower
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
    return database.airports.find().toArray(function(err, airports){
      var operations, number, len$, airport;
      operations = [];
      for (number = 0, len$ = airports.length; number < len$; ++number) {
        airport = airports[number];
        (fn$.call(this, airport, number, airport));
      }
      console.log("Performing DB operation on " + operations.length + " operations.");
      return async.series(operations, callback);
      function fn$(object, number, airport){
        var operation;
        operation = function(cb){
          var country, city;
          country = object.country.toLowerCase().replace('-', '_').replace(' ', '_');
          city = object.city.toLowerCase().replace('-', '_').replace(' ', '_');
          return database.geonames.update({
            country_name_lower: country,
            name_lower: city
          }, {
            $set: {
              iata: object.iata
            }
          }, function(error, result){
            bar.update(number.toFixed(2) / airports.length);
            return cb(error, result);
          });
        };
        operations.push(operation);
      }
    });
  };
  addInflectedNames = function(callback){
    var bar, done, q;
    console.log('Inflecting');
    bar = progressBar.create(process.stdout);
    done = 0;
    q = async.queue(function(task, cb){
      return task(cb);
    }, 16);
    q.drain = function(){
      return callback(null, 'done');
    };
    return database.geonames.find({
      name_ru: {
        $ne: null
      },
      iata: {
        $ne: null
      },
      population: {
        $gte: 10000
      }
    }).toArray(function(err, results){
      var callbacks;
      return callbacks = _.map(results, function(result){
        var opearation;
        opearation = function(cb){
          return exec("python " + __dirname + "/python/inflect.py -d " + __dirname + "/python/dicts/ -w " + result.name_ru, function(error, stdout, stderr){
            var name_ru_inflected;
            if (error || stderr) {
              return cb(error, null);
            }
            name_ru_inflected = stdout.toLowerCase().capitalize().replace('\n', '');
            return database.geonames.update({
              geoname_id: result.geoname_id
            }, {
              $set: {
                name_ru_inflected: name_ru_inflected
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
