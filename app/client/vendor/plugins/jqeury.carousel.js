/* Author:
    Max Degterev @suprMax
*/

;(function($) {
    var Carousel = function(settings) {
        this.options = $.extend({
            items: 3,
            duration: 300
        }, settings);

        this.els = {};
        this.els.block = $(this.options.el);

        this.init();
        this.logic();
    };

    Carousel.prototype.init = function() {
        this.els.control = this.els.block.find('.m-c-control');
        this.els.prev = this.els.control.filter('.m-c-prev');
        this.els.next = this.els.control.filter('.m-c-next');

        this.els.count = this.els.block.find('.m-c-count');

        this.els.container = this.els.block.find('.m-c-coutainer');
        this.els.list = this.els.block.find('.m-c-list');

        this.reset();
    };
    Carousel.prototype.logic = function() {
        var that = this;

        var handleControl = function() {
            var el = $(this);
            if (!el.hasClass('disabled')) {
                if (el.hasClass('m-c-prev')) {
                    that.shiftLeft();
                }
                else {
                    that.shiftRight();
                }
            }
        };

        this.els.control.on('click', handleControl);
    };
    Carousel.prototype.shiftLeft = function() {
        var newShift = this.currentShift - this.options.items;

        if (newShift < 0) return;

        this._setShift(newShift);

        if (newShift === 0) {
            this.els.prev.addClass('disabled');
        }
        if (this.itemsNum > this.options.items && this.els.next.hasClass('disabled')) {
            this.els.next.removeClass('disabled');
        }
    };
    Carousel.prototype.shiftRight = function() {
        var newShift = this.currentShift + this.options.items;

        if (newShift >= this.itemsNum) return;

        this._setShift(newShift);

        if (newShift + this.options.items >= this.itemsNum) {
            this.els.next.addClass('disabled');
        }
        this.els.prev.removeClass('disabled');
    };
    Carousel.prototype._setShift = function(shift) {
        this.els.list.animate({ left: -((this.itemWidth + this.itemMargin) * shift) }, this.options.duration);
        this.els.count.html(shift + '/' + this.itemsNum);
        this.currentShift = shift;
    };
    Carousel.prototype.reset = function() {
        var item;
        this.els.items = this.els.list.find('.m-c-l-item');
        item = this.els.items.eq(0);

        this.itemWidth = item.width();
        this.itemMargin = parseInt(item.css('margin-right'), 10);

        this.itemsNum = this.els.items.length;
        this.currentShift = 0;

        this.els.container.css({
            width: (this.itemWidth * this.options.items) + (this.itemMargin * (this.options.items - 1)),
            height: item.height()
        });
        this.els.list.css({ width: (this.itemWidth + this.itemMargin) * this.itemsNum });

        this.els.count.html('0/' + this.itemsNum);

        if (this.itemsNum <= this.options.items) this.els.next.addClass('disabled');
    };

    $.fn.m_carousel = function(settings) {
        // var options = $.extend({
        // }, settings);

        var instances = [];

        this.each(function(index, elem) {
            instances.push(new Carousel({
                el: elem
            }));
        });

        return instances;
    };
})(jQuery);

$(document).ready(function() { $('.m-carousel').m_carousel(); });
