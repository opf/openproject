import {utils} from '../../utils.js';

/**
 * @desc Creates a box-shaped {@link Geometry}.
 *
 * ## Usage
 *
 * In the example below we'll create a {@link Mesh} with a box-shaped {@link ReadableGeometry}.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_builders_buildBoxGeometry)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildBoxGeometry} from "../src/scene/geometry/builders/buildBoxGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *         canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildBoxGeometry({
 *         center: [0,0,0],
 *         xSize: 1,  // Half-size on each axis
 *         ySize: 1,
 *         zSize: 1
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *         diffuseMap: new Texture(viewer.scene, {
 *             src: "textures/diffuse/uvGrid2.jpg"
 *         })
 *      })
 * });
 * ````
 *
 * @function buildBoxGeometry
 * @param {*} [cfg] Configs
 * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
 * @param {Number[]} [cfg.center]  3D point indicating the center position.
 * @param {Number} [cfg.xSize=1.0]  Half-size on the X-axis.
 * @param {Number} [cfg.ySize=1.0]  Half-size on the Y-axis.
 * @param {Number} [cfg.zSize=1.0]  Half-size on the Z-axis.
 * @returns {Object} Configuration for a {@link Geometry} subtype.
 */
function buildBoxGeometry(cfg = {}) {

    let xSize = cfg.xSize || 1;
    if (xSize < 0) {
        console.error("negative xSize not allowed - will invert");
        xSize *= -1;
    }

    let ySize = cfg.ySize || 1;
    if (ySize < 0) {
        console.error("negative ySize not allowed - will invert");
        ySize *= -1;
    }

    let zSize = cfg.zSize || 1;
    if (zSize < 0) {
        console.error("negative zSize not allowed - will invert");
        zSize *= -1;
    }

    const center = cfg.center;
    const centerX = center ? center[0] : 0;
    const centerY = center ? center[1] : 0;
    const centerZ = center ? center[2] : 0;

    const xmin = -xSize + centerX;
    const ymin = -ySize + centerY;
    const zmin = -zSize + centerZ;
    const xmax = xSize + centerX;
    const ymax = ySize + centerY;
    const zmax = zSize + centerZ;

    return utils.apply(cfg, {

        // The vertices - eight for our cube, each
        // one spanning three array elements for X,Y and Z
        positions: [

            // v0-v1-v2-v3 front
            xmax, ymax, zmax,
            xmin, ymax, zmax,
            xmin, ymin, zmax,
            xmax, ymin, zmax,

            // v0-v3-v4-v1 right
            xmax, ymax, zmax,
            xmax, ymin, zmax,
            xmax, ymin, zmin,
            xmax, ymax, zmin,

            // v0-v1-v6-v1 top
            xmax, ymax, zmax,
            xmax, ymax, zmin,
            xmin, ymax, zmin,
            xmin, ymax, zmax,

            // v1-v6-v7-v2 left
            xmin, ymax, zmax,
            xmin, ymax, zmin,
            xmin, ymin, zmin,
            xmin, ymin, zmax,

            // v7-v4-v3-v2 bottom
            xmin, ymin, zmin,
            xmax, ymin, zmin,
            xmax, ymin, zmax,
            xmin, ymin, zmax,

            // v4-v7-v6-v1 back
            xmax, ymin, zmin,
            xmin, ymin, zmin,
            xmin, ymax, zmin,
            xmax, ymax, zmin
        ],

        // Normal vectors, one for each vertex
        normals: [

            // v0-v1-v2-v3 front
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,
            0, 0, 1,

            // v0-v3-v4-v5 right
            1, 0, 0,
            1, 0, 0,
            1, 0, 0,
            1, 0, 0,

            // v0-v5-v6-v1 top
            0, 1, 0,
            0, 1, 0,
            0, 1, 0,
            0, 1, 0,

            // v1-v6-v7-v2 left
            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,
            -1, 0, 0,

            // v7-v4-v3-v2 bottom
            0, -1, 0,
            0, -1, 0,
            0, -1, 0,
            0, -1, 0,

            // v4-v7-v6-v5 back
            0, 0, -1,
            0, 0, -1,
            0, 0, -1,
            0, 0, -1
        ],

        // UV coords
        uv: [

            // v0-v1-v2-v3 front
            1, 0,
            0, 0,
            0, 1,
            1, 1,

            // v0-v3-v4-v1 right
            0, 0,
            0, 1,
            1, 1,
            1, 0,

            // v0-v1-v6-v1 top
            1, 1,
            1, 0,
            0, 0,
            0, 1,

            // v1-v6-v7-v2 left
            1, 0,
            0, 0,
            0, 1,
            1, 1,

            // v7-v4-v3-v2 bottom
            0, 1,
            1, 1,
            1, 0,
            0, 0,

            // v4-v7-v6-v1 back
            0, 1,
            1, 1,
            1, 0,
            0, 0
        ],

        // Indices - these organise the
        // positions and uv texture coordinates
        // into geometric primitives in accordance
        // with the "primitive" parameter,
        // in this case a set of three indices
        // for each triangle.
        //
        // Note that each triangle is specified
        // in counter-clockwise winding order.
        //
        // You can specify them in clockwise
        // order if you configure the Modes
        // node's frontFace flag as "cw", instead of
        // the default "ccw".
        indices: [
            0, 1, 2,
            0, 2, 3,
            // front
            4, 5, 6,
            4, 6, 7,
            // right
            8, 9, 10,
            8, 10, 11,
            // top
            12, 13, 14,
            12, 14, 15,
            // left
            16, 17, 18,
            16, 18, 19,
            // bottom
            20, 21, 22,
            20, 22, 23
        ]
    });
}

export {buildBoxGeometry};
