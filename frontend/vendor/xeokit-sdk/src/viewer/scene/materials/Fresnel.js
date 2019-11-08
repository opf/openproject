import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {math} from '../math/math.js';

/**
 * @desc Configures Fresnel effects for {@link PhongMaterial}s.
 *
 * Fresnels are attached to {@link PhongMaterial}s, which are attached to {@link Mesh}es.
 *
 * ## Usage
 *
 * In the example below we'll create a {@link Mesh} with a {@link PhongMaterial} that applies a Fresnel to its alpha channel to give a glasss-like effect.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#materials_Fresnel)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildTorusGeometry} from "../src/scene/geometry/builders/buildTorusGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 * import {Fresnel} from "../src/scene/materials/Fresnel.js";
 *
 * const viewer = new Viewer({
 *       canvasId: "myCanvas",
 *       transparent: true
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildTorusGeometry({
 *          center: [0, 0, 0],
 *          radius: 1.5,
 *          tube: 0.5,
 *          radialSegments: 32,
 *          tubeSegments: 24,
 *          arc: Math.PI * 2.0
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          alpha: 0.9,
 *          alphaMode: "blend",
 *          ambient: [0.0, 0.0, 0.0],
 *          shininess: 30,
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          }),
 *          alphaFresnel: new Fresnel(viewer.scene, {
v               edgeBias: 0.2,
 *              centerBias: 0.8,
 *              edgeColor: [1.0, 1.0, 1.0],
 *              centerColor: [0.0, 0.0, 0.0],
 *              power: 2
 *          })
 *      })
 * });
 * ````
 */
class Fresnel extends Component {

    /**
     * JavaScript class name for this Component.
     *
     * @type {String}
     */
    get type() {
        return "Fresnel";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this Fresnel as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent scene, generated automatically when omitted.
     * @param {Number[]} [cfg.edgeColor=[ 0.0, 0.0, 0.0 ]]  Color used on edges.
     * @param {Number[]} [cfg.centerColor=[ 1.0, 1.0, 1.0 ]]  Color used on center.
     * @param {Number} [cfg.edgeBias=0]  Bias at the edge.
     * @param {Number} [cfg.centerBias=1]  Bias at the center.
     * @param {Number} [cfg.power=0]  The power.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            edgeColor: math.vec3([0, 0, 0]),
            centerColor: math.vec3([1, 1, 1]),
            edgeBias: 0,
            centerBias: 1,
            power: 1
        });

        this.edgeColor = cfg.edgeColor;
        this.centerColor = cfg.centerColor;
        this.edgeBias = cfg.edgeBias;
        this.centerBias = cfg.centerBias;
        this.power = cfg.power;
    }

    /**
     * Sets the Fresnel's edge color.
     *
     * Default value is ````[0.0, 0.0, 0.0]````.
     *
     * @type {Number[]}
     */
    set edgeColor(value) {
        this._state.edgeColor.set(value || [0.0, 0.0, 0.0]);
        this.glRedraw();
    }

    /**
     * Gets the Fresnel's edge color.
     *
     * Default value is ````[0.0, 0.0, 0.0]````.
     *
     * @type {Number[]}
     */
    get edgeColor() {
        return this._state.edgeColor;
    }

    /**
     * Sets the Fresnel's center color.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @type {Number[]}
     */
    set centerColor(value) {
        this._state.centerColor.set(value || [1.0, 1.0, 1.0]);
        this.glRedraw();
    }

    /**
     * Gets the Fresnel's center color.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @type {Number[]}
     */
    get centerColor() {
        return this._state.centerColor;
    }

    /**
     * Sets the Fresnel's edge bias.
     *
     * Default value is ````0````.
     *
     * @type {Number}
     */
    set edgeBias(value) {
        this._state.edgeBias = value || 0;
        this.glRedraw();
    }

    /**
     * Gets the Fresnel's edge bias.
     *
     * Default value is ````0````.
     *
     * @type {Number}
     */
    get edgeBias() {
        return this._state.edgeBias;
    }

    /**
     * Sets the Fresnel's center bias.
     *
     * Default value is ````1````.
     *
     * @type {Number}
     */
    set centerBias(value) {
        this._state.centerBias = (value !== undefined && value !== null) ? value : 1;
        this.glRedraw();
    }

    /**
     * Gets the Fresnel's center bias.
     *
     * Default value is ````1````.
     *
     * @type {Number}
     */
    get centerBias() {
        return this._state.centerBias;
    }

    /**
     * Sets the Fresnel's power.
     *
     * Default value is ````1````.
     *
     * @type {Number}
     */
    set power(value) {
        this._state.power = (value !== undefined && value !== null) ? value : 1;
        this.glRedraw();
    }

    /**
     * Gets the Fresnel's power.
     *
     * Default value is ````1````.
     *
     * @type {Number}
     */
    get power() {
        return this._state.power;
    }

    /**
     * Destroys this Fresnel.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {Fresnel};