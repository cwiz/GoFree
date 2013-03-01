(function(){
  var database;
  database = require("./../database");
  exports.index = function(req, res){
    return res.render("invites/index");
  };
  exports.error = function(req, res){
    return res.render("invites/error");
  };
  exports.activate = function(req, res){
    var guid;
    guid = req.params.guid;
    return database.invites.findOne({
      guid: guid,
      used: false
    }, function(error, result){
      console.log(error);
      if (error || !result) {
        return res.redirect("/invites/error");
      }
      req.session.invite = result;
      return res.redirect('/');
    });
  };
}).call(this);
