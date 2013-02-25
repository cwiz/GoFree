geobase 	= require "./../geobase"

exports.autocomplete = (req, res) ->
	query = req.params.query

	res.send { 
		status 	: \error
		message	: "Please supply 'q' GET param." 
	} if not query

	(error, results) <- geobase.autocomplete query
	return res.send { status : 'error', error : error } if error

	res.send do
		status	: \ok
		value	: results
