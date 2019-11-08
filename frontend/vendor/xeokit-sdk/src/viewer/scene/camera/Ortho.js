import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {math} from '../math/math.js';

/**
 * @desc Defines its {@link Camera}'s orthographic projection as a box-shaped view volume.
 *
 * * Located at {@link Camera#ortho}.
 * * Works like Blender's orthographic projection, where the positions of the left, right, top and bottom planes are implicitly
 * indicated with a single {@link Ortho#scale} property, which causes the frustum to be symmetrical on X and Y axis, large enough to
 * contain the number of units given by {@link Ortho#scale}.
 * * {@link Ortho#near} and {@link Ortho#far} indicated the distances to the WebGL clipping planes.
 */
class Ortho extends Component {

    /**
     @private
     */
    get type() {
        return "Ortho";
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

        this.scale = cfg.scale;
        this.near = cfg.near;
        this.far = cfg.far;

        this._onCanvasBoundary = this.scene.canvas.on("boundary", this._needUpdate, this);
    }

    _update() {

        const WIDTH_INDEX = 2;
        const HEIGHT_INDEX = 3;

        const scene = this.scene;
        const scale = this._scale;
        const halfSize = 0.5 * scale;

        const boundary = scene.viewport.boundary;
        const boundaryWidth = boundary[WIDTH_INDEX];
        const boundaryHeight = boundary[HEIGHT_INDEX];
        const aspect = boundaryWidth / boundaryHeight;

        let left;
        let right;
        let top;
        let bottom;

        if (boundaryWidth > boundaryHeight) {
            left = -halfSize;
            right = halfSize;
            top = halfSize / aspect;
            bottom = -halfSize / aspect;

        } else {
            left = -halfSize * aspect;
            right = halfSize * aspect;
            top = halfSize;
            bottom = -halfSize;
        }

        math.orthoMat4c(left, right, bottom, top, this._state.near, this._state.far, this._state.matrix);

        this.glRedraw();

        this.fire("matrix", this._state.matrix);
    }


    /**
     * Sets scale factor for this Ortho's extents on X and Y axis.
     *
     * Clamps to minimum value of ````0.01```.
     *
     * Fires a "scale" event on change.
     *
     * Default value is ````1.0````
     * @param {Number} value New scale value.
     */
    set scale(value) {
        if (value === undefined || value === null) {
            value = 1.0;
        }
        if (value <= 0) {
            value = 0.01;
        }
        this._scale = value;
        this._needUpdate(0);
        /**
         Fired whenever this Ortho's {@link Ortho#scale} property changes.

         @event scale
         @param value The property's new value
         */
        this.fire("scale", this._scale);
    }

    /**
     * Gets scale factor for this Ortho's extents on X and Y axis.
     *
     * Clamps to minimum value of ````0.01```.
     *
     * Default value is ````1.0````
     *
     * @returns {Number} New Ortho scale value.
     */
    get scale() {
        return this._scale;
    }

    /**
     * Sets the position of the Ortho's near plane on the positive View-space Z-axis.
     *
     * Fires a "near" emits on change.
     *
     * Default value is ````0.1````.
     *
     * @param {Number} value New Ortho near plane position.
     */
    set near(value) {
        this._state.near = (value !== undefined && value !== null) ? value : 0.1;
        this._needUpdate(0);
        /**
         Fired whenever this Ortho's  {@link Ortho#near} property changes.

         @event near
         @param value The property's new value
         */
        this.fire("near", this._state.near);
    }

    /**
     * Gets the position of the Ortho's near plane on the positive View-space Z-axis.
     *
     * Default value is ````0.1````.
     *
     * @returns {Number} New Ortho near plane position.
     */
    get near() {
        return this._state.near;
    }

    /**
     * Sets the position of the Ortho's far plane on the positive View-space Z-axis.
     *
     * Fires a "far" event on change.
     *
     * Default value is ````10000.0````.
     *
     * @param {Number} value New far ortho plane position.
     */
    set far(value) {
        this._state.far = (value !== undefined && value !== null) ? value : 10000.0;
        this._needUpdate(0);
        /**
         Fired whenever this Ortho's {@link Ortho#far} property changes.

         @event far
         @param value The property's new value
         */
        this.fire("far", this._state.far);
    }

    /**
     * Gets the position of the Ortho's far plane on the positive View-space Z-axis.
     *
     * Default value is ````10000.0````.
     *
     * @returns {Number} New far ortho plane position.
     */
    get far() {
        return this._state.far;
    }

    /**
     * Gets the Ortho's projection transform matrix.
     *
     * Fires a "matrix" event on change.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @returns {Number[]} The Ortho's projection matrix.
     */
    get matrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.matrix;
    }

    destroy() {
        super.destroy();
        this._state.destroy();
        this.scene.canvas.off(this._onCanvasBoundary);
    }
}

export {Ortho};