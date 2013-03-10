HotelOverlay = Backbone.View.extend
  className: 'v-hoteloverlay-wrap'

  initialize: (@opts)->
    @render()

    app.log('[app.views.HotelOverlay]: initialize')

  # events:

  show: (data)->
    # update overlay with new data

    app.overlay.show(block: '.l-o-hotel')

  hide: ->
    app.overlay.hide()

  render: ->
    @$el.html(app.templates.hotel_overlay())

    app.overlay.add(@$el, '.l-o-hotel')
    @$el.css(height: app.size.height - 100)

  destroy: ->
    @undelegateEvents()
    app.overlay.remove('.l-o-hotel')

    app.log('[app.views.HotelOverlay]: destroyed')

app.views.HotelOverlay = HotelOverlay
