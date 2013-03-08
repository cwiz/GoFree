database = require "./../database"

exports.redirect = (req, res) ->
	url = req.query.url
	return res.send 'supply url GET param', 404 if not url

	database.conversions.insert do
		url		: url
		user	: req.user
		ip		: req.ip
		cookies	: req.cookies

	res.redirect url
