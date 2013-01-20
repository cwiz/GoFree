/* Author:
    Max Degterev @suprMax
*/

;(function($) {
    var FValidate = function(settings) {
        this.options = $.extend({
            form: 'form',
            inputs: 'input[data-validate], select[data-validate], textarea[data-validate]',
            containers: '.m-validate-container',
            enablingInputs: 'input[data-enabling], select[data-enabling], textarea[data-enabling]',
            validations: {},
            report: false,
            isDisabled: false
        }, settings);

        this.els = {};
        this.errors = {};
        this.errorsNum = 0;

        this.init();
        this.logic();
    };

    FValidate.prototype.init = function() {
        (typeof this.options.debug === 'function') && (this.debug = this.options.debug);
        this.validation.external = this.options.validations;

        this.els.form = $(this.options.form);

        if (this.options.isDisabled) {
            this.els.button = this.els.form.find('button');
        }

        this.scanElements();
        return this;
    };

    FValidate.prototype.scanElements = function() {
        var that = this;

        var loadPattern = function(index, elem) {
            var pattern = elem.getAttribute('data-pattern') || elem.getAttribute('pattern');

            if (pattern) {
                that.validation.patterns[elem.name] = new RegExp('^' + pattern + '$');
            }
        };

        // Load patterns from HTML
        this.els.form.find(this.options.inputs).filter('[data-filter*="pattern"]').each(loadPattern);
    };

    FValidate.prototype.logic = function() {
        var that = this;

        var handleSubmit = function(e) {
            if (that.validateForm()) {
                that.els.form.trigger('valid', e);
                that.options.onFormValid && that.options.onFormValid.call(that, e);
            }
            else {
                e.preventDefault();
                that.els.form.trigger('invalid', e);
                that.options.onFormInvalid && that.options.onFormInvalid.call(that, e);
            }
        };

        var handleInputFocus = function() {
            var el = $(this);
            el.removeClass('valid invalid');
            that.els.form.find(that.options.containers).filter('[data-for="' + el.attr('name') + '"]').find('.m-validate-error').remove();
        };

        var handleErrorClick = function(e) {
            var relation = this.getAttribute('data-for');

            if (relation && relation !== '__none__') {
                this.parentNode.removeChild(this);

                var input = that.els.form.find(that.options.inputs).filter('[name="' + relation + '"]');

                // to avoid bug when sometimes keyboard doesn't show up
                $.os.ios && that.els.form.find(that.options.inputs).blur();

                input.length && input[0].focus();
            }
        };

        if (this.options.isDisabled) {
            var checkAllFilled = function(fields) {
                return _.all(fields, function(f) { return f.value.length > 0; });
            };

            var inputsStateCheck = function() {
                if (checkAllFilled(that.els.form.find(that.options.enablingInputs))) {
                    that.els.button.removeAttr('disabled');
                }
                else {
                    setTimeout(inputsStateCheck, 300); // workaround for chrome autofill
                }
            };
            inputsStateCheck();
        }

        this.els.form.attr('novalidate', 'novalidate');

        this.els.form.on('submit', handleSubmit);
        this.els.form.on('focus', this.options.inputs, handleInputFocus);
        this.els.form.on('click', '.m-validate-error', handleErrorClick);
    };

    FValidate.prototype.handleErrors = function() {
        var field,
            error;

        this.els.form.find('.m-validate-error').remove();

        if (this.errorsNum) {
            for (field in this.errors) {
                error = '<span class="m-validate-error ' +
                                this.errors[field].errorpos +
                            '" data-for="' +
                                this.errors[field].name +
                            '">' +
                            this.errors[field].error +
                        '</span>';

                this.els.form.find(this.options.containers).filter('[data-for="' + field + '"]').append(error);
            }

            this.els.form.addClass('has_errors');
        }
        else {
            this.els.form.removeClass('has_errors');
        }
    };

    FValidate.prototype.validateInput = function(el) {
        var name = el.attr('name'),
            filters = el.data('filter') ? el.data('filter').split(' ') : [],
            failed = [],
            m, n;

        if (!el.attr('disabled')) {
            el.attr('required') && filters.push('required');

            for (m = 0, n = filters.length; m < n; m++) {
                if (typeof this.validation.rules[filters[m]] === 'function') {
                    this.validation.rules[filters[m]].call(el[0], this) || (failed.push(name + ':' + filters[m]));
                }
                else {
                    this.debug('[m_validate]: missing required filter: "' + filters[m] + '"');
                }
            }

            if (typeof this.validation.external[name] === 'function') {
                this.validation.external[name].call(el[0], this) || (failed.push(name + ':external'));
            }
        }

        if (!failed.length) {
            el.removeClass('invalid');
            el.addClass('valid');
        }
        else {
            this.debug('[m_validate]: "' + el[0].value + '" failed validation: ' + failed.join(', '));
            el.addClass('invalid');
            el.removeClass('valid');

            this.options.report && this.options.report.call(el[0], failed);

            this.errors[name] = { el: el, name: name, error: el.data('error'), errorpos: el.data('errorpos') || 'right' };
            this.errorsNum++;
        }
    };

    FValidate.prototype.validateForm = function() {
        var i, l;
        var inputs = this.els.form.find(this.options.inputs);

        this.errors = {};
        this.errorsNum = 0;

        for (i = 0, l = inputs.length; i < l; i++) {
            this.validateInput(inputs.eq(i));
        }

        this.handleErrors();

        return !this.errorsNum;
    };

    FValidate.prototype.validation = {
        patterns: {},
        external: {},
        rules: {
            required: function() {
                if (this.type === 'radio' || this.type === 'checkbox') {
                    return this.checked;
                }
                else {
                    return !!$.trim(this.value).length;
                }
            },
            email: function() {
                return !!$.trim(this.value).length && /^[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-.]+$/.test(this.value);
            },
            number: function() {
                var min = +this.getAttribute('min') || -Infinity,
                    max = +this.getAttribute('max') || +Infinity,
                    val = +$.trim(this.value);

                return this.value.length ? (!isNaN(val) && val >= min && val <= max) : true;
            },
            pattern: function(that) {
                return that.validation.patterns[this.name].test(this.value);
            }
        }
    };

    FValidate.prototype.debug = function(msg) {
    };

    $.fn.m_formValidate = function(settings) {
        var options = $.extend({
            validations: {},
            isDisabled: false,
            report: false
        }, settings);

        var instances = [];
        
        // var report = function(failed) {
        //     $.pub('m_validate_error', {
        //         name: this.name,
        //         value: this.value,
        //         message: this.getAttribute('data-error'),
        //         failed: failed
        //     });
        // };

        this.each(function(index, elem) {
            instances.push(new FValidate({
                form: elem,
                debug: app.log,
                validations: options.validations,
                report: options.report,
                isDisabled: options.isDisabled
            }));
        });

        return instances;
    };
})(jQuery);
