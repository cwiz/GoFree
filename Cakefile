# Cakefile

{exec} = require "child_process"

REPORTER = "spec"

task "test", "run tests", ->
  exec "NODE_ENV=test 
    mocha 
    --compilers coffee:coffee-script
    --require coffee-script 
    --require test/test_helper.coffee
    --colors
    --reporter #{REPORTER}
    --timeout 7000
  ", (err, output) ->
    if err
        console.log err
        throw err
    console.log output