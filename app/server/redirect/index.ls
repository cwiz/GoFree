database = require "./../database"

exports.redirect = (req, res) ->

	(error, result) <- database.links.findOne hash: req.params.hash
	return res.render "error" if (error or not result)
	
	res.render "redirect/index", result: result.result

	database.conversions.insert do
		result 	: result
		url		: result.url
		user	: req.user
		ip		: req.ip
		cookies	: req.cookies
