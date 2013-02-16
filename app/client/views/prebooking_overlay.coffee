PrebookingOverlay = Backbone.View.extend
  className: 'v-prebooking-wrap'

  initialize: (@opts)->
    @render()

    app.log('[app.views.PrebookingOverlay]: initialize')

  show: ->
    app.overlay.show(block: '.l-o-prebooking')

  render: ->
    @$el.html(app.templates.prebooking_overlay())
    app.overlay.add(@$el, '.l-o-prebooking')
    @$el.css(height: app.size.height - 200)

  destroy: ->
    app.overlay.remove('.l-o-prebooking')

    app.log('[app.views.PrebookingOverlay]: destroyed')

app.views.PrebookingOverlay = PrebookingOverlay
