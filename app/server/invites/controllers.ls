database = require "./../database"

exports.index = (req, res) ->
	res.render "invites/index"

exports.error = (req, res) ->
	res.render "invites/error"

exports.activate = (req, res) ->
	guid = req.params.guid

	(error, result) <- database.invites.findOne do 
		guid: guid
		used: false

	console.log error

	return res.redirect "/invites/error" if (error or not result)

	req.session.invite = result
	res.redirect '/'
