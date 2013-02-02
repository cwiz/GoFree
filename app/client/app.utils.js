app.browser = {
    isOpera: ('opera' in window),
    isFirefox: (navigator.userAgent.indexOf('Firefox') !== -1),
    isIOS: (function() {
        if (!$.os.ios) {
            return false;
        }

        if(/OS [2-4]_\d(_\d)? like Mac OS X/i.test(navigator.userAgent)) {
            return navigator.userAgent.match(/OS ([2-4])_\d(_\d)? like Mac OS X/i)[1];
        } else if(/CPU like Mac OS X/i.test(navigator.userAgent)) {
            return 1;
        } else {
            return navigator.userAgent.match(/OS ([5-9])(_\d)+ like Mac OS X/i)[1];
        }

        return 0;
    })(),
    isAndroid: $.os.android ? parseInt(/Android\s([\d\.]+)/g.exec(navigator.appVersion)[1], 10) : false,
    isIE: (function() {
        if (!!document.all) {
            if (!!window.atob) return 10;
            if (!!document.addEventListener) return 9;
            if (!!document.querySelector) return 8;
            if (!!window.XMLHttpRequest) return 7;
        }

        return false;
    })(),
    isTouchDevice: $.os.touch
};
app.now = new Date();

// Global utility functions
app.log = function() {
    if (app.env.debug && 'console' in window) {
        (arguments.length > 1) ? console.log(Array.prototype.slice.call(arguments)) : console.log(arguments[0]);
    }
};
app.plog = function(o) {
    if (app.env.debug && 'console' in window) {
        var out = '';
        for (var p in o) {
           out += p + ': ' + o[p] + '\n';
        }
        console.log(out);
    }
};
app.e = function(e) {
    (typeof e.preventDefault === 'function') && e.preventDefault();
    (typeof e.stopPropagation === 'function') && e.stopPropagation();
};
(function() {
    var _storageInterface = function(storageName) {
        var hasStorage = (function() {
                try {
                    return !!window[storageName].getItem;
                } catch(e) {
                    return false;
                }
            }()),
            session = (storageName === 'sessionStorage'),
            storage = window[storageName];

        if (hasStorage) {
            return {
                set: function(key, val) {
                    storage.setItem(key, JSON.stringify(val));
                },
                get: function(key) {
                    var data = storage.getItem(key);
                    return data ? JSON.parse(data) : null;
                },
                has: function(key) {
                    return !!storage.getItem(key);
                },
                remove: function(key) {
                    storage.removeItem(key);
                }
            };
        }
        else {
            return {
                set: function(key, val) {
                    $.cookie(key, JSON.stringify(val), session ? undefined : { expires: 365 });
                },
                get: function(key) {
                    var data = $.cookie(key);
                    return data ? JSON.parse(data) : null;
                },
                has: function(key) {
                    return !!$.cookie(key);
                },
                remove: function(key) {
                    $.cookie(key, null);
                }
            };
        }
    };

    app.store = _storageInterface('localStorage');
    app.sstore = _storageInterface('sessionStorage');
})();

app.utils = {};

app.utils.capfirst = function (string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
};

app.utils.makeEnding = function(number, wordForms) {
    var order = number % 100;

    if ((order > 10 && order < 20) || (number === 0)) {
        return wordForms[2];
    }
    else {
        switch (number % 10) {
            case 1: return wordForms[0];
            case 2:
            case 3:
            case 4: return wordForms[1];
            default: return wordForms[2];
        }
    }
};
// Just like the Django filter
app.utils.choosePlural = function (number, endings) {
    return number + ' ' + app.utils.makeEnding.apply(this, arguments);
};

app.utils.shortenString = function (str, len, pos) {
    var lim = ((len - 3) / 2) | 0,
        res = str;

    if (str.length > len) {
        switch(pos) {
            case 'left':
                res = '...' + str.slice(3 - len);
                break;
            case 'right':
                res = str.slice(0, len - 3) + '...';
                break;
            default:
                res = str.slice(0, lim) + '...' + str.slice(-lim);
                break;
        }
    }

    return res;
};

app.utils.sanitizeString = function(str) {
    return $('<div/>').text(str).html();
};

(function(){
    var _supportsInterface = function(isRaw) {
        var div = document.createElement('div'),
            vendors = 'Ms O Moz Webkit'.split(' '),
            len = vendors.length,
            memo = {};

        return function(prop) {
            var key = prop;

            if (typeof memo[key] !== 'undefined') {
                return memo[key];
            }

            if (typeof div.style[prop] !== 'undefined') {
                memo[key] = prop;
                return memo[key];
            }

            prop = prop.replace(/^[a-z]/, function(val) {
                return val.toUpperCase();
            });

            for (var i = len - 1; i >= 0; i--) {
                if (typeof div.style[vendors[i] + prop] !== 'undefined') {
                    if (isRaw) {
                        memo[key] = ('-' + vendors[i] + '-' + prop).toLowerCase();
                    }
                    else {
                        memo[key] = vendors[i] + prop;
                    }
                    return memo[key];
                }
            }

            return false;
        };
    };

    app.utils.supports = _supportsInterface(false);
    app.utils.__supports = _supportsInterface(true);
})();

app.utils.translate = function() {
    if (app.browser.isAndroid && app.browser.isAndroid >= 4) {
        return function(x, y) {
            return 'translate3d(' + x + ', ' + y + ', 0)';
        };
    }
    
    if (!app.browser.isIOS) {
        return function(x, y) {
            return 'translate(' + x + ', ' + y + ')';
        };
    }
    else {
        return function(x, y) {
            return 'translate3d(' + x + ', ' + y + ', 0)';
        };
    }
}();

app.utils.scroll = function(pos, duration, callback) {
    $('html, body').animate({
        scrollTop: pos || 0
    }, duration, callback || void 0);
};

app.utils.isPopupBlocked = function (poppedWindow) {
    var result = false;

    try {
        if (typeof poppedWindow == 'undefined') {
            // Safari with popup blocker... leaves the popup window handle undefined
            result = true;
        }
        else if (poppedWindow && poppedWindow.closed) {
            // This happens if the user opens and closes the client window...
            // Confusing because the handle is still available, but it's in a "closed" state.
            // We're not saying that the window is not being blocked, we're just saying
            // that the window has been closed before the test could be run.
            result = false;
        }
        else if (poppedWindow && poppedWindow.S) {
            // This is the actual test. The client window should be fine.
            result = false;
        }
        else {
            // Else we'll assume the window is not OK
            result = true;
        }

    } catch (err) {
        //if (console) {
        //    console.warn("Could not access popup window", err);
        //}
    }

    return result;
};

app.utils.parseURL = function (url) {
    var a =  document.createElement('a');
    a.href = url;
    return {
        source: url,
        protocol: a.protocol.replace(':',''),
        host: a.hostname,
        port: a.port,
        query: a.search,
        params: (function() {
            var ret = {},
                seg = a.search.replace(/^\?/,'').split('&'),
                len = seg.length, i = 0, s;
            for (; i < len; i++) {
                if (!seg[i]) { continue; }
                s = seg[i].split('=');
                ret[s[0]] = s[1];
            }
            return ret;
        })(),
        file: (a.pathname.match(/\/([^\/?#]+)$/i) || [,''])[1],
        hash: a.hash.replace('#',''),
        path: a.pathname.replace(/^([^\/])/,'/$1'),
        relative: (a.href.match(/tps?:\/\/[^\/]+(.+)/) || [,''])[1],
        segments: a.pathname.replace(/^\//,'').split('/')
    };
};

// Price, wrapper, num of remainder chars, delimeter and thousands delimeter
app.utils.formatNum = function(p, w, c, d, t) {
    var n = isNaN(+p) ? 0 : +p,
        c = (typeof c === 'undefined') ? 0 : c,
        d = (typeof d === 'undefined') ? "." : d,
        t = (typeof t === 'undefined') ? " " : t,
        s = n < 0 ? '-' : '',
        i = parseInt(n = Math.abs(+n || 0).toFixed(c), 10) + "",
        j = (j = i.length) > 3 ? j % 3 : 0,
        r;

    if (typeof w === 'string' && w.length > 0) {
        r = s + (j ? i.substr(0, j) + t : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, '$1' + t) + '<' + w + '>' + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : '') + '<\/' + w + '>';
    }
    else {
        r = s + (j ? i.substr(0, j) + t : '') + i.substr(j).replace(/(\d{3})(?=\d)/g, '$1' + t) + (c ? d + Math.abs(n - i).toFixed(c).slice(2) : '');
    }
    
    return r;
};
app.utils.monthLabels = ['январь', 'февраль', 'март', 'апрель',
                           'май', 'июнь', 'июль', 'август', 'сентябрь',
                           'октябрь', 'ноябрь', 'декабрь'];
app.utils.monthLabelsAlt = ['января', 'февраля', 'марта', 'апреля',
                           'мая', 'июня', 'июля', 'августа', 'сентября',
                           'октября', 'ноября', 'декабря'];

app.utils.pureDate = function(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
};
app.utils.dateToYMD = function(date) {
    return date.getFullYear() + '-' + ('0' + (date.getMonth() + 1)).slice(-2) + '-' + ('0' + date.getDate()).slice(-2);
};
app.utils.YMDToDate = function(ymd) {
    var darr = ymd.split('-');
    return new Date(+darr[0], +darr[1] - 1, +darr[2]);
};
app.utils.YMDToDateMonth = function(ymd) {
    var darr = ymd.split('-');
    return new Date(+darr[0], +darr[1] - 1, 1);
};
app.utils.getWeeksNum = function(year, month) {
    var daysNum = app.utils.getDaysNum(year, month),
        fDayO = new Date(year, month, 1).getDay(),
        fDay = fDayO ? (fDayO - 1) : 6,
        weeksNum = Math.ceil((daysNum + fDay) / 7);
    return weeksNum;
};
app.utils.getDaysNum = function(year, month) { // nMonth is 0 thru 11
    return 32 - new Date(year, month, 32).getDate();
};
app.utils.extractDate = function(date) {
    if (typeof date === 'number') {
        date = new Date(date);
    }
    if (typeof date === 'string') {
        date = app.utils.YMDToDate(date);
    }

    return date;
};
app.utils.humanizeDate = function(date) {
    date = app.utils.extractDate(date);
    return date.getDate() + ' ' + app.utils.monthLabelsAlt[date.getMonth()];
};
app.utils.humanizeDatesSpan = function(date1, date2) {
    date1 = app.utils.extractDate(date1);
    date2 = app.utils.extractDate(date2);

    if (date1.getMonth() === date2.getMonth()) {
        return date1.getDate() + ' &ndash; ' + date2.getDate() + ' ' + app.utils.monthLabelsAlt[date2.getMonth()];
    }

    return date1.getDate() + ' ' + app.utils.monthLabelsAlt[date1.getMonth()] + ' &ndash; ' + date2.getDate() + ' ' + app.utils.monthLabelsAlt[date2.getMonth()];
};
app.utils.getDaysDiff = function(date1, date2) {
    return Math.abs((+date1 - +date2) / (1000 * 60 * 60 * 24));
};
app.utils.getHoursDiff = function(date1, date2) {
    return Math.abs((+date1 - +date2) / (1000 * 60 * 60));
};
app.utils.getMinutesDiff = function(date1, date2) {
    return Math.abs((+date1 - +date2) / (1000 * 60));
};
app.utils.getSecondsDiff = function(date1, date2) {
    return Math.abs((+date1 - +date2) / (1000));
};
app.utils.humanizeDuration = function(ts) {
    var diff = ts / 60,
        hours = Math.floor(diff / 60),
        minutes = diff % 60;

    if (minutes) {
        return hours + ' ч. ' + minutes + ' мин.';
    }

    return hours + ' ч.';
};
app.utils.humanizeTimeSince = function(timestamp) {
    var diff = Math.ceil(app.utils.getSecondsDiff(+new Date(), timestamp));

    if (!diff) {
        return '<span class="f-humanized-date">сейчас</span>';
    }
    if (diff < 60) {
        return '<span class="f-humanized-date"><b>' + diff + '</b> ' + app.utils.makeEnding(diff, ['секунду', 'секунды', 'секунд']) + ' назад</span>';
    }
    if (diff < 60 * 60) {
        diff = Math.ceil(diff / 60);
        return '<span class="f-humanized-date"><b>' + diff + '</b> ' + app.utils.makeEnding(diff, ['минуту', 'минуты', 'минут']) + ' назад</span>';
    }
    if (diff < 60 * 60 * 24) {
        diff = Math.ceil(diff / (60 * 60));
        return '<span class="f-humanized-date"><b>' + diff + '</b> ' + app.utils.makeEnding(diff, ['час', 'часа', 'часов']) + ' назад</span>';
    }

    var date = new Date(timestamp);

    return '<span class="f-humanized-date"><b>' + date.getDate() + '</b> ' + app.utils.monthLabelsAlt[date.getMonth()] + '</span>';
};

if (app.browser.isIE) {
    app.utils.formatDate = function(dateString) {
        var date = new Date((dateString + '').replace('-', '/').replace('T', ' '));
        return date.getDate() + ' ' + app.utils.monthLabelsAlt[date.getMonth()] + ' ' + date.getFullYear();
    };
    app.utils.formatDateSince = function(dateString) {
        return app.utils.humanizeTimeSince(Date.parse((dateString + '').replace('-', '/').replace('T', ' ')));
    };
}
else {
    app.utils.formatDate = function(dateString) {
        var date = new Date(dateString);
        return date.getDate() + ' ' + app.utils.monthLabelsAlt[date.getMonth()] + ' ' + date.getFullYear();
    };
    app.utils.formatDateSince = function(dateString) {
        return app.utils.humanizeTimeSince(typeof dateString === 'number' ? dateString : Date.parse(dateString));
    };
}
app.utils.starMap = [
    '<i class="f-stars">★<s>☆☆☆☆</s></i>',
    '<i class="f-stars">★★<s>☆☆☆</s></i>',
    '<i class="f-stars">★★★<s>☆☆</s></i>',
    '<i class="f-stars">★★★★<s>☆</s></i>',
    '<i class="f-stars">★★★★★</i>'
];
app.utils.formatStars = function(num) {
    return app.utils.starMap[+num - 1];
};
