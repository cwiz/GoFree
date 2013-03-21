async 	= require "async"
exec	= require("child_process").exec
md5 	= require "MD5"
redis 	= require "redis"
request	= require "request"

client 	= redis.createClient()

TTL 	= 3600

setInProgress 		= (key) -> exports.set "inprogress-#{md5(key)}", true
setNotInProgress 	= (key) -> exports.set "inprogress-#{md5(key)}", false

exports.get = (key, cb, retry=1) -> 
	valueKey 		= "cache-#{md5(key)}"
	inProgessKey	= "inprogress-#{md5(key)}"

	(error, inProgess) <- client.get inProgessKey
	#console.log "CACHE: IN PROGRESS | key: #{inProgessKey} | status: #{!!(not error or inProgess)}"
	if inProgess and retry <= 1 
		return setTimeout ( -> exports.get key, cb, retry + 1 ), 1000
	
	client.get valueKey, cb

exports.set = (key, value) -> 
	key = "cache-#{md5(key)}"

	client.set key, value
	client.expire key, TTL

exports.request = (url, cb) ->

	(error, body) <- exports.get url
	#console.log "CACHE: REDIS | url: #{url} | status: #{!!body}"
	return cb null, body if body
	
	setInProgress url
	(error, response, body) <- request url
	#console.log "CACHE: HTTP | url: #{url} | status: #{!!body}"
	
	if error
		setNotInProgress url
		return cb error, null

	cb null, body
	exports.set url, body
	setNotInProgress url

exports.exec = (command, cb) ->
	(error, body) <- exports.get command
	#console.log "CACHE: REDIS | command: #{command} | status: #{!!body}"

	return cb null, body if body

	(error, body) <- exec command
	#console.log "CACHE: EXEC | command: #{command} | status: #{!!body}"
	
	if error
		setNotInProgress command
		return cb error, null 

	cb null, body
	exports.set command, body
	setNotInProgress command
