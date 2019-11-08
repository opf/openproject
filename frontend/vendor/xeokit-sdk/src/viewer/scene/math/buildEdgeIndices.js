import {math} from './math.js';

/**
 * @private
 */
var buildEdgeIndices = (function () {

    const uniquePositions = [];
    const indicesLookup = [];
    const indicesReverseLookup = [];
    const weldedIndices = [];

// TODO: Optimize with caching, but need to cater to both compressed and uncompressed positions

    const faces = [];
    let numFaces = 0;
    const compa = new Uint16Array(3);
    const compb = new Uint16Array(3);
    const compc = new Uint16Array(3);
    const a = math.vec3();
    const b = math.vec3();
    const c = math.vec3();
    const cb = math.vec3();
    const ab = math.vec3();
    const cross = math.vec3();
    const normal = math.vec3();

    function weldVertices(positions, indices) {
        const positionsMap = {}; // Hashmap for looking up vertices by position coordinates (and making sure they are unique)
        let vx;
        let vy;
        let vz;
        let key;
        const precisionPoints = 4; // number of decimal points, e.g. 4 for epsilon of 0.0001
        const precision = Math.pow(10, precisionPoints);
        let i;
        let len;
        let lenUniquePositions = 0;
        for (i = 0, len = positions.length; i < len; i += 3) {
            vx = positions[i];
            vy = positions[i + 1];
            vz = positions[i + 2];
            key = Math.round(vx * precision) + '_' + Math.round(vy * precision) + '_' + Math.round(vz * precision);
            if (positionsMap[key] === undefined) {
                positionsMap[key] = lenUniquePositions / 3;
                uniquePositions[lenUniquePositions++] = vx;
                uniquePositions[lenUniquePositions++] = vy;
                uniquePositions[lenUniquePositions++] = vz;
            }
            indicesLookup[i / 3] = positionsMap[key];
        }
        for (i = 0, len = indices.length; i < len; i++) {
            weldedIndices[i] = indicesLookup[indices[i]];
            indicesReverseLookup[weldedIndices[i]] = indices[i];
        }
    }

    function buildFaces(numIndices, positionsDecodeMatrix) {
        numFaces = 0;
        for (let i = 0, len = numIndices; i < len; i += 3) {
            const ia = ((weldedIndices[i]) * 3);
            const ib = ((weldedIndices[i + 1]) * 3);
            const ic = ((weldedIndices[i + 2]) * 3);
            if (positionsDecodeMatrix) {
                compa[0] = uniquePositions[ia];
                compa[1] = uniquePositions[ia + 1];
                compa[2] = uniquePositions[ia + 2];
                compb[0] = uniquePositions[ib];
                compb[1] = uniquePositions[ib + 1];
                compb[2] = uniquePositions[ib + 2];
                compc[0] = uniquePositions[ic];
                compc[1] = uniquePositions[ic + 1];
                compc[2] = uniquePositions[ic + 2];
                // Decode
                math.decompressPosition(compa, positionsDecodeMatrix, a);
                math.decompressPosition(compb, positionsDecodeMatrix, b);
                math.decompressPosition(compc, positionsDecodeMatrix, c);
            } else {
                a[0] = uniquePositions[ia];
                a[1] = uniquePositions[ia + 1];
                a[2] = uniquePositions[ia + 2];
                b[0] = uniquePositions[ib];
                b[1] = uniquePositions[ib + 1];
                b[2] = uniquePositions[ib + 2];
                c[0] = uniquePositions[ic];
                c[1] = uniquePositions[ic + 1];
                c[2] = uniquePositions[ic + 2];
            }
            math.subVec3(c, b, cb);
            math.subVec3(a, b, ab);
            math.cross3Vec3(cb, ab, cross);
            math.normalizeVec3(cross, normal);
            const face = faces[numFaces] || (faces[numFaces] = {normal: math.vec3()});
            face.normal[0] = normal[0];
            face.normal[1] = normal[1];
            face.normal[2] = normal[2];
            numFaces++;
        }
    }

    return function (positions, indices, positionsDecodeMatrix, edgeThreshold) {
        weldVertices(positions, indices);
        buildFaces(indices.length, positionsDecodeMatrix);
        const edgeIndices = [];
        const thresholdDot = Math.cos(math.DEGTORAD * edgeThreshold);
        const edges = {};
        let edge1;
        let edge2;
        let index1;
        let index2;
        let key;
        let largeIndex = false;
        let edge;
        let normal1;
        let normal2;
        let dot;
        let ia;
        let ib;
        for (let i = 0, len = indices.length; i < len; i += 3) {
            const faceIndex = i / 3;
            for (let j = 0; j < 3; j++) {
                edge1 = weldedIndices[i + j];
                edge2 = weldedIndices[i + ((j + 1) % 3)];
                index1 = Math.min(edge1, edge2);
                index2 = Math.max(edge1, edge2);
                key = index1 + "," + index2;
                if (edges[key] === undefined) {
                    edges[key] = {
                        index1: index1,
                        index2: index2,
                        face1: faceIndex,
                        face2: undefined
                    };
                } else {
                    edges[key].face2 = faceIndex;
                }
            }
        }
        for (key in edges) {
            edge = edges[key];
            // an edge is only rendered if the angle (in degrees) between the face normals of the adjoining faces exceeds this value. default = 1 degree.
            if (edge.face2 !== undefined) {
                normal1 = faces[edge.face1].normal;
                normal2 = faces[edge.face2].normal;
                dot = math.dotVec3(normal1, normal2);
                if (dot > thresholdDot) {
                    continue;
                }
            }
            ia = indicesReverseLookup[edge.index1];
            ib = indicesReverseLookup[edge.index2];
            if (!largeIndex && ia > 65535 || ib > 65535) {
                largeIndex = true;
            }
            edgeIndices.push(ia);
            edgeIndices.push(ib);
        }
        return (largeIndex) ? new Uint32Array(edgeIndices) : new Uint16Array(edgeIndices);
    };
})();

export {buildEdgeIndices};