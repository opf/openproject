/**
 A **Shadow** defines a shadow cast by a {@link DirLight} or a {@link SpotLight}.

 Work in progress!

 ## Overview

 * Shadows are attached to {@link DirLight} and {@link SpotLight} components.

 TODO

 ## Examples

 TODO

 ## Usage

 ```` javascript
 var mesh = new xeokit.Mesh(scene, {

        lights: new xeokit.Lights({
            lights: [

                new xeokit.SpotLight({
                    pos: [0, 100, 100],
                    dir: [0, -1, 0],
                    color: [0.5, 0.7, 0.5],
                    intensity: 1
                    constantAttenuation: 0,
                    linearAttenuation: 0,
                    quadraticAttenuation: 0,
                    space: "view",

                    shadow: new xeokit.Shadow({
                        resolution: [1000, 1000],
                        intensity: 0.7,
                        sampling: "stratified" // "stratified" | "poisson" | "basic"
                    });
                })
            ]
        }),
 ,
        material: new xeokit.PhongMaterial({
            diffuse: [0.5, 0.5, 0.0]
        }),

        geometry: new xeokit.BoxGeometry()
  });
 ````

 @class Shadow
 @module xeokit
 @submodule lighting
 @constructor
 @extends Component
 @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
 @param {*} [cfg] The Shadow configuration
 @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
 @param {String:Object} [cfg.meta] Optional map of user-defined metadata to attach to this Shadow.
 @param [cfg.resolution=[1000,1000]] {Uint16Array} Resolution of the texture map for this Shadow.
 @param [cfg.intensity=1.0] {Number} Intensity of this Shadow.
 */
import {Component} from '../Component.js';
import {math} from '../math/math.js';

class Shadow extends Component {

    /**
     @private
     */
    get type() {
        return "Shadow";
    }

    constructor(owner, cfg={}) {
        super(owner, cfg);
        this._state = {
            resolution: math.vec3([1000, 1000]),
            intensity: 1.0
        };
        this.resolution = cfg.resolution;
        this.intensity = cfg.intensity;
    }

    /**
     The resolution of the texture map for this Shadow.

     This will be either World- or View-space, depending on the value of {@link Shadow/space}.

     Fires a {@link Shadow/resolution:event} event on change.

     @property resolution
     @default [1000, 1000]
     @type Uint16Array
     */
    set resolution(value) {

        this._state.resolution.set(value || [1000.0, 1000.0]);

        this.glRedraw();

        /**
         Fired whenever this Shadow's  {@link Shadow/resolution} property changes.
         @event resolution
         @param value The property's new value
         */
        this.fire("resolution", this._state.resolution);
    }

    get resolution() {
        return this._state.resolution;
    }

    /**
     The intensity of this Shadow.

     Fires a {@link Shadow/intensity:event} event on change.

     @property intensity
     @default 1.0
     @type {Number}
     */
    set intensity(value) {

        value = value !== undefined ? value : 1.0;

        this._state.intensity = value;

        this.glRedraw();

        /**
         * Fired whenever this Shadow's  {@link Shadow/intensity} property changes.
         * @event intensity
         * @param value The property's new value
         */
        this.fire("intensity", this._state.intensity);
    }

    get intensity() {
        return this._state.intensity;
    }

    destroy() {
        super.destroy();
        //this._state.destroy();
    }
}

export {Shadow};
