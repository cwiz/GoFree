class Overlay
  options: {}
  _isActive: false
  _scrolled: 0

  _preventScroll: =>
    app.dom.win.scrollTop(@_scrolled)

  _handleKeypress: (e)=>
    if e.keyCode is 27
      @hide()

  _handleMisClick: (e)=>
    if $(e.target).is(@holder)
      @hide()

  constructor: (@settings)->
    @$el = $('#l-overlay')
    @holder = @$el.find('.l-overlay-content')
    @parts = @$el.find('.l-o-part')

    @holder.on('click', '.l-overlay-close', @hide)
    @$el.on('click', @_handleMisClick)
    app.dom.doc.on('keydown', @_handleKeypress)

    app.trigger('l_overlay_ready')
    app.log('[app.modules.Overlay]: initialize')

  active: ->
    @_isActive

  show: (@options)->
    return if @_isActive
    app.trigger('l_overlay_beforeshow', @options)

    if @options.block
      @parts.filter('.active').removeClass('active')
      @parts.filter(@options.block).addClass('active')

    @$el.addClass('active')
    @_isActive = true

    @_scrolled = app.dom.win.scrollTop()
    app.dom.win.on('scroll', @_preventScroll)

    app.trigger('l_overlay_show', @options)
    @

  hide: =>
    return unless @_isActive
    app.trigger('l_overlay_beforehide', @options)

    @$el.removeClass('active')
    @_isActive = false

    app.dom.win.off('scroll', @_preventScroll)
  
    app.trigger('l_overlay_hide', @options)
    @

  add: (data, id)->
    if @parts.filter(id).length
      app.log('[app.modules.Overlay]: part "' + id + '" already exists') 
      return @

    el = if typeof data == 'object' then data else $(data)
    el.addClass('l-o-part ' + id.substr(1))

    @holder.append(el)
    @parts = @$el.find('.l-o-part')

    app.trigger('l_overlay_add', data: data, id: id)
    @

  remove: (id)->
    part = @$el.find('.l-o-part' + id)

    if part.length
      part.remove()
      @parts = @$el.find('.l-o-part')
    else
      app.log('[app.modules.Overlay]: part "' + id + '" doesnt exist')

    @

app.modules.Overlay = Overlay
