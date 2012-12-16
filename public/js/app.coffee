# require shit

jadeRuntime = require "./libs/runtime" # Jade templates utils
$ = jQuery 	= require "jquery-browserify"
Backbone 	= require "backbone-browserify"


# actual code shit

MyView = Backbone.View.extend
	el: 'body',
	initialize: () ->
		@render()

	render: () ->
		$(@el).html '<h1>PITUSHOK KUD KUDA</h1>'

$(document).ready () -> 
	myView = new MyView()

#
