geobase 	= require "./../geobase"

exports.autocomplete = (req, res) ->
	query = req.params.query

	res.json { 
		status 	: \error
		message	: "Please supply 'q' GET param." 
	} if not query

	(error, results) <- geobase.autocomplete query

	return res.json { status : 'error', error : error } if error

	res.json do
		status	: \ok
		value	: results
