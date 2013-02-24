_			= require "underscore"
async		= require "async"
database 	= require "./../database"

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
			{ name_lower				: regexp_query }
			{ name_ru_lower_collection	: regexp_query }
		] 
		population				: { $gte: 10000 }
		name_ru_collection 		: { $ne: [] 	}
	}

	.limit(10)
	.sort { population: -1 }
	.toArray (err, results) ->
		res.send { status: 'error', error: err } if err

		for r in results

			for name_ru_lower, i in r.name_ru_lower_collection
				if  name_ru_lower.match regexp_query
					r.name_ru_lower 	= name_ru_lower
					
					r.name_ru = r.name_ru_collection[i]
					r.name_ru_inflected = r.name_ru_inflected_collection[i]

			delete r._id

		res.send {
			status: "ok"
			value:  results
		}
