
exports.index = (req, res) ->
	res.render "index", { title: "Index Page" }

exports.about = (req, res) ->
	res.render "about", { title: 'About Page'}

exports.add_email = (req, res) ->
	res.render "addemail"

exports.error = (req, res) ->
	res.render "error", layout: 'splash'
