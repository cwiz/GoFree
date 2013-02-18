_			= require "underscore"
database 	= require "./../database"

exports.add_email = (req, res) ->
	user 	= req.user
	email 	= req.params.email

	res.json({
		status	: 'error'
		message	: 'this method works only for logged in users'
	}) if not user

	database.users.update { provider: user.provider, id: user.id }, do
		$set:
			emails:
				value: email
			
			email: email
	
	res.json do
		status: 'ok'
