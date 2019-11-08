import {math} from '../math/math.js';
import {Light} from './Light.js';

/**
 * @desc An ambient light source of fixed color and intensity that illuminates all {@link Mesh}es equally.
 *
 * * {@link AmbientLight#color} multiplies by {@link PhongMaterial#ambient} at each position of each {@link ReadableGeometry} surface.
 * * {@link AmbientLight#color} multiplies by {@link LambertMaterial#color} uniformly across each triangle of each {@link ReadableGeometry} (ie. flat shaded).
 * * {@link AmbientLight}s, {@link DirLight}s and {@link PointLight}s are registered by their {@link Component#id} on {@link Scene#lights}.
 *
 * ## Usage
 *
 * In the example below we'll destroy the {@link Scene}'s default light sources then create an AmbientLight and a couple of {@link @DirLight}s:
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#lights_AmbientLight)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildTorusGeometry} from "../src/scene/geometry/builders/buildTorusGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 * import {AmbientLight} from "../src/scene/lights/AmbientLight.js";
 *
 * // Create a Viewer and arrange the camera
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * // Replace the Scene's default lights with a single custom AmbientLight
 *
 * viewer.scene.clearLights();
 *
 * new AmbientLight(viewer.scene, {
 *      color: [0.0, 0.3, 0.7],
 *      intensity: 1.0
 * });
 *
 * new DirLight(viewer.scene, {
 *      id: "keyLight",
 *      dir: [0.8, -0.6, -0.8],
 *      color: [1.0, 0.3, 0.3],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 * new DirLight(viewer.scene, {
 *      id: "fillLight",
 *      dir: [-0.8, -0.4, -0.4],
 *      color: [0.3, 1.0, 0.3],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 * new DirLight(viewer.scene, {
 *      id: "rimLight",
 *      dir: [0.2, -0.8, 0.8],
 *      color: [0.6, 0.6, 0.6],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 * // Create a mesh with torus shape and PhongMaterial
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildSphereGeometry({
 *          center: [0, 0, 0],
 *          radius: 1.5,
 *          tube: 0.5,
 *          radialSegments: 32,
 *          tubeSegments: 24,
 *          arc: Math.PI * 2.0
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          ambient: [1.0, 1.0, 1.0],
 *          shininess: 30,
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          })
 *      })
 * });
 *
 * // Adjust the color of our AmbientLight
 *
 * var ambientLight = viewer.scene.lights["myAmbientLight"];
 * ambientLight.color = [1.0, 0.8, 0.8];
 *````
 */
class AmbientLight extends Light {

    /**
     @private
     */
    get type() {
        return "AmbientLight";
    }

    /**
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this AmbientLight as well.
     * @param {*} [cfg] AmbientLight configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Number[]} [cfg.color=[0.7, 0.7, 0.8]]  The color of this AmbientLight.
     * @param {Number} [cfg.intensity=[1.0]]  The intensity of this AmbientLight, as a factor in range ````[0..1]````.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this._state = {
            type: "ambient",
            color: math.vec3([0.7, 0.7, 0.7]),
            intensity: 1.0
        };
        this.color = cfg.color;
        this.intensity = cfg.intensity;
        this.scene._lightCreated(this);
    }

    /**
     * Sets the RGB color of this AmbientLight.
     *
     * Default value is ````[0.7, 0.7, 0.8]````.
     *
     * @param {Number[]} color The AmbientLight's RGB color.
     */
    set color(color) {
        this._state.color.set(color || [0.7, 0.7, 0.8]);
        this.glRedraw();
    }

    /**
     * Gets the RGB color of this AmbientLight.
     *
     * Default value is ````[0.7, 0.7, 0.8]````.
     *
     * @returns {Number[]} The AmbientLight's RGB color.
     */
    get color() {
        return this._state.color;
    }

    /**
     * Sets the intensity of this AmbientLight.
     *
     * Default value is ````1.0```` for maximum intensity.
     *
     * @param {Number} intensity The AmbientLight's intensity.
     */
    set intensity(intensity) {
        this._state.intensity = intensity !== undefined ? intensity : 1.0;
        this.glRedraw();
    }

    /**
     * Gets the intensity of this AmbientLight.
     *
     * Default value is ````1.0```` for maximum intensity.
     *
     * @returns {Number} The AmbientLight's intensity.
     */
    get intensity() {
        return this._state.intensity;
    }

    /**
     * Destroys this AmbientLight.
     */
    destroy() {
        super.destroy();
    }
}

export {AmbientLight};
