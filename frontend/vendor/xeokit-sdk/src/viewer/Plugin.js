/**
 @desc Base class for {@link Viewer} plugin classes.
 */
class Plugin {

    /**
     * Creates this Plugin and installs it into the given {@link Viewer}.
     *
     * @param {string} id ID for this plugin, unique among all plugins in the viewer.
     * @param {Viewer} viewer The viewer.
     * @param {Object} [cfg] Options
     */
    constructor(id, viewer, cfg) {

        /**
         * ID for this Plugin, unique within its {@link Viewer}.
         *
         * @type {string}
         */
        this.id = (cfg && cfg.id) ? cfg.id : id;

        /**
         * The Viewer that contains this Plugin.
         *
         * @type {Viewer}
         */
        this.viewer = viewer;

        /**
         * Subscriptions to events fired at this Plugin.
         * @private
         */
        this._eventSubs = {};

        viewer.addPlugin(this);
    }

    /**
     Subscribes to an event fired at this Plugin.

     @param {String} event The event
     @param {Function} callback Callback fired on the event
     */
    on(event, callback) {
        let subs = this._eventSubs[event];
        if (!subs) {
            subs = [];
            this._eventSubs[event] = subs;
        }
        subs.push(callback);
    }

    /**
     Fires an event at this Plugin.

     @param {String} event The event type name
     @param {Object} value The event parameters
     */
    fire(event, value) {
        const subs = this._eventSubs[event];
        if (subs) {
            for (let i = 0, len = subs.length; i < len; i++) {
                subs[i](value);
            }
        }
    }

    /**
     * Logs a message to the JavaScript developer console, prefixed with the ID of this Plugin.
     *
     * @param {String} msg The error message
     */
    log(msg) {
        console.log(`[xeokit plugin ${this.id}]: ${msg}`);
    }

    /**
     * Logs a warning message to the JavaScript developer console, prefixed with the ID of this Plugin.
     *
     * @param {String} msg The error message
     */
    warn(msg) {
        console.warn(`[xeokit plugin ${this.id}]: ${msg}`);
    }

    /**
     * Logs an error message to the JavaScript developer console, prefixed with the ID of this Plugin.
     *
     * @param {String} msg The error message
     */
    error(msg) {
        console.error(`[xeokit plugin ${this.id}]: ${msg}`);
    }

    /**
     * Sends a message to this Plugin.
     *
     * @private
     */
    send(name, value) {
        //...
    }

    /**
     * Destroys this Plugin and removes it from its {@link Viewer}.
     */
    destroy() {
        this.viewer.removePlugin(this);
    }
}

export {Plugin}