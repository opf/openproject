import {Scene} from "./scene/scene/Scene.js";
import {CameraFlightAnimation} from "./scene/camera/CameraFlightAnimation.js";
import {CameraControl} from "./scene/camera/CameraControl.js";
import {MetaScene} from "./metadata/MetaScene.js";

/**
 * The 3D Viewer at the heart of the xeokit SDK.
 *
 * * A Viewer wraps a single {@link Scene}
 * * Add {@link Plugin}s to a Viewer to extend its functionality.
 * * {@link Viewer#metaScene} holds metadata about {@link Model}s in the
 * Viewer's {@link MetaScene}.
 * * Use {@link Viewer#cameraFlight} to fly or jump the {@link Scene}'s
 * {@link Camera} to target positions, boundaries or {@link Entity}s.
 *
 * @public
 */
class Viewer {

    /**
     * @constructor
     * @param {Object} cfg Viewer configuration.
     * @param {String} [cfg.id] Optional ID for this Viewer, defaults to the ID of {@link Viewer#scene}, which xeokit automatically generates.
     * @param {String} [cfg.canvasId]  ID of an existing HTML canvas for the {@link Viewer#scene} - either this or canvasElement is mandatory. When both values are given, the element reference is always preferred to the ID.
     * @param {HTMLCanvasElement} [cfg.canvasElement] Reference of an existing HTML canvas for the {@link Viewer#scene} - either this or canvasId is mandatory. When both values are given, the element reference is always preferred to the ID.
     * @param {String} [cfg.spinnerElementId]  ID of existing HTML element to show the {@link Spinner} - internally creates a default element automatically if this is omitted.
     * @param {Number} [cfg.passes=1] The number of times the {@link Viewer#scene} renders per frame.
     * @param {Boolean} [cfg.clearEachPass=false] When doing multiple passes per frame, specifies if to clear the canvas before each pass (true) or just before the first pass (false).
     * @param {Boolean} [cfg.preserveDrawingBuffer=true]  Whether or not to preserve the WebGL drawing buffer. This needs to be ````true```` for {@link Viewer#getSnapshot} to work.
     * @param {Boolean} [cfg.transparent=true]  Whether or not the canvas is transparent.
     * @param {Boolean} [cfg.gammaInput=true]  When true, expects that all textures and colors are premultiplied gamma.
     * @param {Boolean} [cfg.gammaOutput=true]  Whether or not to render with pre-multiplied gama.
     * @param {Number} [cfg.gammaFactor=2.2] The gamma factor to use when rendering with pre-multiplied gamma.
     * @param {Boolean} [cfg.clearColorAmbient=false] Sets if the canvas background color is derived from an {@link AmbientLight}. This only has effect when the canvas is not transparent. When not enabled, the background color will be the canvas element's HTML/CSS background color.
     * @param {String} [cfg.units="meters"] The measurement unit type. Accepted values are ````"meters"````, ````"metres"````, , ````"centimeters"````, ````"centimetres"````, ````"millimeters"````,  ````"millimetres"````, ````"yards"````, ````"feet"```` and ````"inches"````.
     * @param {Number} [cfg.scale=1] The number of Real-space units in each World-space coordinate system unit.
     * @param {Number[]} [cfg.origin=[0,0,0]] The Real-space 3D origin, in current measurement units, at which the World-space coordinate origin ````[0,0,0]```` sits.
     * @throws {String} Throws an exception when both canvasId or canvasElement are missing or they aren't pointing to a valid HTMLCanvasElement.
     */
    constructor(cfg) {

        /**
         * The Viewer's current language setting.
         * @property language
         * @type {String}
         */
        this.language = "en";

        /**
         * The Viewer's {@link Scene}.
         * @property scene
         * @type {Scene}
         */
        this.scene = new Scene({
            viewer: this,
            canvasId: cfg.canvasId,
            canvasElement: cfg.canvasElement,
            webgl2: false,
            contextAttr: {
                preserveDrawingBuffer: cfg.preserveDrawingBuffer !== false
            },
            spinnerElementId: cfg.spinnerElementId,
            transparent: cfg.transparent !== false,
            gammaInput: true,
            gammaOutput: true,
            clearColorAmbient: cfg.clearColorAmbient,
            ticksPerRender: 1,
            ticksPerOcclusionTest: 20,
            units: cfg.units,
            scale: cfg.scale,
            origin: cfg.origin
        });

        /**
         * Metadata about the {@link Scene} and the models and objects within it.
         * @property metaScene
         * @type {MetaScene}
         * @readonly
         */
        this.metaScene = new MetaScene(this, this.scene);

        /**
         * The Viewer's ID.
         * @property id
         *
         * @type {String|Number}
         */
        this.id = cfg.id || this.scene.id;

        /**
         * The Viewer's {@link Camera}. This is also found on {@link Scene#camera}.
         * @property camera
         * @type {Camera}
         */
        this.camera = this.scene.camera;

        /**
         * The Viewer's {@link CameraFlightAnimation}, which
         * is used to fly the {@link Scene}'s {@link Camera} to given targets.
         * @property cameraFlight
         * @type {CameraFlightAnimation}
         */
        this.cameraFlight = new CameraFlightAnimation(this.scene, {
            duration: 0.5
        });

        /**
         * The Viewer's {@link CameraControl}, which
         * controls the {@link Scene}'s {@link Camera} with mouse,  touch and keyboard input.
         * @property cameraControl
         * @type {CameraControl}
         */
        this.cameraControl = new CameraControl(this.scene, {
            // panToPointer: true,
            doublePickFlyTo: true
        });

        /**
         * {@link Plugin}s that have been installed into this Viewer, mapped to their IDs.
         * @property plugins
         * @type {{string:Plugin}}
         */
        this.plugins = {};

        /**
         * Subscriptions to events sent with {@link fire}.
         * @private
         */
        this._eventSubs = {};
    }

    /**
     * Subscribes to an event fired at this Viewer.
     *
     * @param {String} event The event
     * @param {Function} callback Callback fired on the event
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
     * Fires an event at this Viewer.
     *
     * @param {String} event Event name
     * @param {Object} value Event parameters
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
     * Unsubscribes from an event fired at this Viewer.
     * @param event
     */
    off(event) { // TODO

    }

    /**
     * Logs a message to the JavaScript developer console, prefixed with the ID of this Viewer.
     *
     * @param {String} msg The message
     */
    log(msg) {
        console.log(`[xeokit viewer ${this.id}]: ${msg}`);
    }

    /**
     * Logs an error message to the JavaScript developer console, prefixed with the ID of this Viewer.
     *
     * @param {String} msg The error message
     */
    error(msg) {
        console.error(`[xeokit viewer ${this.id}]: ${msg}`);
    }

    /**
     * Installs a Plugin.
     *
     * @private
     */
    addPlugin(plugin) {
        if (this.plugins[plugin.id]) {
            this.error(`Plugin with this ID already installed: ${plugin.id}`);
        }
        this.plugins[plugin.id] = plugin;
        this.log(`Installed plugin: ${plugin.id}`);
    }

    /**
     * Uninstalls a Plugin, clearing content from it first.
     *
     * @private
     */
    removePlugin(plugin) {
        const installedPlugin = this.plugins[plugin.id];
        if (!installedPlugin) {
            this.error(`Can't remove plugin - no plugin with this ID is installed: ${plugin.id}`);
            return;
        }
        if (installedPlugin !== plugin) {
            this.error(`Can't remove plugin - a different plugin is installed with this ID: ${plugin.id}`);
            return;
        }
        if (installedPlugin.clear) {
            installedPlugin.clear();
        }
        delete this.plugins[plugin.id];
        this.log(`Removed plugin: ${plugin.id}`);
    }

    /**
     * Sends a message to installed Plugins.
     *
     * The message can optionally be accompanied by a value.
     * @private
     */
    sendToPlugins(name, value) {
        const plugins = this.plugins;
        for (const id in plugins) {
            if (plugins.hasOwnProperty(id)) {
                plugins[id].send(name, value);
            }
        }
    }

    /**
     * Clears content from this Viewer and all installed {@link Plugin}s.
     */
    clear() {
        this.sendToPlugins("clear");
    }

    /**
     * Resets viewing state.
     *
     * Sends a "resetView" message to each installed {@link Plugin}.
     */
    resetView() {
        this.sendToPlugins("resetView");

        // Clear sectionPlanes at xeokit level

        // TODO
        // this.show();
        // this.hide("space");
        // this.hide("DEFAULT");
    }

    /**
     * Returns a snapshot of this Viewer's canvas as a Base64-encoded image.
     *
     * #### Usage:
     *
     * ````javascript
     * const imageData = viewer.getSnapshot({
     *    width: 500,
     *    height: 500,
     *    format: "png"
     * });
     * ````
     * @param {*} [params] Capture options.
     * @param {Number} [params.width] Desired width of result in pixels - defaults to width of canvas.
     * @param {Number} [params.height] Desired height of result in pixels - defaults to height of canvas.
     * @param {String} [params.format="jpeg"] Desired format; "jpeg", "png" or "bmp".
     * @returns {String} String-encoded image data.
     */
    getSnapshot(params = {}) {
        this.sendToPlugins("snapshotStarting"); // Tells plugins to hide things that shouldn't be in snapshot

        const resize = (params.width !== undefined && params.height !== undefined);
        const canvas = this.scene.canvas.canvas;
        const saveWidth = canvas.clientWidth;
        const saveHeight = canvas.clientHeight;
        const saveCssWidth = canvas.style.width;
        const saveCssHeight = canvas.style.height;

        const width = params.width ? Math.floor(params.width) : canvas.width;
        const height = params.height ? Math.floor(params.height) : canvas.height;

        if (resize) {
            canvas.style.width = width + "px";
            canvas.style.height = height + "px";
        }

        this.scene.render(true);

        const imageData = this.scene.canvas._getSnapshot(params);

        if (resize) {
            canvas.style.width = saveCssWidth;
            canvas.style.height = saveCssHeight;
            canvas.width = saveWidth;
            canvas.height = saveHeight;

            this.scene.glRedraw();
        }

        this.sendToPlugins("snapshotFinished");

        return imageData;
    }

    /** Destroys this Viewer.
     */
    destroy() {
        for (let id in this.plugins) {
            if (this.plugins.hasOwnProperty(id)) {
                this.plugins[id].destroy();
            }
        }
        this.scene.destroy();
    }
}

export {Viewer}
