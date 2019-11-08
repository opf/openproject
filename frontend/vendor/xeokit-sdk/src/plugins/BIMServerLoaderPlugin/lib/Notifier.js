/**
 * @private
 */
function Notifier() {

    this.setSelector = function (selector) {
        console.log('setSelector', arguments);
    };

    this.clear = function () {
        console.log('clear', arguments);
    };

    this.resetStatus = function () {
        console.log('status', arguments);
    };

    this.resetStatusQuick = function () {
        console.log('status', arguments);
    };

    this.setSuccess = function (status, timeToShow) {
        console.log('success', arguments);
    };

    this.setInfo = function (status, timeToShow) {
        console.log('info', arguments);
    };

    this.setError = function (error) {
        console.log('error', arguments);
    };
}

export {Notifier};