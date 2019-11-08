/**
 * @desc controls the canvas viewport for a {@link Scene}.
 *
 * * One Viewport per scene.
 * * You can configure a Scene to render multiple times per frame, while setting the Viewport to different extents on each render.
 * * Make a Viewport automatically size to its {@link Scene} {@link Canvas} by setting its {@link Viewport#autoBoundary} ````true````.
 *
 *
 * Configuring the Scene to render twice on each frame, each time to a separate viewport:
 *
 * ````Javascript
 * // Load glTF model
 * var model = new xeokit.GLTFModel({
    src: "models/gltf/GearboxAssy/glTF-MaterialsCommon/GearboxAssy.gltf"
 });

 var scene = model.scene;
 var viewport = scene.viewport;

 // Configure Scene to render twice for each frame
 scene.passes = 2; // Default is 1
 scene.clearEachPass = false; // Default is false

 // Render to a separate viewport on each render

 var viewport = scene.viewport;
 viewport.autoBoundary = false;

 scene.on("rendering", function (e) {
     switch (e.pass) {
         case 0:
             viewport.boundary = [0, 0, 200, 200]; // xmin, ymin, width, height
             break;

         case 1:
             viewport.boundary = [200, 0, 200, 200];
             break;
     }
 });
 ````

 @class Viewport
 @module xeokit
 @submodule rendering
 @constructor
 @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
 @param {*} [cfg] Viewport configuration
 @param {String} [cfg.id] Optional ID, unique among all components in the parent
 {@link Scene}, generated automatically when omitted.
 @param {String:Object} [cfg.meta] Optional map of user-defined metadata to attach to this Viewport.
 @param [cfg.boundary] {Number[]} Canvas-space Viewport boundary, given as
 (min, max, width, height). Defaults to the size of the parent
 {@link Scene} {@link Canvas}.
 @param [cfg.autoBoundary=false] {Boolean} Indicates if this Viewport's {@link Viewport#boundary}
 automatically synchronizes with the size of the parent {@link Scene} {@link Canvas}.

 @extends Component
 */
import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';

class Viewport extends Component {

    /**
     @private
     */
    get type() {
        return "Viewport";
    }

    /**
     @private
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            boundary: [0, 0, 100, 100]
        });

        this.boundary = cfg.boundary;
        this.autoBoundary = cfg.autoBoundary;
    }


    /**
     * Sets the canvas-space boundary of this Viewport, indicated as ````[min, max, width, height]````.
     *
     * When {@link Viewport#autoBoundary} is ````true````, ignores calls to this method and automatically synchronizes with {@link Canvas#boundary}.
     *
     * Fires a "boundary"" event on change.
     *
     * Defaults to the {@link Canvas} extents.
     *
     * @param {Number[]} value New Viewport extents.
     */
    set boundary(value) {

        if (this._autoBoundary) {
            return;
        }

        if (!value) {

            const canvasBoundary = this.scene.canvas.boundary;

            const width = canvasBoundary[2];
            const height = canvasBoundary[3];

            value = [0, 0, width, height];
        }

        this._state.boundary = value;

        this.glRedraw();

        /**
         Fired whenever this Viewport's {@link Viewport#boundary} property changes.

         @event boundary
         @param value {Boolean} The property's new value
         */
        this.fire("boundary", this._state.boundary);
    }

    /**
     * Gets the canvas-space boundary of this Viewport, indicated as ````[min, max, width, height]````.
     *
     * @returns {Number[]} The Viewport extents.
     */
    get boundary() {
        return this._state.boundary;
    }

    /**
     * Sets if {@link Viewport#boundary} automatically synchronizes with {@link Canvas#boundary}.
     *
     * Default is ````false````.
     *
     * @param {Boolean} value Set true to automatically sycnhronize.
     */
    set autoBoundary(value) {

        value = !!value;

        if (value === this._autoBoundary) {
            return;
        }

        this._autoBoundary = value;

        if (this._autoBoundary) {
            this._onCanvasSize = this.scene.canvas.on("boundary",
                function (boundary) {

                    const width = boundary[2];
                    const height = boundary[3];

                    this._state.boundary = [0, 0, width, height];

                    this.glRedraw();

                    /**
                     Fired whenever this Viewport's {@link Viewport#boundary} property changes.

                     @event boundary
                     @param value {Boolean} The property's new value
                     */
                    this.fire("boundary", this._state.boundary);

                }, this);

        } else if (this._onCanvasSize) {
            this.scene.canvas.off(this._onCanvasSize);
            this._onCanvasSize = null;
        }

        /**
         Fired whenever this Viewport's {@link autoBoundary/autoBoundary} property changes.

         @event autoBoundary
         @param value The property's new value
         */
        this.fire("autoBoundary", this._autoBoundary);
    }

    /**
     * Gets if {@link Viewport#boundary} automatically synchronizes with {@link Canvas#boundary}.
     *
     * Default is ````false````.
     *
     * @returns {Boolean} Returns ````true```` when automatically sycnhronizing.
     */
    get autoBoundary() {
        return this._autoBoundary;
    }

    _getState() {
        return this._state;
    }

    /**
     * @private
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {Viewport};