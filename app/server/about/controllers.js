(function(){
  exports.index = function(req, res){
    return res.render("index", {
      title: "Index Page"
    });
  };
  exports.about = function(req, res){
    return res.render("about", {
      title: 'About Page'
    });
  };
  exports.add_email = function(req, res){
    return res.render("addemail");
  };
  exports.error = function(req, res){
    return res.render("error", {
      layout: 'splash.jade'
    });
  };
}).call(this);
