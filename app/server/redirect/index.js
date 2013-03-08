(function(){
  var database;
  database = require("./../database");
  exports.redirect = function(req, res){
    var url;
    url = req.query.url;
    if (!url) {
      return res.send('supply url GET param', 404);
    }
    database.conversions.insert({
      url: url,
      user: req.user,
      ip: req.ip,
      cookies: req.cookies
    });
    return res.redirect(url);
  };
}).call(this);
