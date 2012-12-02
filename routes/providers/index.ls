eviterra 	= require "./eviterra.js"
ostrovok 	= require "./ostrovok.js"

exports.hotelProviders 	= [ostrovok]
exports.flightProviders = [eviterra]
exports.allProviders	= exports.hotelProviders + exports.flightProviders
