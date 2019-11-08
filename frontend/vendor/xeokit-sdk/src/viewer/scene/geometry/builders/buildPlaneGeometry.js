import {utils} from '../../utils.js';

/**
 * @desc Creates a plane-shaped {@link Geometry}.
 *
 * ## Usage
 *
 * Creating a {@link Mesh} with a PlaneGeometry and a {@link PhongMaterial} with diffuse {@link Texture}:
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_builders_buildPlaneGeometry)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildPlaneGeometry} from "../src/scene/geometry/builders/buildPlaneGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.camera.eye = [0, 0, 5];
 * viewer.camera.look = [0, 0, 0];
 * viewer.camera.up = [0, 1, 0];

 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildPlaneGeometry({
 *          center: [0,0,0],
 *          xSize: 2,
 *          zSize: 2,
 *          xSegments: 10,
 *          zSegments: 10
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          })
 *      })
 *  });
 * ````
 *
 * @function buildPlaneGeometry
 * @param {*} [cfg] Configs
 * @param {Number[]} [cfg.center]  3D point indicating the center position.
 * @param {String} [cfg.id] Optional ID for the {@link Geometry}, unique among all components in the parent {@link Scene}, generated automatically when omitted.
 * @param {Number} [cfg.xSize=1] Dimension on the X-axis.
 * @param {Number} [cfg.zSize=1] Dimension on the Z-axis.
 * @param {Number} [cfg.xSegments=1] Number of segments on the X-axis.
 * @param {Number} [cfg.zSegments=1] Number of segments on the Z-axis.
 * @returns {Object} Configuration for a {@link Geometry} subtype.
 */
function buildPlaneGeometry(cfg = {}) {

    let xSize = cfg.xSize || 1;
    if (xSize < 0) {
        console.error("negative xSize not allowed - will invert");
        xSize *= -1;
    }

    let zSize = cfg.zSize || 1;
    if (zSize < 0) {
        console.error("negative zSize not allowed - will invert");
        zSize *= -1;
    }

    let xSegments = cfg.xSegments || 1;
    if (xSegments < 0) {
        console.error("negative xSegments not allowed - will invert");
        xSegments *= -1;
    }
    if (xSegments < 1) {
        xSegments = 1;
    }

    let zSegments = cfg.xSegments || 1;
    if (zSegments < 0) {
        console.error("negative zSegments not allowed - will invert");
        zSegments *= -1;
    }
    if (zSegments < 1) {
        zSegments = 1;
    }

    const center = cfg.center;
    const centerX = center ? center[0] : 0;
    const centerY = center ? center[1] : 0;
    const centerZ = center ? center[2] : 0;

    const halfWidth = xSize / 2;
    const halfHeight = zSize / 2;

    const planeX = Math.floor(xSegments) || 1;
    const planeZ = Math.floor(zSegments) || 1;

    const planeX1 = planeX + 1;
    const planeZ1 = planeZ + 1;

    const segmentWidth = xSize / planeX;
    const segmentHeight = zSize / planeZ;

    const positions = new Float32Array(planeX1 * planeZ1 * 3);
    const normals = new Float32Array(planeX1 * planeZ1 * 3);
    const uvs = new Float32Array(planeX1 * planeZ1 * 2);

    let offset = 0;
    let offset2 = 0;

    let iz;
    let ix;
    let x;
    let a;
    let b;
    let c;
    let d;

    for (iz = 0; iz < planeZ1; iz++) {

        const z = iz * segmentHeight - halfHeight;

        for (ix = 0; ix < planeX1; ix++) {

            x = ix * segmentWidth - halfWidth;

            positions[offset] = x + centerX;
            positions[offset + 1] = centerY;
            positions[offset + 2] = -z + centerZ;

            normals[offset + 2] = -1;

            uvs[offset2] = (planeX - ix) / planeX;
            uvs[offset2 + 1] = ((planeZ - iz) / planeZ);

            offset += 3;
            offset2 += 2;
        }
    }

    offset = 0;

    const indices = new ((positions.length / 3) > 65535 ? Uint32Array : Uint16Array)(planeX * planeZ * 6);

    for (iz = 0; iz < planeZ; iz++) {

        for (ix = 0; ix < planeX; ix++) {

            a = ix + planeX1 * iz;
            b = ix + planeX1 * (iz + 1);
            c = (ix + 1) + planeX1 * (iz + 1);
            d = (ix + 1) + planeX1 * iz;

            indices[offset] = d;
            indices[offset + 1] = b;
            indices[offset + 2] = a;

            indices[offset + 3] = d;
            indices[offset + 4] = c;
            indices[offset + 5] = b;

            offset += 6;
        }
    }

    return utils.apply(cfg, {
        positions: positions,
        normals: normals,
        uv: uvs,
        indices: indices
    });
}

export {buildPlaneGeometry};
