// Generated by LiveScript 1.2.0
(function(){
  var geobase;
  geobase = require("./../geobase");
  exports.details = function(req, res){
    var provider, id, error;
    provider = req.params.provider.split('.')[0];
    id = +req.params.id;
    if (!provider || !id) {
      return res.json({
        status: 'error',
        message: 'Please supply provider or id'
      });
    }
    try {
      provider = require("./providers/" + provider);
    } catch (e$) {
      error = e$;
      return res.json({
        status: 'error',
        message: 'No such provider'
      });
    }
    return provider.details(id, function(error, hotel){
      if (error || !hotel) {
        return res.json({
          status: 'error',
          message: error
        });
      }
      return res.json({
        status: 'ok',
        hotel: hotel
      });
    });
  };
}).call(this);
