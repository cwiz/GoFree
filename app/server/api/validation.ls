JSV = require("JSV").JSV

env     = JSV.createEnvironment()

START_SEARCH_SCHEMA = 
	type: 'object'
	properties:
		hash:
			type: 'string'
			required: true

SEARCH_SCHEMA = 
	type: 'object'
	properties:
		adults: 
			type: 'integer'
			required: true
			minimum: 1
			maximum: 6

		budget:
			type: 'integer'
			required: true
			minimum: 0

		hash:
			type: 'string'
			required: true
		
		trips:
			type: 'array'
			required: true
			
			items: 
				type: 'object'
				properties:

					signature:
						type: 'string'
						required: false
					
					date:
						type: 'string'
						format: 'date'
						required: true
					
					removable:
						type: 'boolean'
						required: false
					
					place:
						type: 'object'
						required: true

validate = (data, schema, cb) ->
	report  = env.validate(data, schema)

	return cb null, data if (report.errors.length is 0)
	cb report.errors, null

exports.search 			= (data, cb) -> validate(data, SEARCH_SCHEMA, cb)
exports.start_search 	= (data, cb) -> validate(data, START_SEARCH_SCHEMA, cb)	
