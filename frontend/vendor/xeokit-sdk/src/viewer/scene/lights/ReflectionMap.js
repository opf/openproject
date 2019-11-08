import {CubeTexture} from './CubeTexture.js';

/**
 * @desc A reflection cube map.
 *
 * ## Usage
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildSphereGeometry} from "../src/scene/geometry/builders/buildSphereGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {MetallicMaterial} from "../src/scene/materials/MetallicMaterial.js";
 * import {ReflectionMap} from "../src/scene/lights/ReflectionMap.js";
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
 * new ReflectionMap(viewer.scene, {
 *     src: [
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_PX.png",
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_NX.png",
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_PY.png",
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_NY.png",
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_PZ.png",
 *         "textures/reflect/Uffizi_Gallery/Uffizi_Gallery_Radiance_NZ.png"
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
class ReflectionMap extends CubeTexture {

    /**
     @private
     */
    get type() {
        return "ReflectionMap";
    }

    /**
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID for this ReflectionMap, unique among all components in the parent scene, generated automatically when omitted.
     * @param {String[]} [cfg.src=null]  Paths to six image files to load into this ReflectionMap.
     * @param {Boolean} [cfg.flipY=false] Flips this ReflectionMap's source data along its vertical axis when true.
     * @param {String} [cfg.encoding="linear"]  Encoding format.  See the {@link ReflectionMap/encoding} property for more info.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this.scene._lightsState.addReflectionMap(this._state);
        this.scene._reflectionMapCreated(this);
    }

    /**
     * Destroys this ReflectionMap.
     */
    destroy() {
        super.destroy();
        this.scene._reflectionMapDestroyed(this);
    }
}

export {ReflectionMap};
