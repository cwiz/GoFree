(function(){
  var database, geoip;
  database = require("./../database");
  geoip = require("geoip-lite");
  exports.get_location = function(req, res){
    var ip, location;
    ip = req.connection.remoteAddress;
    if (ip === '127.0.0.1') {
      ip = '93.80.144.90';
    }
    location = geoip.lookup(ip);
    if (!location) {
      return res.json({
        status: 'error',
        message: 'nothign found'
      });
    }
    return database.geonames.findOne({
      country_code: location.country,
      name: location.city
    }, function(error, city){
      if (error) {
        return res.json({
          status: 'error',
          message: error
        });
      }
      delete city._id;
      return res.json({
        status: 'ok',
        value: city
      });
    });
  };
}).call(this);
