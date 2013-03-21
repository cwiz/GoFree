HotelOverlay = Backbone.View.extend
  className: 'v-hoteloverlay-wrap'

  initialize: (@opts)->
    @signature = @opts.signature

    # KISSMetrics
    _kmq.push ['record', 'hotel overlay view']

    app.log('[app.views.HotelOverlay]: initialize')

  events:
    'click .v-h-p-prev':    'showSlidePrev'
    'click .v-h-p-next':    'showSlideNext'
    'click .v-h-select':    'selectHotel'

  showSlidePrev: ->
    @carouselEl.jcarousel('scroll', '-=1')

  showSlideNext: ->
    @carouselEl.jcarousel('scroll', '+=1')

  selectHotel: ->
    app.trigger('hotel_overlay_select', 
      signature : @signature
      cid       : @data.hotel.cid
    )
    @hide()

  show: (@data)->
    @render()

    @carouselEl = @$el.find('.v-h-photos')

    @carouselEl.jcarousel()
    app.overlay.show(block: '.l-o-hotel')

  hide: ->
    app.overlay.hide()

  render: ->
    data = _.extend(@data.hotel.toJSON(), nights: @data.nights)
    @$el.html(app.templates.hotel_overlay(data))

    app.overlay.add(@$el, '.l-o-hotel')
    # @$el.css(height: app.size.height - 100)

  destroy: ->
    @undelegateEvents()
    app.overlay.remove('.l-o-hotel')

    app.log('[app.views.HotelOverlay]: destroyed')

app.views.HotelOverlay = HotelOverlay
