/* jQuery Tiny Pub/Sub - v0.7 - 10/27/2011
* http://benalman.com/
* Copyright (c) 2011 "Cowboy" Ben Alman; Licensed MIT, GPL */

(function($) {
    var o = $({});

    $.sub = function() {
        o.on.apply(o, arguments);
    };
    
    $.once = function() {
        o.one.apply(o, arguments);
    };

    $.unsub = function() {
        o.off.apply(o, arguments);
    };

    $.pub = function() {
        o.trigger.apply(o, arguments);
    };
}(jQuery));
