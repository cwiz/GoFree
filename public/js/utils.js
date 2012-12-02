(function() {
  var clone;
  exports.pluralize = function(number, a, b, c) {
    if (number >= 10 && number <= 20) {
      return a;
    }
    if (number === 1 || number % 10 === 1) {
      return b;
    }
    if (number <= 4 || number % 10 === 4) {
      return c;
    }
    return a;
  };
  exports.delay = function(ms, func) {
    return setTimeout(func, ms);
  };
  exports.addCommas = function(nStr) {
    var rgx, x, x1, x2;
    nStr += '';
    x = nStr.split('.');
    x1 = x[0];
    if (x.length > 1) {
      x2 = '.' + x[1];
    } else {
      x2 = '';
    }
    rgx = /(\d+)(\d{3})/;
    while (rgx.test(x1)) {
      x1 = x1.replace(rgx, '$1' + ' ' + '$2');
    }
    return x1 + x2;
  };
  clone = function(obj) {
    var flags, key, newInstance;
    if (!(obj != null) || typeof obj !== 'object') {
      return obj;
    }
    if (obj instanceof Date) {
      return new Date(obj.getTime());
    }
    if (obj instanceof RegExp) {
      flags = '';
      if (obj.global != null) {
        flags += 'g';
      }
      if (obj.ignoreCase != null) {
        flags += 'i';
      }
      if (obj.multiline != null) {
        flags += 'm';
      }
      if (obj.sticky != null) {
        flags += 'y';
      }
      return new RegExp(obj.source, flags);
    }
    newInstance = new obj.constructor();
    for (key in obj) {
      newInstance[key] = clone(obj[key]);
    }
    return newInstance;
  };
  exports.clone = clone;
}).call(this);
