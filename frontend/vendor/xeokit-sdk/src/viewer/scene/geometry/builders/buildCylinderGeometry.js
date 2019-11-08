import {utils} from '../../utils.js';

/**
 * @desc Creates a cylinder-shaped {@link Geometry}.
 *
 * ## Usage
 *
 * Creating a {@link Mesh} with a cylinder-shaped {@link ReadableGeometry} :
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_builders_buildCylinderGeometry)]
 *
 * ````javascript
 *
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildCylinderGeometry} from "../src/scene/geometry/builders/buildCylinderGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 *  });
 *
 * viewer.camera.eye = [0, 0, 5];
 * viewer.camera.look = [0, 0, 0];
 * viewer.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildCylinderGeometry({
 *          center: [0,0,0],
 *          radiusTop: 2.0,
 *          radiusBottom: 2.0,
 *          height: 5.0,
 *          radialSegments: 20,
 *          heightSegments: 1,
 *          openEnded: false
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *         diffuseMap: new Texture(viewer.scene, {
 *             src: "textures/diffuse/uvGrid2.jpg"
 *         })
 *      })
 * });
 * ````
 *
 * @function buildCylinderGeometry
 * @param {*} [cfg] Configs
 * @param {String} [cfg.id] Optional ID for the {@link Geometry}, unique among all components in the parent {@link Scene}, generated automatically when omitted.
 * @param {Number[]} [cfg.center]  3D point indicating the center position.
 * @param {Number} [cfg.radiusTop=1]  Radius of top.
 * @param {Number} [cfg.radiusBottom=1]  Radius of bottom.
 * @param {Number} [cfg.height=1] Height.
 * @param {Number} [cfg.radialSegments=60]  Number of horizontal segments.
 * @param {Number} [cfg.heightSegments=1]  Number of vertical segments.
 * @param {Boolean} [cfg.openEnded=false]  Whether or not the cylinder has solid caps on the ends.
 * @returns {Object} Configuration for a {@link Geometry} subtype.
 */
function buildCylinderGeometry(cfg = {}) {

    let radiusTop = cfg.radiusTop || 1;
    if (radiusTop < 0) {
        console.error("negative radiusTop not allowed - will invert");
        radiusTop *= -1;
    }

    let radiusBottom = cfg.radiusBottom || 1;
    if (radiusBottom < 0) {
        console.error("negative radiusBottom not allowed - will invert");
        radiusBottom *= -1;
    }

    let height = cfg.height || 1;
    if (height < 0) {
        console.error("negative height not allowed - will invert");
        height *= -1;
    }

    let radialSegments = cfg.radialSegments || 32;
    if (radialSegments < 0) {
        console.error("negative radialSegments not allowed - will invert");
        radialSegments *= -1;
    }
    if (radialSegments < 3) {
        radialSegments = 3;
    }

    let heightSegments = cfg.heightSegments || 1;
    if (heightSegments < 0) {
        console.error("negative heightSegments not allowed - will invert");
        heightSegments *= -1;
    }
    if (heightSegments < 1) {
        heightSegments = 1;
    }

    const openEnded = !!cfg.openEnded;

    let center = cfg.center;
    const centerX = center ? center[0] : 0;
    const centerY = center ? center[1] : 0;
    const centerZ = center ? center[2] : 0;

    const heightHalf = height / 2;
    const heightLength = height / heightSegments;
    const radialAngle = (2.0 * Math.PI / radialSegments);
    const radialLength = 1.0 / radialSegments;
    //var nextRadius = this._radiusBottom;
    const radiusChange = (radiusTop - radiusBottom) / heightSegments;

    const positions = [];
    const normals = [];
    const uvs = [];
    const indices = [];

    let h;
    let i;

    let x;
    let z;

    let currentRadius;
    let currentHeight;

    let first;
    let second;

    let startIndex;
    let tu;
    let tv;

    // create vertices
    const normalY = (90.0 - (Math.atan(height / (radiusBottom - radiusTop))) * 180 / Math.PI) / 90.0;

    for (h = 0; h <= heightSegments; h++) {
        currentRadius = radiusTop - h * radiusChange;
        currentHeight = heightHalf - h * heightLength;

        for (i = 0; i <= radialSegments; i++) {
            x = Math.sin(i * radialAngle);
            z = Math.cos(i * radialAngle);

            normals.push(currentRadius * x);
            normals.push(normalY); //todo
            normals.push(currentRadius * z);

            uvs.push((i * radialLength));
            uvs.push(h * 1 / heightSegments);

            positions.push((currentRadius * x) + centerX);
            positions.push((currentHeight) + centerY);
            positions.push((currentRadius * z) + centerZ);
        }
    }

    // create faces
    for (h = 0; h < heightSegments; h++) {
        for (i = 0; i <= radialSegments; i++) {

            first = h * (radialSegments + 1) + i;
            second = first + radialSegments;

            indices.push(first);
            indices.push(second);
            indices.push(second + 1);

            indices.push(first);
            indices.push(second + 1);
            indices.push(first + 1);
        }
    }

    // create top cap
    if (!openEnded && radiusTop > 0) {
        startIndex = (positions.length / 3);

        // top center
        normals.push(0.0);
        normals.push(1.0);
        normals.push(0.0);

        uvs.push(0.5);
        uvs.push(0.5);

        positions.push(0 + centerX);
        positions.push(heightHalf + centerY);
        positions.push(0 + centerZ);

        // top triangle fan
        for (i = 0; i <= radialSegments; i++) {
            x = Math.sin(i * radialAngle);
            z = Math.cos(i * radialAngle);
            tu = (0.5 * Math.sin(i * radialAngle)) + 0.5;
            tv = (0.5 * Math.cos(i * radialAngle)) + 0.5;

            normals.push(radiusTop * x);
            normals.push(1.0);
            normals.push(radiusTop * z);

            uvs.push(tu);
            uvs.push(tv);

            positions.push((radiusTop * x) + centerX);
            positions.push((heightHalf) + centerY);
            positions.push((radiusTop * z) + centerZ);
        }

        for (i = 0; i < radialSegments; i++) {
            center = startIndex;
            first = startIndex + 1 + i;

            indices.push(first);
            indices.push(first + 1);
            indices.push(center);
        }
    }

    // create bottom cap
    if (!openEnded && radiusBottom > 0) {

        startIndex = (positions.length / 3);

        // top center
        normals.push(0.0);
        normals.push(-1.0);
        normals.push(0.0);

        uvs.push(0.5);
        uvs.push(0.5);

        positions.push(0 + centerX);
        positions.push(0 - heightHalf + centerY);
        positions.push(0 + centerZ);

        // top triangle fan
        for (i = 0; i <= radialSegments; i++) {

            x = Math.sin(i * radialAngle);
            z = Math.cos(i * radialAngle);

            tu = (0.5 * Math.sin(i * radialAngle)) + 0.5;
            tv = (0.5 * Math.cos(i * radialAngle)) + 0.5;

            normals.push(radiusBottom * x);
            normals.push(-1.0);
            normals.push(radiusBottom * z);

            uvs.push(tu);
            uvs.push(tv);

            positions.push((radiusBottom * x) + centerX);
            positions.push((0 - heightHalf) + centerY);
            positions.push((radiusBottom * z) + centerZ);
        }

        for (i = 0; i < radialSegments; i++) {

            center = startIndex;
            first = startIndex + 1 + i;

            indices.push(center);
            indices.push(first + 1);
            indices.push(first);
        }
    }

    return utils.apply(cfg, {
        positions: positions,
        normals: normals,
        uv: uvs,
        indices: indices
    });
}


export {buildCylinderGeometry};
