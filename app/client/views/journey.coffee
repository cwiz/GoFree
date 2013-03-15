Journey = Backbone.View.extend
  el: '#l-content'

  initialize: (@opts) ->
    @hash = @opts.hash

    @render()

    @validation = @$el.find('.v-l-e-inputwrap').m_formValidate()[0]
    @emailInput = @$el.find('.v-l-e-inputwrap input')
    @wrapEl = @$el.find('.p-journey')
    
    @collection.setHash(@hash).observe()
    @collection.on 'fetched', @collectionReady,  @
    @collection.on 'error',   @collectionFailed, @

    app.socket.emit('selected_list_fetch', trip_hash: @hash)

    app.log('[app.views.Journey]: initialize with hash: ' + @hash)

  events:
    'click .p-j-h-newsearch':        'newSearch'
    'click .p-j-h-backtoserp':       'repeatSearch'
    'valid .v-l-e-inputwrap':        'submitEmail'

  render: ->
    @$el.html(app.templates.journey())

  submitEmail: (evt, e)->
    app.e(e)

    email = $.trim(@emailInput.val())
    $.ajax(
      url: app.api.email_auth + email
      type: 'get'
      success: =>
        window.location.reload()
      )

  collectionReady: ->

    selected = @collection.serialize()

    # total = 0
    # for trip in selected
    #   total += ((trip.flight?.price or 0) + (trip.hotel?.price or 0))

    @wrapEl.addClass('loaded')
    @wrapEl.find('.p-j-content').html(app.templates.selected_list(
      selected: selected
      # total   : (total or 0)
    ))

  collectionFailed: ->
    @wrapEl.addClass('failed')

  newSearch: ->
    @destroy()
    app.router.navigate('', trigger: true)

  repeatSearch: ->
    app.router.navigate('search/' + @collection._searchHash, trigger: true)
    @destroy()

  destroy: ->
    @undelegateEvents()
    @collection?.off('fetched', @collectionReady, @)
    @collection?.off('error', @collectionFailed, @)

app.views.Journey = Journey
