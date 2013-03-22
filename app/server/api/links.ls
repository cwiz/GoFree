database    = require "./../database"
md5 		= require "MD5"

exports.getLinkHash = (result) ->
	hash = md5 JSON.stringify result
	
	database.links.insert {
		hash	: hash
		result	: result
	}, (error, link) ->

	return hash
