SERPTripRow = Backbone.View.extend

  itemsNum: 3
  selected: null

  initialize: (@opts) ->
    @template   = @opts.template
    @signature  = @opts.signature

    @carouselEl = @$el.find('.m-carousel')

    @listEl       = @$el.find('.m-c-list')
    @counterEl    = @$el.find('.v-s-t-c-count')
    @preFiltersEl = @$el.find('.v-s-t-c-prefilters')
    @filtersEl    = @$el.find('.v-s-t-c-filters')

    @carousel   = @carouselEl.m_carousel()[0]

    @counter    = 0
    @length     = 0
    @rendered   = 0
    @progress   = 0

    @collection.on('progress', @newData, @)
    @collection.on('filtered', @update, @)

    @carouselEl.on('mod_shifted_right', _.bind(@shiftRight, @))
    @carouselEl.on('mod_shifted_left', _.bind(@shiftLeft, @))

    app.on('hotel_overlay_select', @selectFromOverlay, @)

    app.log('[app.views.SERPTripRow]: initialize')

  events:
    'click .v-s-t-i-pick'     : 'selectItem'
    'click .v-s-t-i-unpick'   : 'deselectItem'
    'click .v-s-t-c-filter'   : 'setFilter'
    'click .v-s-t-c-prefilter': 'setPreFilter'

  setPreFilter: (e)->
    
    el    = $(e.target)
    data  = 
      signature: @signature
      filter: el.data('filter')

    @preFiltersEl.find('.selected').removeClass('selected')
    el.addClass('selected')

    app.trigger('serp_prefilter', data)

  setFilter: (e)->
    el = $(e.target)
    data = 
      signature: @signature
      filter: el.data('filter')

    @filtersEl.find('.selected').removeClass('selected')
    el.addClass('selected')

    app.trigger('serp_filter', data)

  selectFromOverlay: (data)->
    if @signature == data.signature
      item = @listEl.find('.v-s-t-item[data-cid="' + data.cid + '"]')
      data = 
        signature: @signature
        model: @collection.get(data.cid)

      @selected.removeClass('selected') if @selected

      item.addClass('selected')
      @selected = item

      app.trigger('serp_selected', data)

  selectItem: (e)->
    el = $(e.target)
    item = el.parents('.v-s-t-item')
    data = 
      signature: @signature
      model: @collection.get(item.data('cid'))

    @selected.removeClass('selected') if @selected

    item.addClass('selected')
    @selected = item

    app.trigger('serp_selected', data)

  deselectItem: (e)->
    data = 
      signature: @signature
      model: @collection.get(@selected.data('cid'))

    @selected.removeClass('selected')
    @selected = null
    app.trigger('serp_deselected', data)

  update: ->
    items = if @progress is 1 then @itemsNum * 2 else @itemsNum
    html = for model in @collection.first(items)
      @render(model)

    @length = @collection.length
    @counter = Math.min(@itemsNum, @length)
    @rendered = Math.min(items, @length)

    @listEl.html(html)
    @counterEl.html(@counter + '/' + @length)

    @carousel.hardReset()

    if not @length and @progress is 1
      @$el.addClass('empty')
    else
      @$el.removeClass('empty')

  newData: (@progress)->
    @update()

    if @progress is 1 then @$el.addClass('loaded')

  shiftRight: ->
    @counter = Math.min(@counter + @itemsNum, @length)
    @counterEl.html(@counter + '/' + @length)

    if @rendered < @length
      end = Math.min(@rendered + @itemsNum, @length)
      app.log("[app.views.SERPTripRow]: lazy loading items #{@rendered} - #{end}")

      html = for i in [@rendered...end]
        @render(@collection.at(i))

      @listEl.append(html)

      @rendered = end
      @carousel.reset()

  shiftLeft: ->
    @counter = @counter = Math.max(@counter - @itemsNum, 0)
    @counterEl.html(@counter + '/' + @length)

  render: (model)->
    @template _.extend model.toJSON(),
      origin      : @model.get 'origin'
      destination : @model.get 'destination'
      extra       : @model.get 'extra'
      cid         : model.cid 

  destroy: ->
    @undelegateEvents()

    @collection.off('progress', @newData, @)
    @collection.off('filtered', @update, @)

    @carouselEl.off('mod_shifted_right')
    @carouselEl.off('mod_shifted_left')

    delete @carouselEl
    delete @carousel
    delete @model
    delete @collection
    delete @opts

app.views.SERPTripRow = SERPTripRow
