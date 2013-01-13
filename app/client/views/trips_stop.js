// Generated by CoffeeScript 1.4.0
(function() {
  var TripsStop;

  TripsStop = Backbone.View.extend({
    tagName: 'li',
    className: 'v-t-stop',
    initialize: function(options) {
      this.list = options.list;
      this.render();
      this.suggestEl = this.$el.find('.v-t-s-p-suggestions');
      this.placeInput = this.$el.find('.v-t-s-p-name');
      this.calendar = this.$el.find('input.m-input-calendar').m_inputCalendar();
      app.log('[app.views.TripsStop]: initialize');
      return this;
    },
    events: {
      'click .v-t-s-removestop': 'removeStop',
      'change .m-i-c-input': 'dateChanged',
      'webkitspeechchange .v-t-s-p-name': 'placeChanged',
      'keyup .v-t-s-p-name': 'placeChanged',
      'click .v-t-s-p-suggestion': 'placeSelected'
    },
    dateChanged: function(e) {
      return this.model.set('date', e.target.value);
    },
    placeSelected: function(e) {
      var place;
      place = this.suggestions[+e.target.getAttribute('index')];
      this.model.set('place', place);
      this.placeInput.val(place.name);
      return this.clearSuggest();
    },
    renderSuggest: function(resp) {
      var i, list, o;
      this.suggestions = resp.value;
      list = (function() {
        var _i, _len, _ref, _results;
        _ref = this.suggestions;
        _results = [];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          o = _ref[i];
          _results.push('<li class="v-t-s-p-suggestion" data-index="' + i + '"">' + o.name + '</li>');
        }
        return _results;
      }).call(this);
      this.suggestEl.html(list.join(''));
      return this.suggestEl.addClass('active');
    },
    clearSuggest: function() {
      this.suggestEl.removeClass('active');
      return this.suggestEl.html('');
    },
    placeChanged: _.debounce(function(e) {
      var place;
      place = $.trim(e.target.value);
      return $.ajax({
        url: app.api.places + place,
        success: this.renderSuggest,
        error: this.clearSuggest,
        context: this
      });
    }, 100),
    render: function() {
      this.$el.html(app.templates.trips_stop(this.model.toJSON()));
      return this.list.append(this.$el);
    },
    removeStop: function() {
      this.model.trigger('destroy', this.model);
      this.undelegateEvents();
      this.calendar.destroy();
      delete this.calendar;
      return this.remove();
    }
  });

  app.views.TripsStop = TripsStop;

}).call(this);