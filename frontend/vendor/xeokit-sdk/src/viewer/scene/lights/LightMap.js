import {CubeTexture} from './CubeTexture.js';

/**
 * @desc A **LightMap** specifies a cube texture light map.
 *
 * ## Usage
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildSphereGeometry} from "../src/scene/geometry/builders/buildSphereGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {MetallicMaterial} from "../src/scene/materials/MetallicMaterial.js";
 * import {LightMap} from "../src/scene/lights/LightMap.js";
 *
 * // Create a Viewer and arrange the camera
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new LightMap(viewer.scene, {
 *     src: [
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_PX.png",
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_NX.png",
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_PY.png",
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_NY.png",
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_PZ.png",
 *         "textures/light/Uffizi_Gallery/Uffizi_Gallery_Irradiance_NZ.png"
 *     ]
 * });
 *
 * // Create a sphere and ground plane
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildSphereGeometry({
 *          radius: 2.0
 *      }),
 *      new MetallicMaterial(viewer.scene, {
 *          baseColor: [1, 1, 1],
 *          metallic: 1.0,
 *          roughness: 1.0
 *      })
 * });
 * ````
 */
class LightMap extends CubeTexture {

    /**
     @private
     */
    get type() {
        return "LightMap";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID for this LightMap, unique among all components in the parent scene, generated automatically when omitted.
     * @param {String:Object} [cfg.meta] Optional map of user-defined metadata to attach to this LightMap.
     * @param {String[]} [cfg.src=null] Paths to six image files to load into this LightMap.
     * @param {Boolean} [cfg.flipY=false] Flips this LightMap's source data along its vertical axis when true.
     * @param {String} [cfg.encoding="linear"] Encoding format.  See the {@link LightMap#encoding} property for more info.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this.scene._lightMapCreated(this);
    }

    destroy() {
        super.destroy();
        this.scene._lightMapDestroyed(this);
    }
}

export {LightMap};
