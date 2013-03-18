(function(){
  var database;
  database = require("./../database");
  exports.redirect = function(req, res){
    return database.links.findOne({
      hash: req.params.hash
    }, function(error, result){
      if (error || !result) {
        return res.render("error");
      }
      res.render("redirect/index", {
        result: result.result
      });
      return database.conversions.insert({
        result: result,
        url: result.url,
        user: req.user,
        ip: req.ip,
        cookies: req.cookies
      });
    });
  };
}).call(this);
