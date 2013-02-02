SERPTripRow = Backbone.View.extend

  itemsNum: 3

  initialize: (@opts) ->
    @template = @opts.template

    @carouselEl = @$el.find('.m-carousel')

    @listEl = @$el.find('.m-c-list')
    @counterEl = @$el.find('.v-s-t-c-count')

    @carousel = @carouselEl.m_carousel()[0]

    @counter = 0
    @length = 0
    @rendered = 0

    @collection.on('progress', @progress, @)

    @carouselEl.on('mod_shifted_right', _.bind(@shiftRight, @))
    @carouselEl.on('mod_shifted_left', _.bind(@shiftLeft, @))

    app.log('[app.views.SERPTripRow]: initialize')

  progress: (p)->
    items = if p is 1 then @itemsNum * 2 else @itemsNum
    html = for model in @collection.first(items)
      @render(model)

    @counter = @itemsNum
    @length = @collection.length
    @rendered = items

    @listEl.html(html)
    @counterEl.html(@counter + '/' + @length)

    if p is 1
      @carousel.hardReset()
      @$el.addClass('loaded')

  shiftRight: ->
    @counter += @itemsNum
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
    @counter -= @itemsNum
    @counterEl.html(@counter + '/' + @length)

  render: (model)->
    @template(_.extend(model.toJSON(), { origin: @model.get('origin'), destination: @model.get('destination')}))

app.views.SERPTripRow = SERPTripRow
