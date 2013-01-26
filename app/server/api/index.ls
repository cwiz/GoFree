autocomplete 			= require "./autocomplete"
controllers 			= require "./controllers"
socket 					= require "./socket"

exports.autocomplete_v2 = autocomplete.autocomplete
exports.autocomplete 	= controllers.autocomplete
exports.image 		  	= controllers.image
exports.search 			= socket.search
