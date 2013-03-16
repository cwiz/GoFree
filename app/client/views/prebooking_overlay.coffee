PrebookingOverlay = Backbone.View.extend
  className: 'v-prebooking-wrap'

  initialize: (@opts)->
    @render()

    @containerEl  = @$el.find('.v-p-selected-container')
    @validation   = @$el.find('.v-l-e-inputwrap').m_formValidate()[0]
    @emailInput   = @$el.find('.v-l-e-inputwrap input')

    app.log('[app.views.PrebookingOverlay]: initialize')

  events:
    'valid .v-l-e-inputwrap':         'submitEmail'

  show: ->
    @containerEl.html(app.templates.selected_list(
      selected: @collection.serialize()
      total:  0
      ))
    app.overlay.show(block: '.l-o-prebooking')
    @containerEl.css(height: app.size.height - 100 - @containerEl.position().top)

  submitEmail: (evt, e)->
    app.e(e)

    email = $.trim(@emailInput.val())
    $.ajax(
      url: app.api.email_auth + email
      type: 'get'
      success: =>
        @trigger('confirmed')
      )

  render: ->
    @$el.html(app.templates.prebooking_overlay())

    app.overlay.add(@$el, '.l-o-prebooking')
    @$el.css(height: app.size.height - 100)    

  destroy: ->
    @undelegateEvents()
    app.overlay.remove('.l-o-prebooking')

    delete @collection
    delete @validation

    app.log('[app.views.PrebookingOverlay]: destroyed')

app.views.PrebookingOverlay = PrebookingOverlay
