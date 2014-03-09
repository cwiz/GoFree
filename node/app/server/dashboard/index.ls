database = require "./../database"

exports.dashboard = (req, res) ->

	(err, numberOfUsers) 		<- database.users.find!.count!
	(err, numberOfSearches) 	<- database.search.find!.count!
	(err, numberOfConversions)	<- database.conversions.find!.count!

	res.render "dashboard/index", do 
		numberOfUsers		: numberOfUsers
		numberOfSearches	: numberOfSearches
		numberOfConversions	: numberOfConversions