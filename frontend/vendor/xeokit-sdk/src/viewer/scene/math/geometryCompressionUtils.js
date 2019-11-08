/**
 * Private geometry compression and decompression utilities.
 */

import {math} from "./math.js";

/**
 * @private
 * @param array
 * @returns {{min: Float32Array, max: Float32Array}}
 */
function getPositionsBounds(array) {
    const min = new Float32Array(3);
    const max = new Float32Array(3);
    let i, j;
    for (i = 0; i < 3; i++) {
        min[i] = Number.MAX_VALUE;
        max[i] = -Number.MAX_VALUE;
    }
    for (i = 0; i < array.length; i += 3) {
        for (j = 0; j < 3; j++) {
            min[j] = Math.min(min[j], array[i + j]);
            max[j] = Math.max(max[j], array[i + j]);
        }
    }
    return {
        min: min,
        max: max
    };
}


/**
 * @private
 */
var compressPositions = (function () { // http://cg.postech.ac.kr/research/mesh_comp_mobile/mesh_comp_mobile_conference.pdf
    const translate = math.mat4();
    const scale = math.mat4();
    return function (array, min, max) {
        const quantized = new Uint16Array(array.length);
        var multiplier = new Float32Array([
            max[0] !== min[0] ? 65535 / (max[0] - min[0]) : 0,
            max[1] !== min[1] ? 65535 / (max[1] - min[1]) : 0,
            max[2] !== min[2] ? 65535 / (max[2] - min[2]) : 0
        ]);
        let i;
        for (i = 0; i < array.length; i += 3) {
            quantized[i + 0] = Math.floor((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Math.floor((array[i + 1] - min[1]) * multiplier[1]);
            quantized[i + 2] = Math.floor((array[i + 2] - min[2]) * multiplier[2]);
        }
        math.identityMat4(translate);
        math.translationMat4v(min, translate);
        math.identityMat4(scale);
        math.scalingMat4v([
            (max[0] - min[0]) / 65535,
            (max[1] - min[1]) / 65535,
            (max[2] - min[2]) / 65535
        ], scale);
        const decodeMat = math.mulMat4(translate, scale, math.identityMat4());
        return {
            quantized: quantized,
            decodeMatrix: decodeMat
        };
    };
})();

function decompressPosition(position, decodeMatrix, dest) {
    dest[0] = position[0] * decodeMatrix[0] + decodeMatrix[12];
    dest[1] = position[1] * decodeMatrix[5] + decodeMatrix[13];
    dest[2] = position[2] * decodeMatrix[10] + decodeMatrix[14];
    return dest;
}

function decompressAABB(aabb, decodeMatrix, dest=aabb) {
    dest[0] = aabb[0] * decodeMatrix[0] + decodeMatrix[12];
    dest[1] = aabb[1] * decodeMatrix[5] + decodeMatrix[13];
    dest[2] = aabb[2] * decodeMatrix[10] + decodeMatrix[14];
    dest[3] = aabb[3] * decodeMatrix[0] + decodeMatrix[12];
    dest[4] = aabb[4] * decodeMatrix[5] + decodeMatrix[13];
    dest[5] = aabb[5] * decodeMatrix[10] + decodeMatrix[14];
    return dest;
}

/**
 * @private
 */
function decompressPositions(positions, decodeMatrix, dest = new Float32Array(positions.length)) {
    for (let i = 0, len = positions.length; i < len; i += 3) {
        dest[i + 0] = positions[i + 0] * decodeMatrix[0] + decodeMatrix[12];
        dest[i + 1] = positions[i + 1] * decodeMatrix[5] + decodeMatrix[13];
        dest[i + 2] = positions[i + 2] * decodeMatrix[10] + decodeMatrix[14];
    }
    return dest;
}

//--------------- UVs --------------------------------------------------------------------------------------------------

/**
 * @private
 * @param array
 * @returns {{min: Float32Array, max: Float32Array}}
 */
function getUVBounds(array) {
    const min = new Float32Array(2);
    const max = new Float32Array(2);
    let i, j;
    for (i = 0; i < 2; i++) {
        min[i] = Number.MAX_VALUE;
        max[i] = -Number.MAX_VALUE;
    }
    for (i = 0; i < array.length; i += 2) {
        for (j = 0; j < 2; j++) {
            min[j] = Math.min(min[j], array[i + j]);
            max[j] = Math.max(max[j], array[i + j]);
        }
    }
    return {
        min: min,
        max: max
    };
}

/**
 * @private
 */
var compressUVs = (function () {
    const translate = math.mat3();
    const scale = math.mat3();
    return function (array, min, max) {
        const quantized = new Uint16Array(array.length);
        const multiplier = new Float32Array([
            65535 / (max[0] - min[0]),
            65535 / (max[1] - min[1])
        ]);
        let i;
        for (i = 0; i < array.length; i += 2) {
            quantized[i + 0] = Math.floor((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Math.floor((array[i + 1] - min[1]) * multiplier[1]);
        }
        math.identityMat3(translate);
        math.translationMat3v(min, translate);
        math.identityMat3(scale);
        math.scalingMat3v([
            (max[0] - min[0]) / 65535,
            (max[1] - min[1]) / 65535
        ], scale);
        const decodeMat = math.mulMat3(translate, scale, math.identityMat3());
        return {
            quantized: quantized,
            decodeMatrix: decodeMat
        };
    };
})();


//--------------- Normals ----------------------------------------------------------------------------------------------

/**
 * @private
 */
function compressNormals(array) { // http://jcgt.org/published/0003/02/01/

    // Note: three elements for each encoded normal, in which the last element in each triplet is redundant.
    // This is to work around a mysterious WebGL issue where 2-element normals just wouldn't work in the shader :/

    const encoded = new Int8Array(array.length);
    let oct, dec, best, currentCos, bestCos;
    for (let i = 0; i < array.length; i += 3) {
        // Test various combinations of ceil and floor
        // to minimize rounding errors
        best = oct = octEncodeVec3(array, i, "floor", "floor");
        dec = octDecodeVec2(oct);
        currentCos = bestCos = dot(array, i, dec);
        oct = octEncodeVec3(array, i, "ceil", "floor");
        dec = octDecodeVec2(oct);
        currentCos = dot(array, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        oct = octEncodeVec3(array, i, "floor", "ceil");
        dec = octDecodeVec2(oct);
        currentCos = dot(array, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        oct = octEncodeVec3(array, i, "ceil", "ceil");
        dec = octDecodeVec2(oct);
        currentCos = dot(array, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        encoded[i] = best[0];
        encoded[i + 1] = best[1];
    }
    return encoded;
}

/**
 * @private
 */
function octEncodeVec3(array, i, xfunc, yfunc) { // Oct-encode single normal vector in 2 bytes
    let x = array[i] / (Math.abs(array[i]) + Math.abs(array[i + 1]) + Math.abs(array[i + 2]));
    let y = array[i + 1] / (Math.abs(array[i]) + Math.abs(array[i + 1]) + Math.abs(array[i + 2]));
    if (array[i + 2] < 0) {
        let tempx = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
        let tempy = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
        x = tempx;
        y = tempy;
    }
    return new Int8Array([
        Math[xfunc](x * 127.5 + (x < 0 ? -1 : 0)),
        Math[yfunc](y * 127.5 + (y < 0 ? -1 : 0))
    ]);
}

/**
 * Decode an oct-encoded normal
 */
function octDecodeVec2(oct) {
    let x = oct[0];
    let y = oct[1];
    x /= x < 0 ? 127 : 128;
    y /= y < 0 ? 127 : 128;
    const z = 1 - Math.abs(x) - Math.abs(y);
    if (z < 0) {
        x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
        y = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
    }
    const length = Math.sqrt(x * x + y * y + z * z);
    return [
        x / length,
        y / length,
        z / length
    ];
}

/**
 * Dot product of a normal in an array against a candidate decoding
 * @private
 */
function dot(array, i, vec3) {
    return array[i] * vec3[0] + array[i + 1] * vec3[1] + array[i + 2] * vec3[2];
}

/**
 * @private
 */
function decompressUV(uv, decodeMatrix, dest) {
    dest[0] = uv[0] * decodeMatrix[0] + decodeMatrix[6];
    dest[1] = uv[1] * decodeMatrix[4] + decodeMatrix[7];
}

/**
 * @private
 */
function decompressUVs(uvs, decodeMatrix, dest = new Float32Array(uvs.length)) {
    for (let i = 0, len = uvs.length; i < len; i += 3) {
        dest[i + 0] = uvs[i + 0] * decodeMatrix[0] + decodeMatrix[6];
        dest[i + 1] = uvs[i + 1] * decodeMatrix[4] + decodeMatrix[7];
    }
    return dest;
}

/**
 * @private
 */
function decompressNormal(oct, result) {
    let x = oct[0];
    let y = oct[1];
    x = (2 * x + 1) / 255;
    y = (2 * y + 1) / 255;
    const z = 1 - Math.abs(x) - Math.abs(y);
    if (z < 0) {
        x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
        y = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
    }
    const length = Math.sqrt(x * x + y * y + z * z);
    result[0] = x / length;
    result[1] = y / length;
    result[2] = z / length;
    return result;
}

/**
 * @private
 */
function decompressNormals(octs, result) {
    for (let i = 0, j = 0, len = octs.length; i < len; i += 2) {
        let x = octs[i + 0];
        let y = octs[i + 1];
        x = (2 * x + 1) / 255;
        y = (2 * y + 1) / 255;
        const z = 1 - Math.abs(x) - Math.abs(y);
        if (z < 0) {
            x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
            y = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
        }
        const length = Math.sqrt(x * x + y * y + z * z);
        result[j + 0] = x / length;
        result[j + 1] = y / length;
        result[j + 2] = z / length;
        j += 3;
    }
    return result;
}

/**
 * @private
 */
const geometryCompressionUtils = {

    getPositionsBounds: getPositionsBounds,
    compressPositions: compressPositions,
    decompressPositions: decompressPositions,
    decompressPosition: decompressPosition,
    decompressAABB: decompressAABB,

    getUVBounds: getUVBounds,
    compressUVs: compressUVs,
    decompressUVs: decompressUVs,
    decompressUV: decompressUV,

    compressNormals: compressNormals,
    decompressNormals: decompressNormals,
    decompressNormal: decompressNormal
};

export {geometryCompressionUtils};