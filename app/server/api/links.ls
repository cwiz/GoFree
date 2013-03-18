database    = require "./../database"
md5 		= require "MD5"

exports.getLinkHash = (result) ->
	hash = md5 JSON.stringify result
	
	database.links.insert do
		hash	: hash
		result	: result

	return hash
