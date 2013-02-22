exec	= require("child_process").exec
md5 	= require "MD5"
redis 	= require "redis"
request	= require "request"

client 	= redis.createClient()

TTL = 3600

exports.get = (key, cb) -> 
	key = "cache-#{md5(key)}"

	client.get key, cb

exports.set = (key, value) -> 
	key = "cache-#{md5(key)}"

	client.set key, value
	client.expire key, TTL

exports.request = (url, cb) ->

	(error, body) <- exports.get url
	console.log "CACHE: REDIS | url: #{url} | status: #{!!body}"

	return cb null, body if body

	(error, response, body) <- request url
	console.log "CACHE: HTTP | url: #{url} | status: #{!!body}"
	return cb error, null if error

	cb null, body
	exports.set url, body

exports.exec = (command, cb) ->
	(error, body) <- exports.get command
	console.log "CACHE: REDIS | command: #{command} | status: #{!!body}"

	return cb null, body if body

	(error, body) <- exec command
	console.log "CACHE: EXEC | command: #{command} | status: #{!!body}"
	return cb error, null if error

	cb null, body
	exports.set command, body
