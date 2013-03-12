geobase 	= require "./../geobase"

exports.details = (req, res) ->
	
	provider 	= req.params.provider
	id 			= +req.params.id

	return res.json {
		status : \error
		message: 'Please supply provider or id'
	} if (not provider or not id)

	try
		provider = require "./providers/#{provider}"
	catch error
		return res.json do
			status : \error
			message: 'No such provider'

	(error, hotel) <- provider.details id
  
	return res.json {
		status 	: \error
		message	: error
	} if (error or not hotel)

	res.json do
		status 	: \ok
		hotel	: hotel
