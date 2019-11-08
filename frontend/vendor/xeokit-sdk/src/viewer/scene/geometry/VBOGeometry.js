import {Geometry} from './Geometry.js';
import {RenderState} from '../webgl/RenderState.js';
import {ArrayBuf} from '../webgl/ArrayBuf.js';
import {math} from '../math/math.js';
import {stats} from '../stats.js';
import {WEBGL_INFO} from '../webglInfo.js';
import {buildEdgeIndices} from '../math/buildEdgeIndices.js';
import {geometryCompressionUtils} from '../math/geometryCompressionUtils.js';

const memoryStats = stats.memory;
const bigIndicesSupported = WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"];
const IndexArrayType = bigIndicesSupported ? Uint32Array : Uint16Array;
const tempAABB = math.AABB3();

/**
 * @desc A {@link Geometry} that keeps its geometry data solely in GPU memory, without retaining it in browser memory.
 *
 * VBOGeometry uses less memory than {@link ReadableGeometry}, which keeps its geometry data in both browser and GPU memory.
 *
 * ## Usage
 *
 * Creating a {@link Mesh} with a VBOGeometry that defines a single triangle, plus a {@link PhongMaterial} with diffuse {@link Texture}:
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_VBOGeometry)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {VBOGeometry} from "../src/scene/geometry/VBOGeometry.js"
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *         canvasId: "myCanvas"
 *     });
 *
 * new Mesh(viewer.scene, {
 *         geometry: new VBOGeometry(viewer.scene, {
 *             primitive: "triangles",
 *             positions: [0.0, 3, 0.0, -3, -3, 0.0, 3, -3, 0.0],
 *             normals: [0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0],
 *             uv: [0.0, 0.0, 0.5, 1.0, 1.0, 0.0],
 *             indices: [0, 1, 2]
 *         }),
 *         material: new PhongMaterial(viewer.scene, {
 *             diffuseMap: new Texture(viewer.scene, {
 *                 src: "textures/diffuse/uvGrid2.jpg"
 *             }),
 *             backfaces: true
 *         })
 *     });
 * ````
 */
class VBOGeometry extends Geometry {

    /**
     @private
     */
    get type() {
        return "VBOGeometry";
    }

    /**
     * @private
     * @returns {boolean}
     */
    get isVBOGeometry() {
        return true;
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {String} [cfg.primitive="triangles"]  The primitive type. Accepted values are 'points', 'lines', 'line-loop', 'line-strip', 'triangles', 'triangle-strip' and 'triangle-fan'.
     * @param {Number[]} [cfg.positions]  Positions array.
     * @param {Number[]} [cfg.normals]  Vertex normal vectors array.
     * @param {Number[]} [cfg.uv]  UVs array.
     * @param {Number[]} [cfg.colors]  Vertex colors.
     * @param {Number[]} [cfg.indices]  Indices array.
     * @param {Number} [cfg.edgeThreshold=10]  When autogenerating edges for supporting {@link Drawable#edges}, this indicates the threshold angle (in degrees) between the face normals of adjacent triangles below which the edge is discarded.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({ // Arrays for emphasis effects are got from xeokit.GeometryLite friend methods
            compressGeometry: true,
            primitive: null, // WebGL enum
            primitiveName: null, // String
            positionsDecodeMatrix: null, // Set when compressGeometry == true
            uvDecodeMatrix: null, // Set when compressGeometry == true
            positionsBuf: null,
            normalsBuf: null,
            colorsbuf: null,
            uvBuf: null,
            indicesBuf: null,
            hash: ""
        });

        this._edgeThreshold = cfg.edgeThreshold || 10.0;
        this._aabb = null;
        this._obb = math.OBB3();

        const state = this._state;
        const gl = this.scene.canvas.gl;

        cfg.primitive = cfg.primitive || "triangles";
        switch (cfg.primitive) {
            case "points":
                state.primitive = gl.POINTS;
                state.primitiveName = cfg.primitive;
                break;
            case "lines":
                state.primitive = gl.LINES;
                state.primitiveName = cfg.primitive;
                break;
            case "line-loop":
                state.primitive = gl.LINE_LOOP;
                state.primitiveName = cfg.primitive;
                break;
            case "line-strip":
                state.primitive = gl.LINE_STRIP;
                state.primitiveName = cfg.primitive;
                break;
            case "triangles":
                state.primitive = gl.TRIANGLES;
                state.primitiveName = cfg.primitive;
                break;
            case "triangle-strip":
                state.primitive = gl.TRIANGLE_STRIP;
                state.primitiveName = cfg.primitive;
                break;
            case "triangle-fan":
                state.primitive = gl.TRIANGLE_FAN;
                state.primitiveName = cfg.primitive;
                break;
            default:
                this.error("Unsupported value for 'primitive': '" + cfg.primitive +
                    "' - supported values are 'points', 'lines', 'line-loop', 'line-strip', 'triangles', " +
                    "'triangle-strip' and 'triangle-fan'. Defaulting to 'triangles'.");
                state.primitive = gl.TRIANGLES;
                state.primitiveName = cfg.primitive;
        }

        if (!cfg.positions) {
            this.error("Config expected: positions");
            return; // TODO: Recover?
        }

        if (!cfg.indices) {
            this.error("Config expected: indices");
            return; // TODO: Recover?
        }

        var positions;

        {
            const positionsDecodeMatrix = cfg.positionsDecodeMatrix;

            if (positionsDecodeMatrix) {

                // Compressed positions

            } else {

                // Uncompressed positions

                const bounds = geometryCompressionUtils.getPositionsBounds(cfg.positions);
                const result = geometryCompressionUtils.compressPositions(cfg.positions, bounds.min, bounds.max);
                positions = result.quantized;
                state.positionsDecodeMatrix = result.decodeMatrix;
                state.positionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, positions, positions.length, 3, gl.STATIC_DRAW);
                memoryStats.positions += state.positionsBuf.numItems;
                math.positions3ToAABB3(cfg.positions, this._aabb);
                math.positions3ToAABB3(positions, tempAABB, state.positionsDecodeMatrix);
                math.AABB3ToOBB3(tempAABB, this._obb);
            }
        }

        if (cfg.colors) {
            const colors = cfg.colors.constructor === Float32Array ? cfg.colors : new Float32Array(cfg.colors);
            state.colorsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, colors, colors.length, 4, gl.STATIC_DRAW);
            memoryStats.colors += state.colorsBuf.numItems;
        }

        if (cfg.uv) {
            const bounds = geometryCompressionUtils.getUVBounds(cfg.uv);
            const result = geometryCompressionUtils.compressUVs(cfg.uv, bounds.min, bounds.max);
            const uv = result.quantized;
            state.uvDecodeMatrix = result.decodeMatrix;
            state.uvBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, uv, uv.length, 2, gl.STATIC_DRAW);
            memoryStats.uvs += state.uvBuf.numItems;
        }

        if (cfg.normals) {
            const normals = geometryCompressionUtils.compressNormals(cfg.normals);
            let normalized = state.compressGeometry;
            state.normalsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, normals, normals.length, 3, gl.STATIC_DRAW, normalized);
            memoryStats.normals += state.normalsBuf.numItems;
        }

        if (!bigIndicesSupported && cfg.indices.constructor === Uint32Array) {
            this.error("This WebGL implementation does not support Uint32Array");
            return; // TODO: Recover?
        }

        {
            const indices = (cfg.indices.constructor === Uint32Array || cfg.indices.constructor === Uint16Array) ? cfg.indices : new IndexArrayType(cfg.indices);
            state.indicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, indices, indices.length, 1, gl.STATIC_DRAW);
            memoryStats.indices += state.indicesBuf.numItems;
            const edgeIndices = buildEdgeIndices(positions, indices, state.positionsDecodeMatrix, this._edgeThreshold);
            this._edgeIndicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, edgeIndices, edgeIndices.length, 1, gl.STATIC_DRAW);
        }

        this._buildHash();

        memoryStats.meshes++;
    }

    _buildHash() {
        const state = this._state;
        const hash = ["/g"];
        hash.push("/" + state.primitive + ";");
        if (state.positionsBuf) {
            hash.push("p");
        }
        if (state.colorsBuf) {
            hash.push("c");
        }
        if (state.normalsBuf || state.autoVertexNormals) {
            hash.push("n");
        }
        if (state.uvBuf) {
            hash.push("u");
        }
        hash.push("cp"); // Always compressed
        hash.push(";");
        state.hash = hash.join("");
    }

    _getEdgeIndices() {
        return this._edgeIndicesBuf;
    }

    /**
     * Gets the primitive type.
     *
     * Possible types are: 'points', 'lines', 'line-loop', 'line-strip', 'triangles', 'triangle-strip' and 'triangle-fan'.
     *
     * @type {String}
     */
    get primitive() {
        return this._state.primitiveName;
    }

    /**
     * Gets the local-space axis-aligned 3D boundary (AABB).
     *
     * The AABB is represented by a six-element Float32Array containing the min/max extents of the axis-aligned volume, ie. ````[xmin, ymin,zmin,xmax,ymax, zmax]````.
     *
     * @type {Number[]}
     */
    get aabb() {
        return this._aabb;
    }

    /**
     * Gets the local-space oriented 3D boundary (OBB).
     *
     * The OBB is represented by a 32-element Float32Array containing the eight vertices of the box, where each vertex is a homogeneous coordinate having [x,y,z,w] elements.
     *
     * @type {Number[]}
     */
    get obb() {
        return this._obb;
    }

    /** @private */
    _getState() {
        return this._state;
    }

    /**
     * Destroys this component.
     */
    destroy() {
        super.destroy();
        const state = this._state;
        if (state.indicesBuf) {
            state.indicesBuf.destroy();
        }
        if (state.positionsBuf) {
            state.positionsBuf.destroy();
        }
        if (state.normalsBuf) {
            state.normalsBuf.destroy();
        }
        if (state.uvBuf) {
            state.uvBuf.destroy();
        }
        if (state.colorsBuf) {
            state.colorsBuf.destroy();
        }
        if (this._edgeIndicesBuf) {
            this._edgeIndicesBuf.destroy();
        }
        state.destroy();
        memoryStats.meshes--;
    }
}

export {VBOGeometry};