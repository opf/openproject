/**
 * @private
 */
function EventHandler() {
    this.handlers = {};
}

EventHandler.prototype.on = function (evt, handler) {
    (this.handlers[evt] || (this.handlers[evt] = [])).push(handler);
};

EventHandler.prototype.off = function (evt, handler) {
    var h = this.handlers[evt];
    var found = false;
    if (typeof(h) !== 'undefined') {
        var i = h.indexOf(handler);
        if (i >= -1) {
            h.splice(i, 1);
            found = true;
        }
    }
    if (!found) {
        throw new Error("Handler not found");
    }
};

EventHandler.prototype.fire = function (evt, args) {
    var h = this.handlers[evt];
    if (!h) {
        return;
    }
    for (var i = 0; i < h.length; ++i) {
        h[i].apply(this, args);
    }
};

export {EventHandler};