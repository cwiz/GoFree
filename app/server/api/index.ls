autocomplete 			= require "./autocomplete"
controllers 			= require "./controllers"
socket 					= require "./socket"

exports.autocomplete_v2 = autocomplete.autocomplete
exports.autocomplete 	= controllers.autocomplete
exports.image 		  	= controllers.image
exports.image_v2 		= controllers.image_v2
exports.search 			= socket.search
