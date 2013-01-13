(function(){
  var exec, REPORTER;
  exec = require("child_process").exec;
  REPORTER = "spec";
  task("test", "run tests", function(){
    return exec("NODE_ENV=test mocha --compilers coffee:coffee-script--require coffee-script --require test/test_helper.coffee--colors--reporter " + REPORTER + "--timeout 5000", function(err, output){
      if (err) {
        console.log(err);
        throw err;
      }
      return console.log(output);
    });
  });
}).call(this);
