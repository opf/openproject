import {WEBGL_INFO} from "../../../webglInfo.js";


const bigIndicesSupported = WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"];
const SLICING = true;
const MAX_VERTS = SLICING ? (bigIndicesSupported ? 5000000 : 65530) : 5000000;

/**
 * @private
 */
class BatchingBuffer {
    constructor() {
        this.slicing = SLICING;
        this.maxVerts = MAX_VERTS;

        this.positions = new Float32Array(MAX_VERTS * 3); // Uncompressed
        this.colors = new Uint8Array(MAX_VERTS * 4); // Compressed
        this.quantizedPositions = new Uint16Array(MAX_VERTS * 3); // Compressed
        this.normals = new Int8Array(MAX_VERTS * 3); // Compressed
        this.pickColors = new Uint8Array(MAX_VERTS * 4); // Compressed
        this.flags = new Uint8Array(MAX_VERTS * 4);
        this.flags2 = new Uint8Array(MAX_VERTS * 4);
        this.indices = bigIndicesSupported ? new Uint32Array(MAX_VERTS * 6) : new Uint16Array(MAX_VERTS * 6); // FIXME
        this.edgeIndices = bigIndicesSupported ? new Uint32Array(MAX_VERTS * 6) : new Uint16Array(MAX_VERTS * 6); // FIXME

        this.lenPositions = 0;
        this.lenColors = 0;
        this.lenNormals = 0;
        this.lenPickColors = 0;
        this.lenFlags = 0;
        this.lenIndices = 0;
        this.lenEdgeIndices = 0;
    }
}

const freeBuffers = [];

/**
 * @private
 */
function getBatchingBuffer() {
    return freeBuffers.length > 0 ? freeBuffers.pop() : new BatchingBuffer();
}

/**
 * @private
 */
function putBatchingBuffer(buffer) {
    freeBuffers.push(buffer);
}

export {getBatchingBuffer, putBatchingBuffer};