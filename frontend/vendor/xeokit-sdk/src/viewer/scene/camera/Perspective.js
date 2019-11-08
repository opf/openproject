import {math} from '../math/math.js';
import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';

/**
 * @desc Defines its {@link Camera}'s perspective projection using a field-of-view angle.
 *
 * * Located at {@link Camera#perspective}.
 * * Implicitly sets the left, right, top, bottom frustum planes using {@link Perspective#fov}.
 * * {@link Perspective#near} and {@link Perspective#far} specify the distances to the WebGL clipping planes.
 */
class Perspective extends Component {

    /**
     @private
     */
    get type() {
        return "Perspective";
    }

    /**
     * @constructor
     * @private
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            matrix: math.mat4(),
            near : 0.1,
            far: 10000.0
        });

        this._dirty = false;
        this._fov = 60.0;

        // Recompute aspect from change in canvas size
        this._canvasResized = this.scene.canvas.on("boundary", this._needUpdate, this);

        this.fov = cfg.fov;
        this.fovAxis = cfg.fovAxis;
        this.near = cfg.near;
        this.far = cfg.far;
    }

    _update() {
        const WIDTH_INDEX = 2;
        const HEIGHT_INDEX = 3;
        const boundary = this.scene.viewport.boundary;
        const aspect = boundary[WIDTH_INDEX] / boundary[HEIGHT_INDEX];
        let fov = this._fov;
        const fovAxis = this._fovAxis;
        if (fovAxis === "x" || (fovAxis === "min" && aspect < 1) || (fovAxis === "max" && aspect > 1)) {
            fov = fov / aspect;
        }
        fov = Math.min(fov, 120);
        math.perspectiveMat4(fov * (Math.PI / 180.0), aspect, this._state.near, this._state.far, this._state.matrix);
        this.glRedraw();
        this.fire("matrix", this._state.matrix);
    }

    /**
     * Sets the Perspective's field-of-view angle (FOV).
     *
     * Fires an "fov" event on change.

     * Default value is ````60.0````.
     *
     * @param {Number} value New field-of-view.
     */
    set fov(value) {
        this._fov = (value !== undefined && value !== null) ? value : 60.0;
        this._needUpdate(0); // Ensure matrix built on next "tick"
        /**
         Fired whenever this Perspective's {@link Perspective/fov} property changes.

         @event fov
         @param value The property's new value
         */
        this.fire("fov", this._fov);
    }

    /**
     * Gets the Perspective's field-of-view angle (FOV).
     *
     * Default value is ````60.0````.
     *
     * @returns {Number} Current field-of-view.
     */
    get fov() {
        return this._fov;
    }

    /**
     * Sets the Perspective's FOV axis.
     *
     * Options are ````"x"````, ````"y"```` or ````"min"````, to use the minimum axis.
     *
     * Fires an "fovAxis" event on change.

     * Default value ````"min"````.
     *
     * @param {String} value New FOV axis value.
     */
    set fovAxis(value) {
        value = value || "min";
        if (this._fovAxis === value) {
            return;
        }
        if (value !== "x" && value !== "y" && value !== "min") {
            this.error("Unsupported value for 'fovAxis': " + value + " - defaulting to 'min'");
            value = "min";
        }
        this._fovAxis = value;
        this._needUpdate(0); // Ensure matrix built on next "tick"
        /**
         Fired whenever this Perspective's {@link Perspective/fovAxis} property changes.

         @event fovAxis
         @param value The property's new value
         */
        this.fire("fovAxis", this._fovAxis);
    }

    /**
     * Gets the Perspective's FOV axis.
     *
     * Options are ````"x"````, ````"y"```` or ````"min"````, to use the minimum axis.
     *
     * Fires an "fovAxis" event on change.

     * Default value is ````"min"````.
     *
     * @returns {String} The current FOV axis value.
     */
    get fovAxis() {
        return this._fovAxis;
    }

    /**
     * Sets the position of the Perspective's near plane on the positive View-space Z-axis.
     *
     * Fires a "near" event on change.
     *
     * Default value is ````0.1````.
     *
     * @param {Number} value New Perspective near plane position.
     */
    set near(value) {
        this._state.near = (value !== undefined && value !== null) ? value : 0.1;
        this._needUpdate(0); // Ensure matrix built on next "tick"
        /**
         Fired whenever this Perspective's   {@link Perspective/near} property changes.
         @event near
         @param value The property's new value
         */
        this.fire("near", this._state.near);
    }

    /**
     * Gets the position of the Perspective's near plane on the positive View-space Z-axis.
     *
     * Fires an "emits" emits on change.
     *
     * Default value is ````0.1````.
     *
     * @return {Number} Near frustum plane position.
     */
    get near() {
        return this._state.near;
    }

    /**
     * Sets the position of this Perspective's far plane on the positive View-space Z-axis.
     *
     * Fires a "far" event on change.
     *
     * @property far
     * @default 10000.0
     * @type {Number}
     */
    set far(value) {
        this._state.far = (value !== undefined && value !== null) ? value : 10000;
        this._needUpdate(0); // Ensure matrix built on next "tick"
        /**
         Fired whenever this Perspective's  {@link Perspective/far} property changes.

         @event far
         @param value The property's new value
         */
        this.fire("far", this._state.far);
    }

    /**
     * Gets the position of this Perspective's far plane on the positive View-space Z-axis.
     *
     * @property far
     * @default 10000.0
     * @type {Number}
     */
    get far() {
        return this._state.far;
    }

    /**
     * Gets the Perspective's projection transform matrix.
     *
     * Fires a "matrix" event on change.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @returns {Number[]} The Perspective's projection matrix.
     */
    get matrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.matrix;
    }

    /**
     * Destroys this Perspective.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
        super.destroy();
        this.scene.canvas.off(this._canvasResized);
    }
}

export {Perspective};