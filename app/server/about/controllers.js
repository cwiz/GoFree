(function(){
  exports.index = function(req, res){
    console.log(req.user);
    return res.render("index", {
      title: "Index Page"
    });
  };
  exports.about = function(req, res){
    return res.render("about", {
      title: 'About Page'
    });
  };
}).call(this);
