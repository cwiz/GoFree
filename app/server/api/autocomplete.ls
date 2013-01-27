database = require "./../database"

exports.autocomplete = (req, res) ->
	query = req.params.query

	if not query
		res.send { 
			status 	: "error"
			message	: "Please supply 'q' GET param." 
		} 

	query = query.toLowerCase().replace('-', '_').replace(' ', '_')
	regexp_query = new RegExp("^" + query);
	
	database.geonames.find {
		$or : [
			{ name_ru_lower	: regexp_query },
			{ name_lower	: regexp_query },
		] 
		population		: { $gte: 10000 },
		iata			: { $ne: null },
		name_ru 		: { $ne: null },
	}

	.limit(10)
	.sort { population: -1 }
	.toArray (err, results) ->
		res.send { status: 'error', error: err } if err
		
		for r in results
			delete r._id 
			
		res.send {
			status: "ok"
			value:  results
		}
