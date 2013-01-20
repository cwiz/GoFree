/* Author:
    Max Degterev @suprMax
*/

;(function($) {
    var FValidate = function(settings) {
        this.options = $.extend({
            form: 'form',
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
        this.els.inputs = this.els.form.find('input[data-validate], select[data-validate], textarea[data-validate]');
        this.els.containers = this.els.form.find('.m-validate-container');

        if (this.options.isDisabled) {
            this.els.enablingInputs = this.els.form.find('input[data-enabling], select[data-enabling], textarea[data-enabling]');
            this.els.button = this.els.form.find('button');
        }

        this.load();
    };

    FValidate.prototype.load = function() {
        var that = this;

        var loadPattern = function(index, elem) {
            var pattern = elem.getAttribute('data-pattern') || elem.getAttribute('pattern');

            if (pattern) {
                that.validation.patterns[elem.name] = new RegExp('^' + pattern + '$');
            }
        };

        // Load patterns from HTML
        this.els.inputs.filter('[data-filter*="pattern"]').each(loadPattern);
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
            $(this).removeClass('valid invalid');
        };

        var handleErrorClick = function(e) {
            var relation = this.getAttribute('data-for');

            if (relation && relation !== '__none__') {
                this.parentNode.removeChild(this);

                var input = that.els.inputs.filter('[name="' + relation + '"]');

                // to avoid bug when sometimes keyboard doesn't show up
                $.os.ios && that.els.inputs.blur();

                input.length && input[0].focus();
            }
        };

        if (this.options.isDisabled) {
            var checkAllFilled = function(fields) {
                return _.all(fields, function(f) { return f.value.length > 0; });
            };

            var inputsStateCheck = function() {
                if (checkAllFilled(that.els.enablingInputs)) {
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
        this.els.inputs.on('focus', handleInputFocus);
        this.els.containers.on('click', '.m-validate-error', handleErrorClick);
    };

    FValidate.prototype.handleErrors = function() {
        var field,
            error;

        this.els.containers.find('.m-validate-error').remove();

        if (this.errorsNum) {
            for (field in this.errors) {
                error = '<span class="m-validate-error ' +
                                this.errors[field].errorpos +
                            '" data-for="' +
                                this.errors[field].name +
                            '">' +
                            this.errors[field].error +
                        '</span>';

                this.els.containers.filter('[data-for="' + field + '"]').append(error);
            }

            this.els.form.addClass('has_errors');
        }
        else {
            this.els.form.removeClass('has_errors');
        }
    };

    FValidate.prototype.validateInput = function(input) {
        var el = $(input),
            name = el.attr('name'),
            filters = el.data('filter') ? el.data('filter').split(' ') : [],
            failed = [],
            m, n;

        if (!el.attr('disabled')) {
            el.attr('required') && filters.push('required');

            for (m = 0, n = filters.length; m < n; m++) {
                if (typeof this.validation.rules[filters[m]] === 'function') {
                    this.validation.rules[filters[m]].call(input, this) || (failed.push(name + ':' + filters[m]));
                }
                else {
                    this.debug('[m_validate]: missing required filter: "' + filters[m] + '"');
                }
            }

            if (typeof this.validation.external[name] === 'function') {
                this.validation.external[name].call(input, this) || (failed.push(name + ':external'));
            }
        }

        if (!failed.length) {
            el.removeClass('invalid');
            el.addClass('valid');
        }
        else {
            this.debug('[m_validate]: "' + input.value + '" failed validation: ' + failed.join(', '));
            el.addClass('invalid');
            el.removeClass('valid');

            this.options.report && this.options.report.call(input, failed);

            this.errors[name] = { el: el, name: name, error: el.data('error'), errorpos: el.data('errorpos') || 'right' };
            this.errorsNum++;
        }
    };

    FValidate.prototype.validateForm = function() {
        var i, l;

        this.errors = {};
        this.errorsNum = 0;

        for (i = 0, l = this.els.inputs.length; i < l; i++) {
            this.validateInput(this.els.inputs[i]);
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
                debug: S.log,
                validations: options.validations,
                report: options.report,
                isDisabled: options.isDisabled
            }));
        });

        return instances;
    };
})(jQuery);
