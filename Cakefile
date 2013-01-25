# Cakefile

child_process   = require "child_process"
exec            = child_process.exec
spawn           = child_process.spawn

REPORTER = "spec"

task "test", "run tests", ->
	test = exec "NODE_ENV=test 
		mocha 
		--compilers coffee:coffee-script
		--require coffee-script 
		--require test/test_helper.coffee
		--colors
		--reporter #{REPORTER}
		--timeout 7000
		"

	test.stdout.on 'data', console.log
	test.stderr.on 'data', console.log

task "db:populateAirports", 'populate airports', ->
	airports = exec "coffee scripts/airports/populateAirports.coffee"

	airports.stdout.on 'data', console.log
	airports.stderr.on 'data', console.log

task "devserver", 'development server w/ autoreload', ->
	exec "npm install ."

	ls = exec "livescript -wc app/server/*"
	ls.stdout.on 'data',  console.log
	ls.stderr.on 'error', console.log

	setTimeout ( ->
		nodemon = exec "nodemon 
						-w public/ 
						-w app/ 
						-w views/ 
						app.js"
		nodemon.stdout.on 'data', console.log
		nodemon.stderr.on 'data', console.log
	), 1000

	

