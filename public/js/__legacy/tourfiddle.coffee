_       = require './underscore'
utils 	= require './utils'

calculatePrice = (candidate) ->
	total = 0

	for c in candidate
		if c.hotel?
			total += c.hotel.price
		if c.flight?
			total += c.flight.price

	return total

calculateRating = (candidate) ->
	total = 0

	for c in candidate
		if c.hotel?
			total += c.hotel.weightedRating 
		if c.flight?
			total += c.flight.weightedRating

	return total

buildInitialCandidate = (blocks) ->
	# initial population
	candidate = []

	for block in blocks
		candidate.push 
			flight: _.min(block.flights, (elem) -> elem.price)
			hotel: 	_.min(block.hotels,  (elem) -> elem.price)

	rating 	= calculateRating(candidate)
	price 	= calculatePrice(candidate)

	#console.log "Inital candidate | Price: #{price} | Rating: #{rating}"

	return candidate

permutateCandidate = (candidate, blocks, maxPrice) ->
	randomIndex = _.random 0, candidate.length - 1
	
	if randomIndex is (blocks.length - 1)
		changeHotel = 0
	else
		changeHotel = _.random 0, 1

	currentCandidate = utils.clone candidate
	availableMoney = maxPrice - currentCandidate.price
	
	if changeHotel
		
		if candidate[randomIndex].hotel?.weightedRating?
			currentHotelRating = candidate[randomIndex].hotel.weightedRating 
		else
			currentHotelRating = 0.0

		availableHotels = _.filter blocks[randomIndex].hotels, (elem) -> (
			(elem.price <= availableMoney) and 
			(elem.weightedRating > currentHotelRating)
		)

		if availableHotels
			randomHotelIndex = _.random 0, availableHotels.length-1
			currentCandidate[randomIndex].hotel = availableHotels[randomHotelIndex]

		return currentCandidate

	if not changeHotel
		
		if candidate[randomIndex].flight?.weightedRating?
			currentFlightRating = candidate[randomIndex].flight.weightedRating
		else
			currentFlightRating = 0

		availableFlights 	= _.filter blocks[randomIndex].flights, (elem) -> (
			(elem.price <= availableMoney) and
			(elem.weightedRating >= currentFlightRating * 1.2)
		)

		if availableFlights
			randomFlightIndex = _.random 0, availableFlights.length-1
			currentCandidate[randomIndex].flight = availableFlights[randomFlightIndex]

		return currentCandidate

	return currentCandidate


exports.findBestCombination = (blocks, maxPrice) ->
	
	# monte-carlo / genetic mix
	maxIterations   = blocks.length * 50
	populationSize 	= 20
	candidates 		= []

	while candidates.length < populationSize
		candidate 			= buildInitialCandidate(blocks)
		candidate.rating 	= calculateRating(candidate)
		candidate.price 	= calculatePrice(candidate)

		counter = 0
		while true
			newCandidate 		= permutateCandidate 	candidate, blocks, maxPrice
			newCandidate.rating = calculateRating 		newCandidate
			newCandidate.price  = calculatePrice 		newCandidate

			if newCandidate.price >= maxPrice
				break

			if newCandidate.rating > candidate.rating
				candidate = newCandidate

			if (counter + 1) is maxIterations
				break

			counter += 1

		# final touch, squeezing last money

		i = 0
		for c in candidate
			availableMoney = maxPrice - candidate.price
			
			if c.hotel?
				betterHotel = _.filter blocks[i].hotels, (elem) -> (elem.weightedRating > c.hotel.weightedRating) and (elem.price <= c.hotel.price + availableMoney) and (elem.price > c.hotel.price )

				if betterHotel.length > 0
					c.hotel = _.max betterHotel, (elem) -> elem.weightedRating

			candidate.price = calculatePrice(candidate)
			candidate.rating = calculatePrice(candidate)

			i += 1

		candidates.push candidate

	filtered = _.filter candidates, (elem) -> elem.price <= maxPrice * 1.2
	return _.max(filtered, (elem) -> elem.rating) or []
