# Cakefile

child_process   = require "child_process"
exec            = child_process.exec
spawn           = child_process.spawn

REPORTER = "spec"

commandOutput = (error, output) ->
    if error
        console.log error.message
    
    console.log output

task "test", "run tests", ->
  exec "NODE_ENV=test 
    mocha 
    --compilers coffee:coffee-script
    --require coffee-script 
    --require test/test_helper.coffee
    --colors
    --reporter #{REPORTER}
    --timeout 7000
    ", commandOutput
    

task "db:populateAirports", 'populate airports', ->
    exec "coffee scripts/airports/populateAirports.coffee", commandOutput

task "devserver", 'development server w/ autoreload', ->
    ls = exec "nodemon -w public/ -w app/ -w views/cleint/ app.js & livescript -wc app/server/*"
    ls.stdout.on 'data', (data) -> console.log data
