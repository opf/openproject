import {utils} from '../../utils.js';
import {K3D} from '../../libs/k3d.js';

/**
 * @desc Loads {@link Geometry} from 3DS.
 *
 * ## Usage
 *
 * In the example below we'll create a {@link Mesh} with {@link PhongMaterial}, {@link Texture} and a {@link ReadableGeometry} loaded from 3DS.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_loaders_3DS)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {load3DSGeometry} from "../src/scene/geometry/loaders/load3DSGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [40.04, 23.46, 79.06];
 * viewer.scene.camera.look = [-6.48, 13.92, -0.56];
 * viewer.scene.camera.up = [-0.04, 0.98, -0.08];
 *
 * load3DSGeometry(viewer.scene, {
 *      src: "models/3ds/lexus.3ds",
 *      compressGeometry: false
 *
 *  }).then(function (geometryCfg) {
 *
 *      // Success
 *
 *      new Mesh(viewer.scene, {
 *
 *          geometry: new ReadableGeometry(viewer.scene, geometryCfg),
 *
 *          material: new PhongMaterial(viewer.scene, {
 *
 *              emissive: [1, 1, 1],
 *              emissiveMap: new Texture({  // .3DS has no normals so relies on emissive illumination
 *                  src: "models/3ds/lexus.jpg"
 *              })
 *          }),
 *
 *          rotation: [-90, 0, 0] // +Z is up for this particular 3DS
 *      });
 *  }, function () {
 *      // Error
 *  });
 * ````
 *
 * @function load3DSGeometry
 * @param {Scene} scene Scene we're loading the geometry for.
 * @param {*} cfg Configs, also added to the result object.
 * @param {String} [cfg.src]  Path to 3DS file.
 * @returns {Object} Configuration to pass into a {@link Geometry} constructor, containing geometry arrays loaded from the OBJ file.
 */
function load3DSGeometry(scene, cfg = {}) {

    return new Promise(function (resolve, reject) {

        if (!cfg.src) {
            console.error("load3DSGeometry: Parameter expected: src");
            reject();
        }

        var spinner = scene.canvas.spinner;
        spinner.processes++;

        utils.loadArraybuffer(cfg.src, function (data) {

                if (!data.byteLength) {
                    console.error("load3DSGeometry: no data loaded");
                    spinner.processes--;
                    reject();
                }

                var m = K3D.parse.from3DS(data);	// done !

                var mesh = m.edit.objects[0].mesh;
                var positions = mesh.vertices;
                var uv = mesh.uvt;
                var indices = mesh.indices;

                spinner.processes--;

                resolve(utils.apply(cfg, {
                    primitive: "triangles",
                    positions: positions,
                    normals: null,
                    uv: uv,
                    indices: indices
                }));
            },

            function (msg) {
                console.error("load3DSGeometry: " + msg);
                spinner.processes--;
                reject();
            });
    });
}

export {load3DSGeometry};
