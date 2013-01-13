// Generated by CoffeeScript 1.4.0
(function() {
  var Index;

  Index = Backbone.View.extend({
    el: '#page-index .block-current',
    initialize: function() {
      this.searchFormView = new app.views.SearchForm({
        el: this.el,
        model: this.model,
        collection: this.model.get('trips')
      });
      this.render();
      app.log('[app.views.Index]: initialize');
      return this;
    },
    render: function() {
      this.$el.hide();
      this.$el.fadeIn(500);
      return this;
    }
  });

  app.views.Index = Index;

}).call(this);