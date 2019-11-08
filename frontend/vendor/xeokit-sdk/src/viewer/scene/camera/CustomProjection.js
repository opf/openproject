import {math} from '../math/math.js';
import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';

/**
 * @desc Defines a custom projection for a {@link Camera} as a custom 4x4 matrix..
 *
 * Located at {@link Camera#customProjection}.
 */
class CustomProjection extends Component {

    /**
     * @private
     */
    get type() {
        return "CustomProjection";
    }

    /**
     * @constructor
     * @private
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this._state = new RenderState({
            matrix: math.mat4()
        });
        this.matrix = cfg.matrix;
    }

    /**
     * Sets the CustomProjection's projection transform matrix.
     *
     * Fires a "matrix" event on change.

     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @param {Number[]} matrix New value for the CustomProjection's matrix.
     */
    set matrix(matrix) {

        this._state.matrix.set(matrix || [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

        this.glRedraw();

        /**
         Fired whenever this CustomProjection's {@link CustomProjection/matrix} property changes.

         @event matrix
         @param value The property's new value
         */
        this.fire("far", this._state.matrix);
    }

    /**
     * Gets the CustomProjection's projection transform matrix.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @return {Number[]} New value for the CustomProjection's matrix.
     */
    get matrix() {
        return this._state.matrix;
    }

    /**
     * Destroys this CustomProjection.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {CustomProjection};