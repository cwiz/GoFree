require './libs/runtime' # Jade templates utils

require({
  paths: {
    jquery: './libs/jquery',
    underscore: './libs/underscore',
    backbone: './libs/backbone'
  },
  shim: {
    'jquery': {
      exports: '$'
    },
    'underscore': {
      exports: '_'
    },
    'backbone': {
      deps: ['underscore', 'jquery'],
      exports: 'Backbone'
    }
  }
});

console.log 'LOADID'
