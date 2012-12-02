# requires
require './jquery-ui'
require './bootstrap'

_       = require './underscore'
utils   = require './utils'
fiddle  = require './tourfiddle'

#
# Main shit
#

serp = null
serpRows = null


main = () ->

  # defaults
  $.datepicker.setDefaults $.datepicker.regional["ru"]

  serp = new SocketSERP 

    checkSignatue: (signature) ->
      return (signature is serpRows.currentSignature)
    
    onHotelsReady: (data) ->
      if not @checkSignatue(data.signature)
        return
      
      serpRows.rows[data.rowNumber].addHotels data.hotels
      serpRows.findBestCombination()
      serpRows.calculateStatistics()
    
    onFlightsReady: (data) ->
      if not @checkSignatue(data.signature)
        return
      
      serpRows.rows[data.rowNumber].addFlights data.flights 
      serpRows.findBestCombination()   
      serpRows.calculateStatistics()

  serpRows  = new SearchRowCollection
  
  # --- 1st row default values
  firstRow  = new SearchRow
  serpRows.push firstRow

  firstRow.calendar.attr      'placeholder', 'когда'
  firstRow.autocomplete.attr  'placeholder', 'откуда'

  firstRow.showTeaser()
  firstRow.isFirstRow = true;

  # --- 2nd row
  #secondRow = new SearchRow
  #serpRows.push secondRow

  #secondRow.calendar.attr     'placeholder', 'когда обратно'
  #secondRow.autocomplete.attr 'placeholder', 'куда'
  
  # add button
  addRowButton = $(".plus p")
  addRowButton.fadeIn(500)
  addRowButton.click ()->
    newRow = new SearchRow() 

    # setting min date 
    previousDate = serpRows.rows[serpRows.rows.length-1].calendar.val()
    
    if previousDate
      previousDate = new Date( new Date(previousDate).getTime() + (1 * 24 * 60 * 60 * 1000) )
      newRow.setMinDate previousDate
    
    serpRows.push newRow

class SearchRow
  constructor: () ->
    # Internals
    @city = null
    @date = null
    @activated = false

    @hotelsCollection = []
    @flightsCollection = []

    @parentElement  = $("#mainContainer")
    @hotelItemHtml  = $('#hotelItem').html()
    @flightItemHtml = $('#flightItem').html()

    # Template
    @html = $($("#searchRowTemplate").html())
    @parentElement.append @html
    @html.hide()
    @html.fadeIn 500

    # Results
    @hotels   = @html.find('.hotels')
    @flights  = @html.find('.flights')

    # Picture 
    @picture  = @html.find("div.image")
    @hello    = @html.find('.splash')

    @cheepFlight        = 0.0
    @bestFlight         = 0.0
    @bestValueFlight    = 0.0
    @averageFlight      = 0.0

    @cheepHotel         = 0.0
    @bestHotel          = 0.0
    @bestValueHotel     = 0.0
    @averageHotel       = 0.0

    # THIS – THAT
    that = @
    
    # Calendar
    @calendar = @html.find(".calendar")
    @calendar.datepicker
      weekStart: 1, 
      dateFormat : "yy-mm-dd"
      minDate: new Date( new Date().getTime() + (2 * 24 * 60 * 60 * 1000) )
      
      beforeShow: (input, inst) ->
        delta = $(window).height() - $(input).offset().top 

        if delta > 205
          marginTop = -48
        else
          marginTop =  48

        cal =  $ "#ui-datepicker-div"
        cal.css 'margin-top', marginTop

        onSelect: (dateText, inst) ->
          that.onSelect
            date: dateText
            type: 'date'

    # Autocomplete
    @autocomplete = @html.find(".geo_autocomplete")
    @autocomplete.autocomplete

      source: (req, res) -> 
        $.ajax
          url: "/api/v1/autocomplete/#{req.term}"
          success: (data) ->

            if not data.value
              return

            res $.map data.value, (item) ->
              label: item.name
              oid: item.oid
              iata: item.iata

      select: (event, item) ->
        that.onSelect
          city: item.item
          type: 'city'

        that.setBackground item.item.label

  showStats: () ->
    stats = @html.find('.stats')

    if not stats.is(":visible")
      stats.hide()
      stats.html($('#stats').html())
      stats.fadeIn(500)

  hind: (data) ->
    @html.find('.stats').hide()

  setMinDate: (date) ->
    @html.find(".calendar").datepicker("option", "minDate", date)

  setMaxDate: (date) ->
    @html.find(".calendar").datepicker("option", "maxDate", date)

  showTeaser: () ->
    @html.find('.stats').parent().prepend($('#teaser').html())

  hindTeaser: () ->
    @html.find('.teaser').fadeOut(500)
    $("#navbar").fadeIn(1000)
    $("#ads").fadeIn(1000)
    $(".plus").fadeIn(1000)

  displayHotels: () ->
    if @hotelsCollection.length is 0
      return 

    bestRating  = _.max @hotelsCollection,  (elem) -> elem.weightedRating
    bestRating.description = 'лучший рейтинг'
    bestRating.class = ''

    cheepest    = _.min @hotelsCollection,  (elem) -> elem.price
    cheepest.description = 'самый дешевый'
    cheepest.class = ''

    average     = _.max( _.filter(@hotelsCollection, (elem) -> elem.price <= (cheepest.price + bestRating.price) / 2), (elem) -> elem.weightedRating )
    average.description = 'средний'
    average.class = ''

    if @bestVariant?.hotel?
      bestValue  = @bestVariant.hotel
    else
      bestValue   = _.max _.filter(@hotelsCollection, (elem) -> bestRating.price > elem.price), (elem) -> elem.weightedRating / elem.price      

    bestValue.description = 'цена/качество'
    bestValue.class = 'bestValueMatch'

    @cheepHotel     = cheepest.price
    @bestHotel      = bestRating.price
    @bestValueHotel = bestValue.price
    @averageHotel   = average.price

    # presentation shit

    @hindTeaser()
    @hotels.empty()
    @hotels.parent().parent().addClass('dest-item')
    @hotels.parent().fadeIn(1000)
    @hotels.empty()

    for hotel in _.uniq(_.sortBy([bestRating, cheepest, average, bestValue], (elem) -> elem.price))
      stars = new Array(hotel.stars).join("★")
      html = @hotelItemHtml
        .replace('%price%', utils.addCommas(Math.ceil(hotel.price)))
        .replace('%name%',  hotel.name)
        .replace('%room%',  hotel.room)
        .replace('%stars%', "#{stars}")
        .replace('%url%',   hotel.url)
        .replace('%description%', hotel.description)
        
      html = $(html)
      if hotel.class?
        html.addClass hotel.class

      @hotels.append html

  addHotels: (hotels) ->
    
    for hotel in hotels
      hotel.price = parseFloat(hotel.price)

    @hotelsCollection = @hotelsCollection.concat hotels

    # todo: refactor recalculate rating
    bestRating = _.max(@hotelsCollection, (elem) -> elem.rating).rating
    for hotel in @hotelsCollection
      hotel.weightedRating = 0.2 * ( (hotel.stars-1) / 5.0) + 0.8 * (hotel.rating / bestRating or 0)


  displayFlights: () ->
    if @flightsCollection.length is 0
      return
    
    fastest                 = _.max  @flightsCollection,  (elem) -> elem.weightedRating
    fastest.description     = 'самый быстрый'
    fastest.class           = ''

    cheepest                = _.min         @flightsCollection,  (elem) -> elem.price
    cheepest.description    = 'самый дешевый'
    cheepest.class          = ''

    average                 = _.min _.filter(@flightsCollection, (elem) -> elem != cheepest),   (elem) -> elem.price
    average.description     = 'средний'
    average.class           = ''

    if @bestVariant?.flight?
      bestValue   = @bestVariant.flight
    else
      bestValue   = _.max _.filter(@flightsCollection, (elem) -> elem.price <= 1.2 * (cheepest.price + fastest.price) / 2), (elem) -> elem.weightedRating
    
    bestValue.description   = 'цена/качество'
    bestValue.class = 'bestValueMatch'

    @cheepFlight        = cheepest.price
    @bestFlight         = fastest.price
    @bestValueFlight    = bestValue.price
    @averageFlight      = average.price

    flights = _.uniq([fastest, cheepest, bestValue, average])
    if flights.length is 1
      flights[0].description = 'единственный'

    # presentation shit
    @hindTeaser()
    @flights.empty()

    for flight in _.sortBy(flights, (elem) -> elem.price)

      pluralHours     = utils.pluralize(flight.timeSpan, "часов", "час", "часа")
      timespanString  = "#{flight.timeSpan} #{pluralHours}"

      if flight.transferNumber != 0
        pluralTransfers = utils.pluralize(flight.transferNumber, "пересадок", "пересадка", "пересадки")
        transferString  = "#{flight.transferNumber} #{pluralTransfers}"
      else
        transferString  = "Прямой рейс"

      html = @flightItemHtml
        .replace('%price%',           utils.addCommas flight.price)
        .replace('%arrival%',         flight.arrival)
        .replace('%departure%',       flight.departure)
        .replace('%timeSpan%',        timespanString)
        .replace('%transferNumber%',  transferString)
        .replace('%url%',             flight.url)
        .replace('%description%',     flight.description)

      html = $(html)

      if flight.class?
        html.addClass flight.class

      @flights.append html

  addFlights: (flights) ->   
    @flightsCollection = @flightsCollection.concat flights
    minSpan = _.min(@flightsCollection, (elem) -> elem.timeSpan).timeSpan

    for flight in @flightsCollection
      flight.weightedRating = minSpan.toFixed(2) / flight.timeSpan 

  setBackground: (term) ->
     that = @
     $.ajax
      url: "/api/v1/image/#{term}"
      success: (data) ->
        if data.status is "ok"      
          that.picture.css('background', "url('#{data.value.image}') no-repeat center #000")
          that.html.find("input.calendar")        .css('background-color', '#000')
          that.html.find("input.geo_autocomplete").css('background-color', '#000')

  showHotelsLoading:  () ->
    @hotels.html  $('#loading').html()
  
  showFlightsLoading: () ->
    @flights.html $('#loading').html()

  onSelect: (data) ->
    if data.city
      @city = data.city

    if data.date
      @date = data.date

    if not @city or not @date
      return

    @activated = true

    if @isFirstRow? and serpRows.rows.length is 1
      secondRow = new SearchRow
      serpRows.push secondRow

      secondRow.calendar.attr     'placeholder', 'когда обратно'
      secondRow.autocomplete.attr 'placeholder', 'куда'


    @hotelsCollection = []
    @flightsCollection = []

    if @rowCollectionCallback
      @rowCollectionCallback data

class SearchRowCollection
  constructor: ->
    @rows = []
    @numAdults = 2
    @maxPrice  = 100000
    @currentSignature = ''

    that = @

    $("#numAdults").change () ->
      that.numAdults = parseInt($("#numAdults").val())
      that.refreshSearch()

    $("#maxPrice").change () ->
      that.maxPrice = parseInt($("#maxPrice").val())
      that.findBestCombination()
      that.calculateStatistics()

  push: (row) ->
    rowNumber = @rows.length
    @rows.push row
    row.rowCollectionCallback = (data) => 
      @onRowSelection rowNumber, data

  findBestCombination: () ->
    
    blocks = _.map @rows, (elem) -> { 
      hotels:   elem.hotelsCollection, 
      flights:  elem.flightsCollection 
    }
        
    bestCandidate = fiddle.findBestCombination blocks, @maxPrice

    i = 0
    for row in bestCandidate
      @rows[i].bestVariant = bestCandidate[i]
      i += 1
    
    for row in @rows
      row.displayFlights()
      row.displayHotels()

  calculateStatistics: () ->
    @rows[0].showStats()

    cheep     = 0.0
    average   = 0.0
    bestValue = 0.0
    best      = 0.0

    for row in @rows
      cheep     += (row.cheepHotel      + row.cheepFlight)
      average   += (row.averageHotel    + row.averageFlight)
      bestValue += (row.bestValueHotel  + row.bestValueFlight)
      best      += (row.bestHotel       + row.bestFlight)

    @rows[0].html.find('.inner-stats span.cheep'    ).html(utils.addCommas(Math.ceil(cheep)))
    @rows[0].html.find('.inner-stats span.average'  ).html(utils.addCommas(Math.ceil(average)))
    @rows[0].html.find('.inner-stats span.bestValue').html(utils.addCommas(Math.ceil(bestValue)))
    @rows[0].html.find('.inner-stats span.best'     ).html(utils.addCommas(Math.ceil(best)))

    @rows[0].showStats()

  makeSignature: () ->
    signature = "#{@numAdults}"

    for row in @dataRows
      signature += "#{row.origin.iata}:#{row.origin.date}-#{row.destination.iata}:#{row.destination.date}"

    return signature

  startSearch: () ->
    if @dataRows.length > 0
        @currentSignature = @makeSignature()
        serp.startSearch @dataRows, { adults: @numAdults }, @currentSignature 

  refreshSearch: () ->
    for row in @rows
      row.showHotelsLoading()
      row.showFlightsLoading()

      row.hotelsCollection  = []
      row.flightsCollection = []
      row.bestVariant       = null

    @startSearch()

  onRowSelection: (rowNumber, row) ->    
    if @rows.length < 2
      return

    if rowNumber != (@rows.length - 1)
      nextDate    = new Date( new Date(row.date).getTime() + (1 * 24 * 60 * 60 * 1000) )
      @rows[rowNumber + 1].setMinDate nextDate

    if rowNumber != 0
      previosDate = new Date( new Date(row.date).getTime() - (1 * 24 * 60 * 60 * 1000) )
      @rows[rowNumber - 1].setMaxDate previosDate

    @dataRows = []
    for i in [0..@rows.length-2] when @rows[i].activated and @rows[i+1].activated

      @dataRows.push
        origin:
          iata: @rows[i  ].city.iata
          oid:  @rows[i  ].city.oid
          date: @rows[i  ].date
        destination:
          iata: @rows[i+1].city.iata
          oid:  @rows[i+1].city.oid
          date: @rows[i+1].date


      # todo -- refactor
      @rows[0].hindTeaser()

      @rows[i].flights.parent().fadeIn(1000)
      @rows[i].flights.parent().parent().addClass('dest-item')
      
      @rows[i].hotels.parent().fadeIn(1000)
      @rows[i].hotels.parent().parent().addClass('dest-item')
      
      @rows[i+1].flights.parent().fadeIn(1000)
      @rows[i+1].flights.parent().parent().addClass('dest-item')

      # end -- todo

    if rowNumber >= 1
      @rows[rowNumber-1].showHotelsLoading()
      @rows[rowNumber-1].flightsCollection = []
      @rows[rowNumber-1].bestVariant = null

      if row.type is 'city'
        @rows[rowNumber-1].hotelsCollection = []
        @rows[rowNumber-1].showFlightsLoading()

    @rows[rowNumber].bestVariant = null
    @rows[rowNumber].showFlightsLoading()
    @rows[rowNumber].showHotelsLoading()

    @startSearch()


class SocketSERP
  constructor: (funcs) ->
    #@socket = io.connect 'http://localhost/'
    @socket   = io.connect 'http://ostroterra.com:1488/'
    
    @socket.on 'hotels_ready',  (data) ->
      funcs.onHotelsReady data

    @socket.on 'flights_ready', (data) ->
      funcs.onFlightsReady data

  startSearch: (rows, extra, signature) ->
    @socket.emit 'start_search'
      rows: rows
      extra: extra
      signature: signature


jQuery(document).ready ->
  main()