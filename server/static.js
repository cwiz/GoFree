(function(){
  exports.about = function(req, res){
    return res.render("about", {
      title: 'about page'
    });
  };
}).call(this);
