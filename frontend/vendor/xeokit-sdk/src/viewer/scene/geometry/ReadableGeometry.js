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
 * @desc A {@link Geometry} that keeps its geometry data in both browser and GPU memory.
 *
 * ReadableGeometry uses more memory than {@link VBOGeometry}, which only stores its geometry data in GPU memory.
 *
 * ## Usage
 *
 * Creating a {@link Mesh} with a ReadableGeometry that defines a single triangle, plus a {@link PhongMaterial} with diffuse {@link Texture}:
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#geometry_ReadableGeometry)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js"
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *         canvasId: "myCanvas"
 *     });
 *
 * const myMesh = new Mesh(viewer.scene, {
 *         geometry: new ReadableGeometry(viewer.scene, {
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
 *
 * // Get geometry data from browser memory:
 *
 * const positions = myMesh.geometry.positions; // Flat arrays
 * const normals = myMesh.geometry.normals;
 * const uv = myMesh.geometry.uv;
 * const indices = myMesh.geometry.indices;
 *
 * ````
 */
class ReadableGeometry extends Geometry {

    /**
     @private
     */
    get type() {
        return "ReadableGeometry";
    }

    /**
     * @private
     * @returns {boolean}
     */
    get isReadableGeometry() {
        return true;
    }

    /**
     *
     @class ReadableGeometry
     @module xeokit
     @submodule geometry
     @constructor
     @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     @param {*} [cfg] Configs
     @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene},
     generated automatically when omitted.
     @param {String:Object} [cfg.meta] Optional map of user-defined metadata to attach to this Geometry.
     @param [cfg.primitive="triangles"] {String} The primitive type. Accepted values are 'points', 'lines', 'line-loop', 'line-strip', 'triangles', 'triangle-strip' and 'triangle-fan'.
     @param [cfg.positions] {Number[]} Positions array.
     @param [cfg.normals] {Number[]} Vertex normal vectors array.
     @param [cfg.uv] {Number[]} UVs array.
     @param [cfg.colors] {Number[]} Vertex colors.
     @param [cfg.indices] {Number[]} Indices array.
     @param [cfg.autoVertexNormals=false] {Boolean} Set true to automatically generate normal vectors from the positions and
     indices, if those are supplied.
     @param [cfg.compressGeometry=false] {Boolean} Stores positions, colors, normals and UVs in compressGeometry and oct-encoded formats
     for reduced memory footprint and GPU bus usage.
     @param [cfg.edgeThreshold=10] {Number} When a {@link Mesh} renders this Geometry as wireframe,
     this indicates the threshold angle (in degrees) between the face normals of adjacent triangles below which the edge is discarded.
     @extends Component
     * @param owner
     * @param cfg
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({ // Arrays for emphasis effects are got from xeokit.Geometry friend methods
            compressGeometry: !!cfg.compressGeometry,
            primitive: null, // WebGL enum
            primitiveName: null, // String
            positions: null,    // Uint16Array when compressGeometry == true, else Float32Array
            normals: null,      // Uint8Array when compressGeometry == true, else Float32Array
            colors: null,
            uv: null,           // Uint8Array when compressGeometry == true, else Float32Array
            indices: null,
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

        // Lazy-generated VBOs

        this._edgeIndicesBuf = null;
        this._pickTrianglePositionsBuf = null;
        this._pickTriangleColorsBuf = null;

        // Local-space Boundary3D

        this._aabbDirty = true;

        this._boundingSphere = true;
        this._aabb = null;
        this._aabbDirty = true;

        this._obb = null;
        this._obbDirty = true;

        const state = this._state;
        const gl = this.scene.canvas.gl;

        // Primitive type

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

        if (cfg.positions) {
            if (this._state.compressGeometry) {
                const bounds = geometryCompressionUtils.getPositionsBounds(cfg.positions);
                const result = geometryCompressionUtils.compressPositions(cfg.positions, bounds.min, bounds.max);
                state.positions = result.quantized;
                state.positionsDecodeMatrix = result.decodeMatrix;
            } else {
                state.positions = cfg.positions.constructor === Float32Array ? cfg.positions : new Float32Array(cfg.positions);
            }
        }
        if (cfg.colors) {
            state.colors = cfg.colors.constructor === Float32Array ? cfg.colors : new Float32Array(cfg.colors);
        }
        if (cfg.uv) {
            if (this._state.compressGeometry) {
                const bounds = geometryCompressionUtils.getUVBounds(cfg.uv);
                const result = geometryCompressionUtils.compressUVs(cfg.uv, bounds.min, bounds.max);
                state.uv = result.quantized;
                state.uvDecodeMatrix = result.decodeMatrix;
            } else {
                state.uv = cfg.uv.constructor === Float32Array ? cfg.uv : new Float32Array(cfg.uv);
            }
        }
        if (cfg.normals) {
            if (this._state.compressGeometry) {
                state.normals = geometryCompressionUtils.compressNormals(cfg.normals);
            } else {
                state.normals = cfg.normals.constructor === Float32Array ? cfg.normals : new Float32Array(cfg.normals);
            }
        }
        if (cfg.indices) {
            if (!bigIndicesSupported && cfg.indices.constructor === Uint32Array) {
                this.error("This WebGL implementation does not support Uint32Array");
                return;
            }
            state.indices = (cfg.indices.constructor === Uint32Array || cfg.indices.constructor === Uint16Array) ? cfg.indices : new IndexArrayType(cfg.indices);
        }

        this._buildHash();

        memoryStats.meshes++;

        this._buildVBOs();
    }

    _buildVBOs() {
        const state = this._state;
        const gl = this.scene.canvas.gl;
        if (state.indices) {
            state.indicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, state.indices, state.indices.length, 1, gl.STATIC_DRAW);
            memoryStats.indices += state.indicesBuf.numItems;
        }
        if (state.positions) {
            state.positionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, state.positions, state.positions.length, 3, gl.STATIC_DRAW);
            memoryStats.positions += state.positionsBuf.numItems;
        }
        if (state.normals) {
            let normalized = state.compressGeometry;
            state.normalsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, state.normals, state.normals.length, 3, gl.STATIC_DRAW, normalized);
            memoryStats.normals += state.normalsBuf.numItems;
        }
        if (state.colors) {
            state.colorsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, state.colors, state.colors.length, 4, gl.STATIC_DRAW);
            memoryStats.colors += state.colorsBuf.numItems;
        }
        if (state.uv) {
            state.uvBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, state.uv, state.uv.length, 2, gl.STATIC_DRAW);
            memoryStats.uvs += state.uvBuf.numItems;
        }
    }

    _buildHash() {
        const state = this._state;
        const hash = ["/g"];
        hash.push("/" + state.primitive + ";");
        if (state.positions) {
            hash.push("p");
        }
        if (state.colors) {
            hash.push("c");
        }
        if (state.normals || state.autoVertexNormals) {
            hash.push("n");
        }
        if (state.uv) {
            hash.push("u");
        }
        if (state.compressGeometry) {
            hash.push("cp");
        }
        hash.push(";");
        state.hash = hash.join("");
    }

    _getEdgeIndices() {
        if (!this._edgeIndicesBuf) {
            this._buildEdgeIndices();
        }
        return this._edgeIndicesBuf;
    }

    _getPickTrianglePositions() {
        if (!this._pickTrianglePositionsBuf) {
            this._buildPickTriangleVBOs();
        }
        return this._pickTrianglePositionsBuf;
    }

    _getPickTriangleColors() {
        if (!this._pickTriangleColorsBuf) {
            this._buildPickTriangleVBOs();
        }
        return this._pickTriangleColorsBuf;
    }

    _buildEdgeIndices() { // FIXME: Does not adjust indices after other objects are deleted from vertex buffer!!
        const state = this._state;
        if (!state.positions || !state.indices) {
            return;
        }
        const gl = this.scene.canvas.gl;
        const edgeIndices = buildEdgeIndices(state.positions, state.indices, state.positionsDecodeMatrix, this._edgeThreshold);
        this._edgeIndicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, edgeIndices, edgeIndices.length, 1, gl.STATIC_DRAW);
        memoryStats.indices += this._edgeIndicesBuf.numItems;
    }

    _buildPickTriangleVBOs() { // Builds positions and indices arrays that allow each triangle to have a unique color
        const state = this._state;
        if (!state.positions || !state.indices) {
            return;
        }
        const gl = this.scene.canvas.gl;
        const arrays = math.buildPickTriangles(state.positions, state.indices, state.compressGeometry);
        const positions = arrays.positions;
        const colors = arrays.colors;
        this._pickTrianglePositionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, positions, positions.length, 3, gl.STATIC_DRAW);
        this._pickTriangleColorsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, colors, colors.length, 4, gl.STATIC_DRAW, true);
        memoryStats.positions += this._pickTrianglePositionsBuf.numItems;
        memoryStats.colors += this._pickTriangleColorsBuf.numItems;
    }

    _buildPickVertexVBOs() {
        // var state = this._state;
        // if (!state.positions || !state.indices) {
        //     return;
        // }
        // var gl = this.scene.canvas.gl;
        // var arrays = math.buildPickVertices(state.positions, state.indices, state.compressGeometry);
        // var pickVertexPositions = arrays.positions;
        // var pickColors = arrays.colors;
        // this._pickVertexPositionsBuf = new xeokit.renderer.ArrayBuf(gl, gl.ARRAY_BUFFER, pickVertexPositions, pickVertexPositions.length, 3, gl.STATIC_DRAW);
        // this._pickVertexColorsBuf = new xeokit.renderer.ArrayBuf(gl, gl.ARRAY_BUFFER, pickColors, pickColors.length, 4, gl.STATIC_DRAW, true);
        // memoryStats.positions += this._pickVertexPositionsBuf.numItems;
        // memoryStats.colors += this._pickVertexColorsBuf.numItems;
    }

    _webglContextLost() {
        if (this._sceneVertexBufs) {
            this._sceneVertexBufs.webglContextLost();
        }
    }

    _webglContextRestored() {
        if (this._sceneVertexBufs) {
            this._sceneVertexBufs.webglContextRestored();
        }
        this._buildVBOs();
        this._edgeIndicesBuf = null;
        this._pickVertexPositionsBuf = null;
        this._pickTrianglePositionsBuf = null;
        this._pickTriangleColorsBuf = null;
        this._pickVertexPositionsBuf = null;
        this._pickVertexColorsBuf = null;
    }

    /**
     * Gets the Geometry's primitive type.

     Valid types are: 'points', 'lines', 'line-loop', 'line-strip', 'triangles', 'triangle-strip' and 'triangle-fan'.

     @property primitive
     @default "triangles"
     @type {String}
     */
    get primitive() {
        return this._state.primitiveName;
    }

    /**
     Indicates if this Geometry is quantized.

     Compression is an internally-performed optimization which stores positions, colors, normals and UVs
     in quantized and oct-encoded formats for reduced memory footprint and GPU bus usage.

     Quantized geometry may not be updated.

     @property compressGeometry
     @default false
     @type {Boolean}
     @final
     */
    get compressGeometry() {
        return this._state.compressGeometry;
    }

    /**
     The Geometry's vertex positions.

     @property positions
     @default null
     @type {Number[]}
     */
    get positions() {
        if (!this._state.positions) {
            return null;
        }
        if (!this._state.compressGeometry) {
            return this._state.positions;
        }
        if (!this._decompressedPositions) {
            this._decompressedPositions = new Float32Array(this._state.positions.length);
            geometryCompressionUtils.decompressPositions(this._state.positions, this._state.positionsDecodeMatrix, this._decompressedPositions);
        }
        return this._decompressedPositions;
    }

    set positions(newPositions) {
        const state = this._state;
        const positions = state.positions;
        if (!positions) {
            this.error("can't update geometry positions - geometry has no positions");
            return;
        }
        if (positions.length !== newPositions.length) {
            this.error("can't update geometry positions - new positions are wrong length");
            return;
        }
        if (this._state.compressGeometry) {
            const bounds = geometryCompressionUtils.getPositionsBounds(newPositions);
            const result = geometryCompressionUtils.compressPositions(newPositions, bounds.min, bounds.max);
            newPositions = result.quantized; // TODO: Copy in-place
            state.positionsDecodeMatrix = result.decodeMatrix;
        }
        positions.set(newPositions);
        if (state.positionsBuf) {
            state.positionsBuf.setData(positions);
        }
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     The Geometry's vertex normals.

     @property normals
     @default null
     @type {Number[]}
     */
    get normals() {
        if (!this._state.normals) {
            return;
        }
        if (!this._state.compressGeometry) {
            return this._state.normals;
        }
        if (!this._decompressedNormals) {
            const lenCompressed = this._state.normals.length;
            const lenDecompressed = lenCompressed + (lenCompressed / 2); // 2 -> 3
            this._decompressedNormals = new Float32Array(lenDecompressed);
            geometryCompressionUtils.decompressNormals(this._state.normals, this._decompressedNormals);
        }
        return this._decompressedNormals;
    }

    set normals(newNormals) {
        if (this._state.compressGeometry) {
            this.error("can't update geometry normals - quantized geometry is immutable"); // But will be eventually
            return;
        }
        const state = this._state;
        const normals = state.normals;
        if (!normals) {
            this.error("can't update geometry normals - geometry has no normals");
            return;
        }
        if (normals.length !== newNormals.length) {
            this.error("can't update geometry normals - new normals are wrong length");
            return;
        }
        normals.set(newNormals);
        if (state.normalsBuf) {
            state.normalsBuf.setData(normals);
        }
        this.glRedraw();
    }


    /**
     The Geometry's UV coordinates.

     @property uv
     @default null
     @type {Number[]}
     */
    get uv() {
        if (!this._state.uv) {
            return null;
        }
        if (!this._state.compressGeometry) {
            return this._state.uv;
        }
        if (!this._decompressedUV) {
            this._decompressedUV = new Float32Array(this._state.uv.length);
            geometryCompressionUtils.decompressUVs(this._state.uv, this._state.uvDecodeMatrix, this._decompressedUV);
        }
        return this._decompressedUV;
    }

    set uv(newUV) {
        if (this._state.compressGeometry) {
            this.error("can't update geometry UVs - quantized geometry is immutable"); // But will be eventually
            return;
        }
        const state = this._state;
        const uv = state.uv;
        if (!uv) {
            this.error("can't update geometry UVs - geometry has no UVs");
            return;
        }
        if (uv.length !== newUV.length) {
            this.error("can't update geometry UVs - new UVs are wrong length");
            return;
        }
        uv.set(newUV);
        if (state.uvBuf) {
            state.uvBuf.setData(uv);
        }
        this.glRedraw();
    }

    /**
     The Geometry's vertex colors.

     @property colors
     @default null
     @type {Number[]}
     */
    get colors() {
        return this._state.colors;
    }

    set colors(newColors) {
        if (this._state.compressGeometry) {
            this.error("can't update geometry colors - quantized geometry is immutable"); // But will be eventually
            return;
        }
        const state = this._state;
        const colors = state.colors;
        if (!colors) {
            this.error("can't update geometry colors - geometry has no colors");
            return;
        }
        if (colors.length !== newColors.length) {
            this.error("can't update geometry colors - new colors are wrong length");
            return;
        }
        colors.set(newColors);
        if (state.colorsBuf) {
            state.colorsBuf.setData(colors);
        }
        this.glRedraw();
    }

    /**
     The Geometry's indices.

     If ````xeokit.WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"]```` is true, then this can be
     a ````Uint32Array````, otherwise it needs to be a ````Uint16Array````.

     @property indices
     @default null
     @type Uint16Array | Uint32Array
     @final
     */
    get indices() {
        return this._state.indices;
    }

    /**
     * Local-space axis-aligned 3D boundary (AABB) of this geometry.
     *
     * The AABB is represented by a six-element Float32Array containing the min/max extents of the
     * axis-aligned volume, ie. ````[xmin, ymin,zmin,xmax,ymax, zmax]````.
     *
     * @property aabb
     * @final
     * @type {Number[]}
     */
    get aabb() {
        if (this._aabbDirty) {
            if (!this._aabb) {
                this._aabb = math.AABB3();
            }
            math.positions3ToAABB3(this._state.positions, this._aabb, this._state.positionsDecodeMatrix);
            this._aabbDirty = false;
        }
        return this._aabb;
    }

    /**
     * Local-space oriented 3D boundary (OBB) of this geometry.
     *
     * The OBB is represented by a 32-element Float32Array containing the eight vertices of the box,
     * where each vertex is a homogeneous coordinate having [x,y,z,w] elements.
     *
     * @property obb
     * @final
     * @type {Number[]}
     */
    get obb() {
        if (this._obbDirty) {
            if (!this._obb) {
                this._obb = math.OBB3();
            }
            math.positions3ToAABB3(this._state.positions, tempAABB, this._state.positionsDecodeMatrix);
            math.AABB3ToOBB3(tempAABB, this._obb);
            this._obbDirty = false;
        }
        return this._obb;
    }

    _setAABBDirty() {
        if (this._aabbDirty) {
            return;
        }
        this._aabbDirty = true;
        this._aabbDirty = true;
        this._obbDirty = true;
    }

    _getState() {
        return this._state;
    }

    /**
     * Destroys this ReadableGeometry
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
        if (this._pickTrianglePositionsBuf) {
            this._pickTrianglePositionsBuf.destroy();
        }
        if (this._pickTriangleColorsBuf) {
            this._pickTriangleColorsBuf.destroy();
        }
        if (this._pickVertexPositionsBuf) {
            this._pickVertexPositionsBuf.destroy();
        }
        if (this._pickVertexColorsBuf) {
            this._pickVertexColorsBuf.destroy();
        }
        state.destroy();
        memoryStats.meshes--;
    }
}


export {ReadableGeometry};