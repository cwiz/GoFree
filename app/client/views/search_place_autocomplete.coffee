SearchPlaceAutocomplete = Backbone.View.extend
  tagName: 'li'
  className: 'v-s-t-stop'

  initialize: (options) ->

    @dependantElement = options.dependant
    
    @manageKeypress = _.bind(@manageKeypress, @)
    @manageClick    = _.bind(@manageClick, @)

    @render()

    @suggestActive    = false
    @suggestEl        = @$el.find('.v-s-t-s-p-suggestions')
    @placeInput       = @$el.find('.v-s-t-s-p-name')
    @suggestSelected  = null
    @lastQuery        = null

    @model.on('change:place', @updatePlaceValue, @)
    @updateDependant()

    app.log('[app.views.SearchPlaceAutocomplete]: initialize')
    @

  events:
    'webkitspeechchange .v-s-t-s-p-name'         : 'placeChanged'
    'keyup .v-s-t-s-p-name'                      : 'placeChanged'
    'click .v-s-t-s-p-suggestion'                : 'placeSelected'

  dateChanged: (e) ->
    @model.set('date', e.target.value)
    @$el.find('.v-s-t-s-date').find('.m-validate-error').remove()

  updatePlaceValue: (model, place)->
    name = "#{place.name_ru}, #{place.country_name_ru}"
    
    @placeInput.val name
    @updateDependant(name)
  
  updateDependant: (name) ->  
    if not name
      place = @model.get('place')
      name = "#{place.name_ru}, #{place.country_name_ru}"
      
    @dependantElement.html name

  manageKeypress: (e) ->
    switch e.keyCode
      #up
      when 38, 40
        app.e(e)

        if not @suggestSelected?.length
          @suggestSelected = @suggestEl.find(if e.keyCode == 38 then 'li:last-child' else 'li:first-child')
          @suggestSelected.addClass('selected')
        else
          next = if e.keyCode == 38 then @suggestSelected.prev() else @suggestSelected.next()
          @suggestSelected.removeClass('selected')

          if next.length            
            @suggestSelected = next
            @suggestSelected.addClass('selected')
          else
            @suggestSelected = null

      #enter
      when 13
        app.e(e)

        if @suggestSelected?.length
          place = @suggestions[+@suggestSelected.data('index')]

          @model.set('place', place)

          @suggestSelected = null

          @clearSuggest()
              
  manageClick: (e) ->
    $target = $(e.target)

    if (@suggestActive and not $target.is(@suggestEl) and not $target.is(@placeInput))
      @clearSuggest()

  placeSelected: (e) ->
    place = @suggestions[+e.target.getAttribute('data-index')]
    @model.set('place', place)
    @clearSuggest()

  renderSuggest: (resp) ->
    @suggestions = resp.value
    
    list = for o, i in @suggestions
      """<li class="v-s-t-s-p-suggestion" data-index="#{i}">
            <strong>#{o.name_ru}</strong>, #{o.country_name_ru}
          </li>"""

    @suggestEl.html(list.join(''))

    if not @suggestActive
      @suggestEl.addClass('active')
      @suggestActive = true

      app.dom.doc.on('keydown', @manageKeypress)
      app.dom.doc.on('click', @manageClick)

    @suggestSelected = null


  clearSuggest: ->
    @suggestEl.removeClass('active')
    @suggestActive = false
    @suggestEl.html('')
    
    @lastQuery = null

    app.dom.doc.off('keydown', @manageKeypress);
    app.dom.doc.off('click', @manageClick);

  placeChanged: _.debounce((e) ->
    place = $.trim(e.target.value)
    return unless place.length

    if @model.get('place').name != place and (@lastQuery != place or not @suggestActive)
      $.ajax
        url: app.api.places + place
        success: @renderSuggest
        error: @clearSuggest
        context: @

      @lastQuery = place

  , 100)

  render: ->

    # is there better way to do it?
    name_ru         = @model.get('place').name_ru
    country_name_ru = @model.get('place').country_name_ru
   
    displayName     = if name_ru then "#{name_ru}, #{country_name_ru}" else ''
    @model.set 'displayName', displayName
    
    @$el.html(app.templates.search_place_autocomplete(@model.toJSON()))

  removePlace: ->
    @undelegateEvents()
    @model.trigger('delete', @model)
    @remove()

app.views.SearchPlaceAutocomplete = SearchPlaceAutocomplete
