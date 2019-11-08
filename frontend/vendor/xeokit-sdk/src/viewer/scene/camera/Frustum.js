import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {math} from '../math/math.js';

/**
 * @desc Defines its {@link Camera}'s perspective projection as a frustum-shaped view volume.
 *
 * * Located at {@link Camera#frustum}.
 * * Allows to explicitly set the positions of the left, right, top, bottom, near and far planes, which is useful for asymmetrical view volumes, such as for stereo viewing.
 * * {@link Frustum#near} and {@link Frustum#far} specify the distances to the WebGL clipping planes.
 */
class Frustum extends Component {

    /**
     @private
     */
    get type() {
        return "Frustum";
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

        this._left = -1.0;
        this._right = 1.0;
        this._bottom = -1.0;
        this._top = 1.0;

        // Set component properties

        this.left = cfg.left;
        this.right = cfg.right;
        this.bottom = cfg.bottom;
        this.top = cfg.top;
        this.near = cfg.near;
        this.far = cfg.far;
    }

    _update() {
        math.frustumMat4(this._left, this._right, this._bottom, this._top, this._state.near, this._state.far, this._state.matrix);
        this.glRedraw();
        this.fire("matrix", this._state.matrix);
    }

    /**
     * Sets the position of the Frustum's left plane on the View-space X-axis.
     *
     * Fires a {@link Frustum#left:emits} emits on change.
     *
     * @param {Number} value New left frustum plane position.
     */
    set left(value) {
        this._left = (value !== undefined && value !== null) ? value : -1.0;
        this._needUpdate(0);

        /**
         Fired whenever the Frustum's {@link Frustum#left} property changes.

         @emits left
         @param value New left frustum plane position.
         */
        this.fire("left", this._left);
    }

    /**
     * Gets the position of the Frustum's left plane on the View-space X-axis.
     *
     * @return {Number} Left frustum plane position.
     */
    get left() {
        return this._left;
    }

    /**
     * Sets the position of the Frustum's right plane on the View-space X-axis.
     *
     * Fires a {@link Frustum#right:emits} emits on change.
     *
     * @param {Number} value New right frustum plane position.
     */
    set right(value) {
        this._right = (value !== undefined && value !== null) ? value : 1.0;
        this._needUpdate(0);

        /**
         Fired whenever the Frustum's {@link Frustum#right} property changes.

         @emits right
         @param value New frustum right plane position.
         */
        this.fire("right", this._right);
    }

    /**
     * Gets the position of the Frustum's right plane on the View-space X-axis.
     *
     * Fires a {@link Frustum#right:emits} emits on change.
     *
     * @return {Number} Right frustum plane position.
     */
    get right() {
        return this._right;
    }

    /**
     * Sets the position of the Frustum's top plane on the View-space Y-axis.
     *
     * Fires a {@link Frustum#top:emits} emits on change.
     *
     * @param {Number} value New top frustum plane position.
     */
    set top(value) {
        this._top = (value !== undefined && value !== null) ? value : 1.0;
        this._needUpdate(0);

        /**
         Fired whenever the Frustum's   {@link Frustum#top} property changes.

         @emits top
         @param value New top frustum plane position.
         */
        this.fire("top", this._top);
    }

    /**
     * Gets the position of the Frustum's top plane on the View-space Y-axis.
     *
     * Fires a {@link Frustum#top:emits} emits on change.
     *
     * @return {Number} Top frustum plane position.
     */
    get top() {
        return this._top;
    }

    /**
     * Sets the position of the Frustum's bottom plane on the View-space Y-axis.
     *
     * Fires a {@link Frustum#bottom:emits} emits on change.
     *
     * @emits {"bottom"} event with the value of this property whenever it changes.
     *
     * @param {Number} value New bottom frustum plane position.
     */
    set bottom(value) {
        this._bottom = (value !== undefined && value !== null) ? value : -1.0;
        this._needUpdate(0);

        this.fire("bottom", this._bottom);
    }

    /**
     * Gets the position of the Frustum's bottom plane on the View-space Y-axis.
     *
     * Fires a {@link Frustum#bottom:emits} emits on change.
     *
     * @return {Number} Bottom frustum plane position.
     */
    get bottom() {
        return this._bottom;
    }

    /**
     * Sets the position of the Frustum's near plane on the positive View-space Z-axis.
     *
     * Fires a {@link Frustum#near:emits} emits on change.
     *
     * Default value is ````0.1````.
     *
     * @param {Number} value New Frustum near plane position.
     */
    set near(value) {
        this._state.near = (value !== undefined && value !== null) ? value : 0.1;
        this._needUpdate(0);

        /**
         Fired whenever the Frustum's {@link Frustum#near} property changes.

         @emits near
         @param value The property's new value
         */
        this.fire("near", this._state.near);
    }

    /**
     * Gets the position of the Frustum's near plane on the positive View-space Z-axis.
     *
     * Fires a {@link Frustum#near:emits} emits on change.
     *
     * Default value is ````0.1````.
     *
     * @return {Number} Near frustum plane position.
     */
    get near() {
        return this._state.near;
    }

    /**
     * Sets the position of the Frustum's far plane on the positive View-space Z-axis.
     *
     * Fires a {@link Frustum#far:emits} emits on change.
     *
     * Default value is ````10000.0````.
     *
     * @param {Number} value New far frustum plane position.
     */
    set far(value) {
        this._state.far = (value !== undefined && value !== null) ? value : 10000.0;
        this._needUpdate(0);

        /**
         Fired whenever the Frustum's  {@link Frustum#far} property changes.

         @emits far
         @param value The property's new value
         */
        this.fire("far", this._state.far);
    }

    /**
     * Gets the position of the Frustum's far plane on the positive View-space Z-axis.
     *
     * Default value is ````10000.0````.
     *
     * @return {Number} Far frustum plane position.
     */
    get far() {
        return this._state.far;
    }

    /**
     * Gets the Frustum's projection transform matrix.
     *
     * Fires a {@link Frustum#matrix:emits} emits on change.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @returns {Number[]} The Frustum's projection matrix matrix.
     */
    get matrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.matrix;
    }

    /**
     * Destroys this Frustum.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
        super.destroy();
    }
}

export {Frustum};