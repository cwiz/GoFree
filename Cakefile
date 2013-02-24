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
		--timeout 60000
		"

	test.stdout.on 'data', console.log
	test.stderr.on 'data', console.log

task "db:populate_airports", 'populate airports', ->
	airports = exec "coffee scripts/airports/populateAirports.coffee"

	airports.stdout.on 'data', console.log
	airports.stderr.on 'data', console.log

task "db:populate_airlines", 'populate airports', ->
	airports = exec "livescript scripts/airlines/populateAirlines.ls"

	airports.stdout.on 'data', console.log
	airports.stderr.on 'data', console.log

task "db:restore_geonames", 'populate geonames', ->
	airports = exec "mongorestore --db ostroterra --verbose --collection geonames #{__dirname}/scripts/autocomplete/geonames/ostroterra/geonames.bson"

	airports.stdout.on 'data', console.log
	airports.stderr.on 'data', console.log

task "db:copy_geonames", 'copy geonames DB to node modules', ->
	exec 'cp -r data/* node_modules/geoip-lite/data'

task "dev", 'development server w/ autoreload', ->
	exec "npm install ."

	ls = exec "livescript -wc app/server/ app.ls"
	ls.stdout.on 'data',  console.log
	ls.stderr.on 'error', console.log

	setTimeout ( ->
		nodemon = exec "nodemon -w public/css/ -w app/ -w views/ -w app.js app.js"
		nodemon.stdout.on 'data', console.log
		nodemon.stderr.on 'data', console.log
	), 1000
