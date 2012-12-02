(function() {
  var SearchRow, SearchRowCollection, SocketSERP, fiddle, main, serp, serpRows, utils, _;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  require('./jquery-ui');
  require('./bootstrap');
  _ = require('./underscore');
  utils = require('./utils');
  fiddle = require('./tourfiddle');
  serp = null;
  serpRows = null;
  main = function() {
    var addRowButton, firstRow;
    $.datepicker.setDefaults($.datepicker.regional["ru"]);
    serp = new SocketSERP({
      checkSignatue: function(signature) {
        return signature === serpRows.currentSignature;
      },
      onHotelsReady: function(data) {
        if (!this.checkSignatue(data.signature)) {
          return;
        }
        serpRows.rows[data.rowNumber].addHotels(data.hotels);
        serpRows.findBestCombination();
        return serpRows.calculateStatistics();
      },
      onFlightsReady: function(data) {
        if (!this.checkSignatue(data.signature)) {
          return;
        }
        serpRows.rows[data.rowNumber].addFlights(data.flights);
        serpRows.findBestCombination();
        return serpRows.calculateStatistics();
      }
    });
    serpRows = new SearchRowCollection;
    firstRow = new SearchRow;
    serpRows.push(firstRow);
    firstRow.calendar.attr('placeholder', 'когда');
    firstRow.autocomplete.attr('placeholder', 'откуда');
    firstRow.showTeaser();
    firstRow.isFirstRow = true;
    addRowButton = $(".plus p");
    addRowButton.fadeIn(500);
    return addRowButton.click(function() {
      var newRow, previousDate;
      newRow = new SearchRow();
      previousDate = serpRows.rows[serpRows.rows.length - 1].calendar.val();
      if (previousDate) {
        previousDate = new Date(new Date(previousDate).getTime() + (1 * 24 * 60 * 60 * 1000));
        newRow.setMinDate(previousDate);
      }
      return serpRows.push(newRow);
    });
  };
  SearchRow = (function() {
    function SearchRow() {
      var that;
      this.city = null;
      this.date = null;
      this.activated = false;
      this.hotelsCollection = [];
      this.flightsCollection = [];
      this.parentElement = $("#mainContainer");
      this.hotelItemHtml = $('#hotelItem').html();
      this.flightItemHtml = $('#flightItem').html();
      this.html = $($("#searchRowTemplate").html());
      this.parentElement.append(this.html);
      this.html.hide();
      this.html.fadeIn(500);
      this.hotels = this.html.find('.hotels');
      this.flights = this.html.find('.flights');
      this.picture = this.html.find("div.image");
      this.hello = this.html.find('.splash');
      this.cheepFlight = 0.0;
      this.bestFlight = 0.0;
      this.bestValueFlight = 0.0;
      this.averageFlight = 0.0;
      this.cheepHotel = 0.0;
      this.bestHotel = 0.0;
      this.bestValueHotel = 0.0;
      this.averageHotel = 0.0;
      that = this;
      this.calendar = this.html.find(".calendar");
      this.calendar.datepicker({
        weekStart: 1,
        dateFormat: "yy-mm-dd",
        minDate: new Date(new Date().getTime() + (2 * 24 * 60 * 60 * 1000)),
        beforeShow: function(input, inst) {
          var cal, delta, marginTop;
          delta = $(window).height() - $(input).offset().top;
          if (delta > 205) {
            marginTop = -48;
          } else {
            marginTop = 48;
          }
          cal = $("#ui-datepicker-div");
          cal.css('margin-top', marginTop);
          return {
            onSelect: function(dateText, inst) {
              return that.onSelect({
                date: dateText,
                type: 'date'
              });
            }
          };
        }
      });
      this.autocomplete = this.html.find(".geo_autocomplete");
      this.autocomplete.autocomplete({
        source: function(req, res) {
          return $.ajax({
            url: "/api/v1/autocomplete/" + req.term,
            success: function(data) {
              if (!data.value) {
                return;
              }
              return res($.map(data.value, function(item) {
                return {
                  label: item.name,
                  oid: item.oid,
                  iata: item.iata
                };
              }));
            }
          });
        },
        select: function(event, item) {
          that.onSelect({
            city: item.item,
            type: 'city'
          });
          return that.setBackground(item.item.label);
        }
      });
    }
    SearchRow.prototype.showStats = function() {
      var stats;
      stats = this.html.find('.stats');
      if (!stats.is(":visible")) {
        stats.hide();
        stats.html($('#stats').html());
        return stats.fadeIn(500);
      }
    };
    SearchRow.prototype.hind = function(data) {
      return this.html.find('.stats').hide();
    };
    SearchRow.prototype.setMinDate = function(date) {
      return this.html.find(".calendar").datepicker("option", "minDate", date);
    };
    SearchRow.prototype.setMaxDate = function(date) {
      return this.html.find(".calendar").datepicker("option", "maxDate", date);
    };
    SearchRow.prototype.showTeaser = function() {
      return this.html.find('.stats').parent().prepend($('#teaser').html());
    };
    SearchRow.prototype.hindTeaser = function() {
      this.html.find('.teaser').fadeOut(500);
      $("#navbar").fadeIn(1000);
      $("#ads").fadeIn(1000);
      return $(".plus").fadeIn(1000);
    };
    SearchRow.prototype.displayHotels = function() {
      var average, bestRating, bestValue, cheepest, hotel, html, stars, _i, _len, _ref, _ref2, _results;
      if (this.hotelsCollection.length === 0) {
        return;
      }
      bestRating = _.max(this.hotelsCollection, function(elem) {
        return elem.weightedRating;
      });
      bestRating.description = 'лучший рейтинг';
      bestRating["class"] = '';
      cheepest = _.min(this.hotelsCollection, function(elem) {
        return elem.price;
      });
      cheepest.description = 'самый дешевый';
      cheepest["class"] = '';
      average = _.max(_.filter(this.hotelsCollection, function(elem) {
        return elem.price <= (cheepest.price + bestRating.price) / 2;
      }), function(elem) {
        return elem.weightedRating;
      });
      average.description = 'средний';
      average["class"] = '';
      if (((_ref = this.bestVariant) != null ? _ref.hotel : void 0) != null) {
        bestValue = this.bestVariant.hotel;
      } else {
        bestValue = _.max(_.filter(this.hotelsCollection, function(elem) {
          return bestRating.price > elem.price;
        }), function(elem) {
          return elem.weightedRating / elem.price;
        });
      }
      bestValue.description = 'цена/качество';
      bestValue["class"] = 'bestValueMatch';
      this.cheepHotel = cheepest.price;
      this.bestHotel = bestRating.price;
      this.bestValueHotel = bestValue.price;
      this.averageHotel = average.price;
      this.hindTeaser();
      this.hotels.empty();
      this.hotels.parent().parent().addClass('dest-item');
      this.hotels.parent().fadeIn(1000);
      this.hotels.empty();
      _ref2 = _.uniq(_.sortBy([bestRating, cheepest, average, bestValue], function(elem) {
        return elem.price;
      }));
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        hotel = _ref2[_i];
        stars = new Array(hotel.stars).join("★");
        html = this.hotelItemHtml.replace('%price%', utils.addCommas(Math.ceil(hotel.price))).replace('%name%', hotel.name).replace('%room%', hotel.room).replace('%stars%', "" + stars).replace('%url%', hotel.url).replace('%description%', hotel.description);
        html = $(html);
        if (hotel["class"] != null) {
          html.addClass(hotel["class"]);
        }
        _results.push(this.hotels.append(html));
      }
      return _results;
    };
    SearchRow.prototype.addHotels = function(hotels) {
      var bestRating, hotel, _i, _j, _len, _len2, _ref, _results;
      for (_i = 0, _len = hotels.length; _i < _len; _i++) {
        hotel = hotels[_i];
        hotel.price = parseFloat(hotel.price);
      }
      this.hotelsCollection = this.hotelsCollection.concat(hotels);
      bestRating = _.max(this.hotelsCollection, function(elem) {
        return elem.rating;
      }).rating;
      _ref = this.hotelsCollection;
      _results = [];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        hotel = _ref[_j];
        _results.push(hotel.weightedRating = 0.2 * ((hotel.stars - 1) / 5.0) + 0.8 * (hotel.rating / bestRating || 0));
      }
      return _results;
    };
    SearchRow.prototype.displayFlights = function() {
      var average, bestValue, cheepest, fastest, flight, flights, html, pluralHours, pluralTransfers, timespanString, transferString, _i, _len, _ref, _ref2, _results;
      if (this.flightsCollection.length === 0) {
        return;
      }
      fastest = _.max(this.flightsCollection, function(elem) {
        return elem.weightedRating;
      });
      fastest.description = 'самый быстрый';
      fastest["class"] = '';
      cheepest = _.min(this.flightsCollection, function(elem) {
        return elem.price;
      });
      cheepest.description = 'самый дешевый';
      cheepest["class"] = '';
      average = _.min(_.filter(this.flightsCollection, function(elem) {
        return elem !== cheepest;
      }), function(elem) {
        return elem.price;
      });
      average.description = 'средний';
      average["class"] = '';
      if (((_ref = this.bestVariant) != null ? _ref.flight : void 0) != null) {
        bestValue = this.bestVariant.flight;
      } else {
        bestValue = _.max(_.filter(this.flightsCollection, function(elem) {
          return elem.price <= 1.2 * (cheepest.price + fastest.price) / 2;
        }), function(elem) {
          return elem.weightedRating;
        });
      }
      bestValue.description = 'цена/качество';
      bestValue["class"] = 'bestValueMatch';
      this.cheepFlight = cheepest.price;
      this.bestFlight = fastest.price;
      this.bestValueFlight = bestValue.price;
      this.averageFlight = average.price;
      flights = _.uniq([fastest, cheepest, bestValue, average]);
      if (flights.length === 1) {
        flights[0].description = 'единственный';
      }
      this.hindTeaser();
      this.flights.empty();
      _ref2 = _.sortBy(flights, function(elem) {
        return elem.price;
      });
      _results = [];
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        flight = _ref2[_i];
        pluralHours = utils.pluralize(flight.timeSpan, "часов", "час", "часа");
        timespanString = "" + flight.timeSpan + " " + pluralHours;
        if (flight.transferNumber !== 0) {
          pluralTransfers = utils.pluralize(flight.transferNumber, "пересадок", "пересадка", "пересадки");
          transferString = "" + flight.transferNumber + " " + pluralTransfers;
        } else {
          transferString = "Прямой рейс";
        }
        html = this.flightItemHtml.replace('%price%', utils.addCommas(flight.price)).replace('%arrival%', flight.arrival).replace('%departure%', flight.departure).replace('%timeSpan%', timespanString).replace('%transferNumber%', transferString).replace('%url%', flight.url).replace('%description%', flight.description);
        html = $(html);
        if (flight["class"] != null) {
          html.addClass(flight["class"]);
        }
        _results.push(this.flights.append(html));
      }
      return _results;
    };
    SearchRow.prototype.addFlights = function(flights) {
      var flight, minSpan, _i, _len, _ref, _results;
      this.flightsCollection = this.flightsCollection.concat(flights);
      minSpan = _.min(this.flightsCollection, function(elem) {
        return elem.timeSpan;
      }).timeSpan;
      _ref = this.flightsCollection;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        flight = _ref[_i];
        _results.push(flight.weightedRating = minSpan.toFixed(2) / flight.timeSpan);
      }
      return _results;
    };
    SearchRow.prototype.setBackground = function(term) {
      var that;
      that = this;
      return $.ajax({
        url: "/api/v1/image/" + term,
        success: function(data) {
          if (data.status === "ok") {
            that.picture.css('background', "url('" + data.value.image + "') no-repeat center #000");
            that.html.find("input.calendar").css('background-color', '#000');
            return that.html.find("input.geo_autocomplete").css('background-color', '#000');
          }
        }
      });
    };
    SearchRow.prototype.showHotelsLoading = function() {
      return this.hotels.html($('#loading').html());
    };
    SearchRow.prototype.showFlightsLoading = function() {
      return this.flights.html($('#loading').html());
    };
    SearchRow.prototype.onSelect = function(data) {
      var secondRow;
      if (data.city) {
        this.city = data.city;
      }
      if (data.date) {
        this.date = data.date;
      }
      if (!this.city || !this.date) {
        return;
      }
      this.activated = true;
      if ((this.isFirstRow != null) && serpRows.rows.length === 1) {
        secondRow = new SearchRow;
        serpRows.push(secondRow);
        secondRow.calendar.attr('placeholder', 'когда обратно');
        secondRow.autocomplete.attr('placeholder', 'куда');
      }
      this.hotelsCollection = [];
      this.flightsCollection = [];
      if (this.rowCollectionCallback) {
        return this.rowCollectionCallback(data);
      }
    };
    return SearchRow;
  })();
  SearchRowCollection = (function() {
    function SearchRowCollection() {
      var that;
      this.rows = [];
      this.numAdults = 2;
      this.maxPrice = 100000;
      this.currentSignature = '';
      that = this;
      $("#numAdults").change(function() {
        that.numAdults = parseInt($("#numAdults").val());
        return that.refreshSearch();
      });
      $("#maxPrice").change(function() {
        that.maxPrice = parseInt($("#maxPrice").val());
        that.findBestCombination();
        return that.calculateStatistics();
      });
    }
    SearchRowCollection.prototype.push = function(row) {
      var rowNumber;
      rowNumber = this.rows.length;
      this.rows.push(row);
      return row.rowCollectionCallback = __bind(function(data) {
        return this.onRowSelection(rowNumber, data);
      }, this);
    };
    SearchRowCollection.prototype.findBestCombination = function() {
      var bestCandidate, blocks, i, row, _i, _j, _len, _len2, _ref, _results;
      blocks = _.map(this.rows, function(elem) {
        return {
          hotels: elem.hotelsCollection,
          flights: elem.flightsCollection
        };
      });
      bestCandidate = fiddle.findBestCombination(blocks, this.maxPrice);
      i = 0;
      for (_i = 0, _len = bestCandidate.length; _i < _len; _i++) {
        row = bestCandidate[_i];
        this.rows[i].bestVariant = bestCandidate[i];
        i += 1;
      }
      _ref = this.rows;
      _results = [];
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        row = _ref[_j];
        row.displayFlights();
        _results.push(row.displayHotels());
      }
      return _results;
    };
    SearchRowCollection.prototype.calculateStatistics = function() {
      var average, best, bestValue, cheep, row, _i, _len, _ref;
      this.rows[0].showStats();
      cheep = 0.0;
      average = 0.0;
      bestValue = 0.0;
      best = 0.0;
      _ref = this.rows;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        cheep += row.cheepHotel + row.cheepFlight;
        average += row.averageHotel + row.averageFlight;
        bestValue += row.bestValueHotel + row.bestValueFlight;
        best += row.bestHotel + row.bestFlight;
      }
      this.rows[0].html.find('.inner-stats span.cheep').html(utils.addCommas(Math.ceil(cheep)));
      this.rows[0].html.find('.inner-stats span.average').html(utils.addCommas(Math.ceil(average)));
      this.rows[0].html.find('.inner-stats span.bestValue').html(utils.addCommas(Math.ceil(bestValue)));
      this.rows[0].html.find('.inner-stats span.best').html(utils.addCommas(Math.ceil(best)));
      return this.rows[0].showStats();
    };
    SearchRowCollection.prototype.makeSignature = function() {
      var row, signature, _i, _len, _ref;
      signature = "" + this.numAdults;
      _ref = this.dataRows;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        signature += "" + row.origin.iata + ":" + row.origin.date + "-" + row.destination.iata + ":" + row.destination.date;
      }
      return signature;
    };
    SearchRowCollection.prototype.startSearch = function() {
      if (this.dataRows.length > 0) {
        this.currentSignature = this.makeSignature();
        return serp.startSearch(this.dataRows, {
          adults: this.numAdults
        }, this.currentSignature);
      }
    };
    SearchRowCollection.prototype.refreshSearch = function() {
      var row, _i, _len, _ref;
      _ref = this.rows;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        row.showHotelsLoading();
        row.showFlightsLoading();
        row.hotelsCollection = [];
        row.flightsCollection = [];
        row.bestVariant = null;
      }
      return this.startSearch();
    };
    SearchRowCollection.prototype.onRowSelection = function(rowNumber, row) {
      var i, nextDate, previosDate, _ref;
      if (this.rows.length < 2) {
        return;
      }
      if (rowNumber !== (this.rows.length - 1)) {
        nextDate = new Date(new Date(row.date).getTime() + (1 * 24 * 60 * 60 * 1000));
        this.rows[rowNumber + 1].setMinDate(nextDate);
      }
      if (rowNumber !== 0) {
        previosDate = new Date(new Date(row.date).getTime() - (1 * 24 * 60 * 60 * 1000));
        this.rows[rowNumber - 1].setMaxDate(previosDate);
      }
      this.dataRows = [];
      for (i = 0, _ref = this.rows.length - 2; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        if (this.rows[i].activated && this.rows[i + 1].activated) {
          this.dataRows.push({
            origin: {
              iata: this.rows[i].city.iata,
              oid: this.rows[i].city.oid,
              date: this.rows[i].date
            },
            destination: {
              iata: this.rows[i + 1].city.iata,
              oid: this.rows[i + 1].city.oid,
              date: this.rows[i + 1].date
            }
          });
          this.rows[0].hindTeaser();
          this.rows[i].flights.parent().fadeIn(1000);
          this.rows[i].flights.parent().parent().addClass('dest-item');
          this.rows[i].hotels.parent().fadeIn(1000);
          this.rows[i].hotels.parent().parent().addClass('dest-item');
          this.rows[i + 1].flights.parent().fadeIn(1000);
          this.rows[i + 1].flights.parent().parent().addClass('dest-item');
        }
      }
      if (rowNumber >= 1) {
        this.rows[rowNumber - 1].showHotelsLoading();
        this.rows[rowNumber - 1].flightsCollection = [];
        this.rows[rowNumber - 1].bestVariant = null;
        if (row.type === 'city') {
          this.rows[rowNumber - 1].hotelsCollection = [];
          this.rows[rowNumber - 1].showFlightsLoading();
        }
      }
      this.rows[rowNumber].bestVariant = null;
      this.rows[rowNumber].showFlightsLoading();
      this.rows[rowNumber].showHotelsLoading();
      return this.startSearch();
    };
    return SearchRowCollection;
  })();
  SocketSERP = (function() {
    function SocketSERP(funcs) {
      this.socket = io.connect('http://ostroterra.com:1488/');
      this.socket.on('hotels_ready', function(data) {
        return funcs.onHotelsReady(data);
      });
      this.socket.on('flights_ready', function(data) {
        return funcs.onFlightsReady(data);
      });
    }
    SocketSERP.prototype.startSearch = function(rows, extra, signature) {
      return this.socket.emit('start_search', {
        rows: rows,
        extra: extra,
        signature: signature
      });
    };
    return SocketSERP;
  })();
  jQuery(document).ready(function() {
    return main();
  });
}).call(this);
