
exports.index = (req, res) ->
	console.log req.user
	res.render "index", { title: "Index Page" }

exports.about = (req, res) ->
	res.render "about", { title: 'About Page'}
