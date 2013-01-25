(function(){
  var JSV, env, START_SEARCH_SCHEMA, SEARCH_SCHEMA, validate;
  JSV = require("JSV").JSV;
  env = JSV.createEnvironment();
  START_SEARCH_SCHEMA = {
    type: 'object',
    properties: {
      hash: {
        type: 'string',
        required: true
      }
    }
  };
  SEARCH_SCHEMA = {
    type: 'object',
    properties: {
      adults: {
        type: 'integer',
        required: true,
        minimum: 1,
        maximum: 6
      },
      budget: {
        type: 'integer',
        required: true,
        minimum: 0
      },
      hash: {
        type: 'string',
        required: true
      },
      trips: {
        type: 'array',
        required: true,
        items: {
          type: 'object',
          properties: {
            signature: {
              type: 'string',
              required: false
            },
            date: {
              type: 'string',
              format: 'date',
              required: true
            },
            removable: {
              type: 'boolean',
              required: false
            },
            place: {
              type: 'object',
              required: true
            }
          }
        }
      }
    }
  };
  validate = function(data, schema, cb){
    var report;
    report = env.validate(data, schema);
    if (report.errors.length === 0) {
      return cb(null, data);
    }
    return cb(report.errors, null);
  };
  exports.search = function(data, cb){
    return validate(data, SEARCH_SCHEMA, cb);
  };
  exports.start_search = function(data, cb){
    return validate(data, START_SEARCH_SCHEMA, cb);
  };
}).call(this);
