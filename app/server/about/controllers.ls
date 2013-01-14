
exports.index = (req, res) ->
	res.render "index", { title: "Index Page" }

exports.about = (req, res) ->
	res.render "about", { title: 'About Page'}
