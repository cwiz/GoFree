(function() {
  var buildInitialCandidate, calculatePrice, calculateRating, permutateCandidate, utils, _;
  _ = require('./underscore');
  utils = require('./utils');
  calculatePrice = function(candidate) {
    var c, total, _i, _len;
    total = 0;
    for (_i = 0, _len = candidate.length; _i < _len; _i++) {
      c = candidate[_i];
      if (c.hotel != null) {
        total += c.hotel.price;
      }
      if (c.flight != null) {
        total += c.flight.price;
      }
    }
    return total;
  };
  calculateRating = function(candidate) {
    var c, total, _i, _len;
    total = 0;
    for (_i = 0, _len = candidate.length; _i < _len; _i++) {
      c = candidate[_i];
      if (c.hotel != null) {
        total += c.hotel.weightedRating;
      }
      if (c.flight != null) {
        total += c.flight.weightedRating;
      }
    }
    return total;
  };
  buildInitialCandidate = function(blocks) {
    var block, candidate, price, rating, _i, _len;
    candidate = [];
    for (_i = 0, _len = blocks.length; _i < _len; _i++) {
      block = blocks[_i];
      candidate.push({
        flight: _.min(block.flights, function(elem) {
          return elem.price;
        }),
        hotel: _.min(block.hotels, function(elem) {
          return elem.price;
        })
      });
    }
    rating = calculateRating(candidate);
    price = calculatePrice(candidate);
    return candidate;
  };
  permutateCandidate = function(candidate, blocks, maxPrice) {
    var availableFlights, availableHotels, availableMoney, changeHotel, currentCandidate, currentFlightRating, currentHotelRating, randomFlightIndex, randomHotelIndex, randomIndex, _ref, _ref2;
    randomIndex = _.random(0, candidate.length - 1);
    if (randomIndex === (blocks.length - 1)) {
      changeHotel = 0;
    } else {
      changeHotel = _.random(0, 1);
    }
    currentCandidate = utils.clone(candidate);
    availableMoney = maxPrice - currentCandidate.price;
    if (changeHotel) {
      if (((_ref = candidate[randomIndex].hotel) != null ? _ref.weightedRating : void 0) != null) {
        currentHotelRating = candidate[randomIndex].hotel.weightedRating;
      } else {
        currentHotelRating = 0.0;
      }
      availableHotels = _.filter(blocks[randomIndex].hotels, function(elem) {
        return (elem.price <= availableMoney) && (elem.weightedRating > currentHotelRating);
      });
      if (availableHotels) {
        randomHotelIndex = _.random(0, availableHotels.length - 1);
        currentCandidate[randomIndex].hotel = availableHotels[randomHotelIndex];
      }
      return currentCandidate;
    }
    if (!changeHotel) {
      if (((_ref2 = candidate[randomIndex].flight) != null ? _ref2.weightedRating : void 0) != null) {
        currentFlightRating = candidate[randomIndex].flight.weightedRating;
      } else {
        currentFlightRating = 0;
      }
      availableFlights = _.filter(blocks[randomIndex].flights, function(elem) {
        return (elem.price <= availableMoney) && (elem.weightedRating >= currentFlightRating * 1.2);
      });
      if (availableFlights) {
        randomFlightIndex = _.random(0, availableFlights.length - 1);
        currentCandidate[randomIndex].flight = availableFlights[randomFlightIndex];
      }
      return currentCandidate;
    }
    return currentCandidate;
  };
  exports.findBestCombination = function(blocks, maxPrice) {
    var availableMoney, betterHotel, c, candidate, candidates, counter, filtered, i, maxIterations, newCandidate, populationSize, _i, _len;
    maxIterations = blocks.length * 50;
    populationSize = 20;
    candidates = [];
    while (candidates.length < populationSize) {
      candidate = buildInitialCandidate(blocks);
      candidate.rating = calculateRating(candidate);
      candidate.price = calculatePrice(candidate);
      counter = 0;
      while (true) {
        newCandidate = permutateCandidate(candidate, blocks, maxPrice);
        newCandidate.rating = calculateRating(newCandidate);
        newCandidate.price = calculatePrice(newCandidate);
        if (newCandidate.price >= maxPrice) {
          break;
        }
        if (newCandidate.rating > candidate.rating) {
          candidate = newCandidate;
        }
        if ((counter + 1) === maxIterations) {
          break;
        }
        counter += 1;
      }
      i = 0;
      for (_i = 0, _len = candidate.length; _i < _len; _i++) {
        c = candidate[_i];
        availableMoney = maxPrice - candidate.price;
        if (c.hotel != null) {
          betterHotel = _.filter(blocks[i].hotels, function(elem) {
            return (elem.weightedRating > c.hotel.weightedRating) && (elem.price <= c.hotel.price + availableMoney) && (elem.price > c.hotel.price);
          });
          if (betterHotel.length > 0) {
            c.hotel = _.max(betterHotel, function(elem) {
              return elem.weightedRating;
            });
          }
        }
        candidate.price = calculatePrice(candidate);
        candidate.rating = calculatePrice(candidate);
        i += 1;
      }
      candidates.push(candidate);
    }
    filtered = _.filter(candidates, function(elem) {
      return elem.price <= maxPrice * 1.2;
    });
    return _.max(filtered, function(elem) {
      return elem.rating;
    }) || [];
  };
}).call(this);
