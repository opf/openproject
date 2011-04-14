/**
 * @author Ryan Johnson <http://syntacticx.com/>
 * @copyright 2008 PersonalGrid Corporation <http://personalgrid.com/>
 * @package LivePipe UI
 * @license MIT
 * @url http://livepipe.net/control/progressbar
 * @require prototype.js, livepipe.js
 */

/*global document, Prototype, Ajax, Class, PeriodicalExecuter, $, $A, Control */

if (typeof(Prototype) === "undefined") {
    throw "Control.ProgressBar requires Prototype to be loaded.";
}
if (typeof(Event) === "undefined") {
    throw "Control.ProgressBar requires Event to be loaded.";
}

Control.ProgressBar = Class.create({
    initialize: function(container, options) {
        this.progress = 0;
        this.executer = false;
        this.active = false;
        this.poller = false;
        this.container = $(container);
        this.containerWidth = this.container.getDimensions().width;
        this.progressContainer = $(document.createElement('div'));
        this.progressContainer.setStyle({
            width: this.containerWidth + 'px',
            height: '100%',
            position: 'absolute',
            top: '0px',
            right: '0px'
        });
        this.container.appendChild(this.progressContainer);
        this.options = {
            afterChange: Prototype.emptyFunction,
            interval: 0.25,
            step: 1,
            classNames: {
                active: 'progress_bar_active',
                inactive: 'progress_bar_inactive'
            }
        };
        Object.extend(this.options, options || {});
        this.container.addClassName(this.options.classNames.inactive);
        this.active = false;
    },
    setProgress: function (value) {
        this.progress = value;
        this.draw();
        if (this.progress >= 100) {
            this.stop(false);
        }
        this.notify('afterChange', this.progress, this.active);
    },
    poll: function (url, interval, ajaxOptions) {
        // Extend the passed ajax options and success callback with our own.
        ajaxOptions = ajaxOptions || {};
        var success = ajaxOptions.onSuccess || Prototype.emptyFunction;
        ajaxOptions.onSuccess = success.wrap(function (callOriginal, request) {
            this.setProgress(parseInt(request.responseText, 10));
            if (!this.active) {
                this.poller.stop();
            }
            callOriginal(request);
        }).bind(this);

        this.active = true;
        this.poller = new PeriodicalExecuter(function () {
            var a = new Ajax.Request(url, ajaxOptions);
        }.bindAsEventListener(this), interval || 3);
    },
    start: function () {
        this.active = true;
        this.container.removeClassName(this.options.classNames.inactive);
        this.container.addClassName(this.options.classNames.active);
        this.executer = new PeriodicalExecuter(this.step.bind(this, this.options.step), this.options.interval);
    },
    stop: function (reset) {
        this.active = false;
        if (this.executer) {
            this.executer.stop();
        }
        this.container.removeClassName(this.options.classNames.active);
        this.container.addClassName(this.options.classNames.inactive);
        if (typeof reset  === 'undefined' || reset === true) {
            this.reset();
        }
    },
    step: function (amount) {
        this.active = true;
        this.setProgress(Math.min(100, this.progress + amount));
    },
    reset: function () {
        this.active = false;
        this.setProgress(0);
    },
    draw: function () {
        this.progressContainer.setStyle({
            width: (100 - this.progress) + "%"
        });
    },
    notify: function (event_name) {
        if (this.options[event_name]) {
            return [this.options[event_name].apply(this.options[event_name], $A(arguments).slice(1))];
        }
    }
});
Event.extend(Control.ProgressBar);