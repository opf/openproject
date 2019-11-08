import {Map} from "../utils/Map.js";

const ids = new Map({});

/**
 * @desc Represents a chunk of state changes applied by the {@link Scene}'s renderer while it renders a frame.
 *
 * * Contains properties that represent the state changes.
 * * Has a unique automatically-generated numeric ID, which the renderer can use to sort these, in order to avoid applying redundant state changes for each frame.
 * * Initialize your own properties on a RenderState via its constructor.
 *
 * @private
 */
class RenderState {

    constructor(cfg) {

        /**
         The RenderState's ID, unique within the renderer.
         @property id
         @type {Number}
         @final
         */
        this.id = ids.addItem({});
        for (const key in cfg) {
            if (cfg.hasOwnProperty(key)) {
                this[key] = cfg[key];
            }
        }
    }

    /**
     Destroys this RenderState.
     */
    destroy() {
        ids.removeItem(this.id);
    }
}

export {RenderState};