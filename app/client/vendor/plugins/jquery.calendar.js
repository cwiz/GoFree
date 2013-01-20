//
// jQuery calendar generator by @suprMax
//

(function($){
  $.calendar = function() {
    var cal_days_labels = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'],
        cal_months_labels = ['январь', 'февраль', 'март', 'апрель',
                           'май', 'июнь', 'июль', 'август', 'сентябрь',
                           'октябрь', 'ноябрь', 'декабрь'],
        cal_short_months_labels = ['янв.', 'фев.', 'мар.', 'апр.',
                                 'май', 'июн.', 'июл.', 'авг.', 'сен.',
                                 'окт.', 'ноя.', 'дек.'],
        now = new Date(),
        today = new Date(now.getFullYear(), now.getMonth(), now.getDate()),
        now_time = +now,
        today_time = +today,
        one_day = 86400000; // 1000*60*60*24

    return {
      compiled: null,
      // start: date object
      // s: settings object
      //   s.classes - calendar table classes
      //   s.daylabels - add week day labels at the top?
      generateTable: function(start, s) {
        var month = start.getMonth(),
            year = start.getFullYear(),
            starting_day = start.getDay() ? (start.getDay() - 1) : 6, // Hacking this to make Monday the first day
            month_length = this.getDaysNum(year, month),
            month_name = cal_months_labels[month];

        var html = '<table class="calendar-table' +
                    (s.classes ? (' ' + s.classes) : '') +
                    '" cellspacing="0" cellpadding="0" data-month="' +
                    (month + 1) +
                    '" data-year="' +
                    year +
                    '">';

        if (s.daylabels) {
          html += '<thead><tr><th colspan="4">' +
                  month_name + '<\/th><th class="calendar-year-label" colspan="3">' + year +
                  '<\/th><\/tr><tr>';
      
          for (var i = 0; i <= 6; i++ ) {
            html += '<td class="calendar-day-label' + ((i > 4) ? ' calendar-weekend' : '') + '">' +
                    cal_days_labels[i] +
                    '<\/td>';
          }

          html += '<\/tr><\/thead><tbody><tr>';
        }
        else {
          html += '<tbody><tr>';
        }

        var day = start.getDate(),
            len = Math.ceil((month_length + starting_day) / 7),
            date_time = +start;

        for (var i = 0; i < len; i++) {
          // this loop is for weekdays (cells)
          for (var j = 0; j <= 6; j++) { 
            var valid = (day <= month_length && (i > 0 || j >= starting_day));

            html += '<td class="calendar-day' +
                    ((today_time === date_time) ? ' today' : '') +
                    ((today_time > date_time) ? ' past' : '') + '"' +

                    (valid ? ('data-date="' +
                    year +
                    '-' +
                    ('0' + (month + 1)).slice(-2) +
                    '-' +
                    ('0' + day).slice(-2) + '"') : '') +

                    '><span>';

            if (valid) {
              html += day;
              day++;
            }
            else {
              html += '&nbsp;';
            }
            html += '<\/span><\/td>';
            
            date_time += one_day;
          }
          // stop making rows if we've run out of days
          if (day > month_length) {
            break;
          } else {
            html += '<\/tr><tr>';
          }
        }
        html += '<\/tr><\/tbody><\/table>';

        return html;
      },
      // start - date onject
      // s - settings
      //   s.first_month - is it a first month in a big calendar?
      //   s.monthlabels - add month labels?
      //   s.mlabels_firstday - add month labels to first day of month?
      //   s.daylabels - add weekday labels?
      generateList: function(start, s) {
        var month = start.getMonth(),
            year = start.getFullYear(),
            month_length = this.getDaysNum(year, month);

        var html = '';

        // fill in the days
        var day = start.getDate(),
            date_day = start.getDay(),
            date_time = +start;

        for (; day <= month_length; day++) {
          var firstweek = (day <= 7);

          html += '<li class="calendar-day' +
                  (firstweek && !s.first_month ? ' firstweek' : '') +
                  ((day === 1 && s.first_month) ? ' firstday' : '') +
                  ((s.monthlabels && !s.mlabels_firstday && (date_day === 0) && firstweek) ? ' monthlabel' : '') +
                            ((s.monthlabels && s.mlabels_firstday && (day === 1)) ? ' monthlabel' : '') +
                  ((date_day === 1) ? ' monday' : '') +
                  ((date_day === 0 || date_day === 6) ? ' weekend' : '') +
                          ((today_time === date_time) ? ' today' : '') +
                  ((today_time > date_time) ? ' past' : '') + '"' +
                
                  ((day === 1) ? (' data-started="' +
                  year +
                  '-' +
                  ('0' + (month + 1)).slice(-2) + '"') : '') +
                
                  ' data-date="' +
                  year +
                  '-' +
                  ('0' + (month + 1)).slice(-2) +
                  '-' +
                  ('0' + day).slice(-2) + '"' +
                
                  '><span>' +
                  day +
                          ((s.daylabels) ? '<em>' + cal_days_labels[date_day ? date_day - 1 : 6] + '<\/em>' : '') +
                  '<\/span>' +
                    ((s.monthlabels && !s.mlabels_firstday && (date_day === 0) && firstweek) ? '<strong>' + cal_months_labels[month] + '<\/strong>' : '') +
                    ((s.monthlabels && s.mlabels_firstday && (day === 1)) ? '<strong>' + cal_months_labels[month] + '<\/strong>' : '') +
                  '<\/li>';

          date_time += one_day;

          date_day++;
          (date_day > 6) && (date_day = 0);
        }

        return html;
      },
      // Generate a calendar with specific settings:
      // s.type === 'list' - a list type calendar
      // s.type === 'table' - a table type calendar (default)

      // s.start.year, s.start.month - year and month to start with
      // s.end.year, s.end.month - year and month to finish with

      // s.classes - calendar classes
      // s.nogaps - make a calendar appear without gaps between months (list only)

      // s.save - save result of compilation
      generate: function(s) {
        var e,
            t,
            i,
            fill_cells,
            html ='';

        t = new Date(s.start.year, s.start.month - 1, s.start.day || 1);
        e = new Date(s.end.year, s.end.month);
        
        s.first_month = true;


        if (s.type === 'list') {
          html = '<ul class="calendar-list' +
                (s.classes ? (' ' + s.classes) : '') +
                '">';
              
          if (!s.nogaps) {
            fill_cells = (t.getDay() ? t.getDay() : 7)  - 1;

            for (i = 0; i < fill_cells; i++ ) {
              html += '<li class="empty"><\/li>';
            }
          }
        }

        do {
          if (s.type === 'list') {
            html += this.generateList(t, s);
          }
          else {
            html += this.generateTable(t, s);
          }
          t = new Date(t.getFullYear(), t.getMonth() + 1);
          s.first_month = false;
        } while (+t !== +e);

        if (s.type === 'list') {
          if (!s.nogaps) {
            fill_cells = 7 - (new Date(e - one_day)).getDay();

            if (fill_cells < 7) {
              for(i = 0; i < fill_cells; i++ ){
                html += '<li class="empty"><\/li>';
              }
            }
          }
          html += '<\/ul>';
        }

        if (s.save) {
          this.compiled = html;
        }
    
        return html;
      },
      // utility, get num of days in month
      getDaysNum: function(year, month) { // nMonth is 0 thru 11
        return 32 - new Date(year, month, 32).getDate();
      }
    };
  }();

  var DatesPicker = function(el, settings) {
    this.options = $.extend({
      duration: 200,
      precompiled: true,

      start: new Date(),
      end: new Date()
    }, settings);
    
    this.els = {};
    this.dates = {};

    this.offset = 0;
    this.now = new Date();

    this.isAnimated = false;
    
    this.monthLabels = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    this.monthLabelsAlt = ['января', 'февраля', 'марта', 'апреля',
                           'мая', 'июня', 'июля', 'августа', 'сентября',
                           'октября', 'ноября', 'декабря'];
    
    this.els.input = $(el);

    this.selected = null;

    this.generateDOM();
    this.init();
  };
  DatesPicker.prototype.generateDOM = function() {
    this.dates.start = new Date(this.options.start.getFullYear(), this.options.start.getMonth());
    this.dates.end = new Date(this.options.end.getFullYear(), this.options.end.getMonth());
    this.dates.current = new Date(this.options.start.getFullYear(), this.options.start.getMonth());

    if (this.options.precompiled) {
      this.els.dateList = $($.calendar.compiled);
    }
    else {
      this.els.dateList = $($.calendar.generate({
        start: {
          month: this.dates.start.getMonth() + 1,
          year: this.dates.start.getFullYear()
        },
        end: {
          month: this.dates.end.getMonth() + 1,
          year: this.dates.end.getFullYear()
        },
        type: 'list',
        monthlabels: false
      }));
    }

    this.els.body = $('<span class="m-i-c-selected placeholder" data-placeholder="Дата">Дата</span>' +
                      '<div class="m-i-c-calwrap">' +
                        '<div class="m-i-c-header">' +
                          '<div class="m-i-c-status">' +
                            '<span class="m-i-c-control-up m-i-c-controls">&lt;</span>' +
                            '<span class="m-i-c-control-down m-i-c-controls">&gt;</span>' +
                            '<strong class="m-i-c-month">' +
                              this.monthLabels[this.dates.start.getMonth()] +
                              ' ' +
                              this.dates.start.getFullYear() +
                            '</strong>' +
                          '</div>' +
                          '<ul class="m-i-c-day-labels">' +
                            '<li>Пн</li>' +
                            '<li>Вт</li>' +
                            '<li>Ср</li>' +
                            '<li>Чт</li>' +
                            '<li>Пт</li>' +
                            '<li class="weekend">Сб</li>' +
                            '<li class="weekend">Вс</li>' +
                          '</ul>' +
                        '</div>' +
                        '<div class="m-i-c-datelistwrap"></div>' +
                      '</div>');

    this.els.input.removeClass('m-input-calendar').addClass('m-i-c-input');
    this.els.input.wrap('<div class="m-input-calendar"/>');

    this.els.block = this.els.input.parent();
    
    this.els.datelistHolder = this.els.body.find('.m-i-c-datelistwrap');

    this.els.monthHeader = this.els.body.find('.m-i-c-month');

    this.els.controls = this.els.body.find('.m-i-c-controls');
    this.els.controlUp = this.els.controls.filter('.m-i-c-control-up');
    this.els.controlDown = this.els.controls.filter('.m-i-c-control-down');

    this.els.selected = this.els.body.eq(0);

    this.els.cells = this.els.dateList.children('li[data-date]');

    this.els.datelistHolder.append(this.els.dateList);
    this.els.block.append(this.els.body);
  };
  DatesPicker.prototype.init = function() {
    this.cellHeight = this.els.cells.eq(0).height();
    this.scrollCalendarTo(this.dates.current.getFullYear(), this.dates.current.getMonth(), true);

    this.logic();

    this.els.block.trigger('modready');
  };

  DatesPicker.prototype.logic = function() {
    var that = this,

        current = this.els.input.val();
    
    var handleControls = function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      var el = $(this);
      if (!el.hasClass('disabled') && !that.isAnimated) {
        that.scrollCalendarTo(
          that.dates.current.getFullYear(),
          that.dates.current.getMonth() + (el.hasClass('m-i-c-control-up') ? -1 : 1)
        );
      }
    };
    
    var proxyHandler = function(e) {
      e.preventDefault();
      e.stopPropagation();

      that._handleCells.call(that, this);
    };

    var activateCal = function(e) {
      that.els.block.toggleClass('active');
    };

    var handleBasicClick = function(e) {
      var target = e.target,
          $target = $(target),
          factor = $target.parents('.m-input-calendar').is(that.els.block);

      if (that.els.block.hasClass('active') && !factor) {
        that.els.block.removeClass('active');
      }
    };

    var handleDestroy = function() {
      that.els.controls.off('click', handleControls);
      that.els.dateList.off('click', 'li[data-date]', proxyHandler);
      that.els.selected.off('click', activateCal);
      $(document).off('click', handleBasicClick);
    };
    
    this.els.controls.on('click', handleControls);
    this.els.dateList.on('click', 'li[data-date]', proxyHandler);
    this.els.selected.on('click', activateCal);
    this.els.input.on('focus', activateCal);
    $(document).on('click', handleBasicClick);
    this.els.block.one('moddestroy', handleDestroy);

    current && this._handleCells(this.els.cells.filter('[data-date="' + current + '"]')[0]);
  };

  DatesPicker.prototype.destroy = function() {
    this.els.block.trigger('moddestroy');
  };
      
  DatesPicker.prototype._handleCells = function(elem) {
    var el = $(elem),
        ymd = el.data('date'),

        date = this.YMDToDate(ymd),

        mdate = this.YMDToDateMonth(ymd),
        edate = +mdate,
        ecurr = +this.dates.current;

    if (el.hasClass('past') || el.hasClass('locked')) {
      return;
    }
        
    if (this.selected === ymd) {// Selecting the same date again?
      return;
    }

    if ((edate < ecurr) || (edate > ecurr)) { // edge dates autoscroll
      this.scrollCalendarTo(mdate.getFullYear(), mdate.getMonth(), true);
    }

    this.selectDate(ymd);
    this.els.block.removeClass('active');
    this.els.block.trigger('modchange');

  };
  DatesPicker.prototype.selectDate = function(ymd) {
    var date = this.YMDToDate(ymd);

    this.els.cells.filter('.selected').removeClass('selected');
    this.els.cells.filter('[data-date="' + ymd + '"]').addClass('selected');

    this.selected = ymd;
    this.els.input.val(ymd).trigger('change');

    this.els.selected.removeClass('placeholder');
    this.els.selected.html(date.getDate() + ' ' + this.monthLabelsAlt[date.getMonth()]);
  };
  DatesPicker.prototype.deselectDate = function() {
    this.els.cells.filter('.selected').removeClass('selected');

    this.selected = null;
    this.els.input.val('').trigger('change');

    this.els.selected.addClass('placeholder');
    this.els.selected.html(this.els.selected.data('placeholder'));
  };

  DatesPicker.prototype.checkScrollability = function(next) {
    var enext = +next,
        estart = +this.dates.start,
        eend = +this.dates.end;

    if (this.isAnimated) {
      return false;
    }

    if (enext >= eend) {
      if (enext === eend) {
        this.els.controlDown.addClass('disabled');
      }
      else {
        return false;
      }
    }
    else if (enext <= estart) {
      if (enext === estart) {
        this.els.controlUp.addClass('disabled');
      }
      else {
        return false;
      }
    }
    else {
      this.els.controls.filter('.disabled').removeClass('disabled');
    }
    
    return true;
  };

  // Utility functions
  DatesPicker.prototype.dateToYMD = function(date) {
    return date.getFullYear() + '-' + ('0' + (date.getMonth() + 1)).slice(-2) + '-' + ('0' + date.getDate()).slice(-2);
  };
  DatesPicker.prototype.YMDToDate = function(ymd) {
    var darr = ymd.split('-');
    return new Date(+darr[0], +darr[1] - 1, +darr[2]);
  };
  DatesPicker.prototype.YMDToDateMonth = function(ymd) {
    var darr = ymd.split('-');
    return new Date(+darr[0], +darr[1] - 1, 1);
  };
  DatesPicker.prototype.getWeeksNum = function(year, month) {
    var daysNum = this.getDaysNum(year, month),
        fDayO = new Date(year, month, 1).getDay(),
        fDay = fDayO ? (fDayO - 1) : 6,
        weeksNum = Math.ceil((daysNum + fDay) / 7);
    return weeksNum;
  };
  DatesPicker.prototype.getDaysNum = function(year, month) { // nMonth is 0 thru 11
    return 32 - new Date(year, month, 32).getDate();
  };

  // Behavior functions
  DatesPicker.prototype.setActiveMonth = function(date) {
    var darr = this.dateToYMD(date).split('-');
    this.els.cells.filter('.active').removeClass('active');
    this.els.cells.filter('[data-date^="' + darr[0] + '-' + darr[1] + '"]').addClass('active');
  };
  DatesPicker.prototype.setMonthHeader = function(date) {
    this.els.monthHeader.html(this.monthLabels[date.getMonth()] + ' ' + date.getFullYear());
  };
  DatesPicker.prototype.getHolderHeight = function(date) {
    return this.cellHeight * this.getWeeksNum(date.getFullYear(), date.getMonth()) - 1;
  };
  DatesPicker.prototype.getCalendarPos = function(date) {
    return -((this.els.cells.filter('[data-date="' + this.dateToYMD(date) + '"]').index() / 7) | 0) * this.cellHeight;
  };
  DatesPicker.prototype.animateCalendar = function(date) {
    var that = this;

    this.isAnimated = true;
    
    this.els.dateList.animate({
      top: this.getCalendarPos(date)
    }, this.options.duration, function() {
        that.isAnimated = false;
        that.els.datelistHolder.css({ height: that.getHolderHeight(date) });
    });
    
    this.els.block.trigger('modscrolling', date);
  };
  DatesPicker.prototype.moveCalendar = function(date) {
    this.els.dateList.css({ top: this.getCalendarPos(date) });
    this.els.datelistHolder.css({ height: this.getHolderHeight(date) });
    
    this.els.block.trigger('modmoved', date);
  };

  DatesPicker.prototype.scrollCalendarTo = function(year, month, noAnimation) {
    var next = new Date(year, month);
    
    if (this.checkScrollability(next)) {
      this.setMonthHeader(next);
      this.setActiveMonth(next);
      
      noAnimation ? this.moveCalendar(next) : this.animateCalendar(next);

      this.dates.current = next;
    }
  };
  DatesPicker.prototype.selectRange = function(ymd1, ymd2, selection_class, addOnly) {
    var d1_arr = ymd1.split('-'),
        d2_arr = ymd2.split('-'),
        date1 = new Date(+d1_arr[0], +d1_arr[1] - 1, +d1_arr[2] - 1),// offset this so we can increment in while loop straight away
        date2 = +(new Date(+d2_arr[0], +d2_arr[1] - 1, +d2_arr[2])),
        curr_cell;

    this.els.dateList.detach();

    addOnly || this.els.cells.filter('.' + selection_class).removeClass(selection_class);
    while (+date1 < date2) {
      date1.setDate(date1.getDate() + 1);
      curr_cell = this.els.cells.filter('[data-date="' + this.dateToYMD(date1) + '"]').addClass(selection_class);
    }

    this.els.datelistHolder.append(this.els.dateList);
  };

  DatesPicker.prototype.lockDates = function(ymd1, ymd2) {
    var start = ymd1,
        end = ymd2;

    if (!start) {
      start = this.dateToYMD(this.dates.start);
    }
    if (!end) {
      var tmp = new Date(this.dates.end.getFullYear(), this.dates.end.getMonth() + 1);
      tmp.setDate(-1);
      end = this.dateToYMD(tmp);
    }

    if (this.selected) {
      var startDate = this.YMDToDate(start),
          endDate = this.YMDToDate(end),
          currentDate = this.YMDToDate(this.selected),

          tsStart = +startDate,
          tsEnd = +endDate,
          tsCurrent = +currentDate;

      // selected date is in the locked area, have to deselect
      if ((tsCurrent >= tsStart) && (tsCurrent <= tsEnd)) {
        this.deselectDate();
      }
    }

    // if (ymd1 && ymd2) {
    //   if ((tsCurrent > tsStart) && (tsCurrent < tsEnd)) {
    //     this.deselectDate(); // uncertain what to pick
    //   }
    // }
    // if (!ymd1) {
    //   if (tsCurrent < tsEnd) {
    //     endDate.setDate(endDate.getDate() + 1);
    //     this.selectDate(this.dateToYMD(endDate));
    //   }
    // }

    // if (!ymd2) {
    //   if (tsCurrent > tsStart) {
    //     startDate.setDate(startDate.getDate() - 1);
    //     this.selectDate(this.dateToYMD(startDate));
    //   }
    // }

    this.selectRange(start, end, 'locked', true);
  };

  DatesPicker.prototype.unlockDates = function() {
    this.els.dateList.detach();
    this.els.cells.filter('.locked').removeClass('locked');
    this.els.datelistHolder.append(this.els.dateList);
  };

  DatesPicker.prototype.setAvailable = function(start, end) {
    this.unlockDates();

    this.lockDates(null, start);
    this.lockDates(end, null);
  };

  $.fn.m_inputCalendar = function(settings) {
    var start = new Date(),
        end = new Date(),
        instances = [];

    end.setMonth(start.getMonth() + 6);

    var options = $.extend({
      lazy: false,
      precompiled: true,
      start: start,
      end: end
    }, settings);

    if (options.precompiled && !$.calendar.compiled) {
      $.calendar.generate({
        start: {
          month: options.start.getMonth() + 1,
          year: options.start.getFullYear()
        },
        end: {
          month: options.end.getMonth() + 1,
          year: options.end.getFullYear()
        },
        type: 'list',
        monthlabels: false,
        save: true
      });
    }

    var iterate = function(i, elem) {
      if (elem.tagName.toUpperCase() !== 'INPUT') return;
      instances.push(new DatesPicker(elem, options));
    };

    this.each(iterate);

    return instances;
  };
})(jQuery);
