(function(){
  exports.login = function(req, res){
    var user;
    if (req.session.auth) {
      console.log(req.session.auth.github);
      user = req.session.auth.facebook.user.name;
      console.log("user: " + user);
    }
    console.log(req.session.auth);
    return res.render('auth/example', {
      title: user,
      usr: user,
      layout: false
    });
  };
}).call(this);
