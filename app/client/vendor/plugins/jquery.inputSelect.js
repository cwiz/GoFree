;(function($) {
  var dropdownSelect = function(i, elem) {
    var sel = $(elem),
        opts = sel.find('option'),
        el,
        label,
        dropdn;

    var createElements = function() {
      var i, l,
          current = sel.val(),
          classes = sel[0].className;

      dropdn = $('<ul class="m-i-s-dropdown"/>');

      for (i = 0, l = opts.length; i < l; i++) {
        dropdn.append('<li' +
          (current === opts[i].value ? ' class="selected"' : '') +
          ' data-value="' + opts[i].value + '">' +
          opts[i].innerHTML);
      }

      dropdn.find('li').eq(0).addClass('first');

      label = $('<span class="m-i-s-label"/>');
      sel[0].className = 'm-i-s-select';

      el = sel.wrap('<div class="m-input-select">').parent();
      el.append(label);
      el.append(dropdn);
    };

    var handleDropDn = function(e) {
      e && e.stopPropagation();
      el.toggleClass('active');
    };

    var handleDropDnOpts = function(e) {
      handleDropDn(e);

      var current = $(this);

      dropdn.find('.selected').removeClass('selected');
      current.addClass('selected');
      sel.val(current.data('value')).trigger('change');
    };

    var handleSelect = function() {
      label.html(opts.filter('[value="' + this.value + '"]').html());
      el.trigger('modselect');
    };

    var handleBasicClick = function(e) {
      var target = e.target,
          $target = $(target);

      if (el.hasClass('active') && !$target.is(dropdn) && !$target.is(label)) {
        handleDropDn(e);
      }
    };

    createElements();
    label.on('click', handleDropDn);
    dropdn.on('click', 'li', handleDropDnOpts);
    sel.on('change', handleSelect);
    $(document).on('click', handleBasicClick);

    handleSelect.call(sel[0]);
  };

  $.fn.m_inputSelect = function(settings) {
      // var options = $.extend({}, settings);
      this.each(dropdownSelect);
  };
})(jQuery);
