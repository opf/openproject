import {math} from "../../../math/math.js";
import {buildEdgeIndices} from '../../../math/buildEdgeIndices.js';
import {WEBGL_INFO} from "../../../webglInfo.js";

import {RenderState} from "../../../webgl/RenderState.js";
import {ArrayBuf} from "../../../webgl/ArrayBuf.js";

import {InstancingDrawRenderer} from "./instancingDrawRenderer.js";
import {InstancingFillRenderer} from "./instancingFillRenderer.js";
import {InstancingEdgesRenderer} from "./instancingEdgesRenderer.js";
import {InstancingPickMeshRenderer} from "./instancingPickMeshRenderer.js";
import {InstancingPickDepthRenderer} from "./instancingPickDepthRenderer.js";
import {InstancingPickNormalsRenderer} from "./instancingPickNormalsRenderer.js";
import {InstancingOcclusionRenderer} from "./instancingOcclusionRenderer.js";
import {geometryCompressionUtils} from "../../../math/geometryCompressionUtils.js";

import {RENDER_FLAGS} from '../renderFlags.js';
import {RENDER_PASSES} from '../renderPasses.js';

const bigIndicesSupported = WEBGL_INFO.SUPPORTED_EXTENSIONS["OES_element_index_uint"];
const MAX_VERTS = bigIndicesSupported ? 5000000 : 65530;
const quantizedPositions = new Uint16Array(MAX_VERTS * 3);
const compressedNormals = new Int8Array(MAX_VERTS * 3);
const tempUint8Vec4 = new Uint8Array(4);
const tempVec3a = math.vec4([0, 0, 0, 1]);
const tempVec3b = math.vec4([0, 0, 0, 1]);
const tempVec3c = math.vec4([0, 0, 0, 1]);

/**
 * @private
 */
class InstancingLayer {

    /**
     * @param model
     * @param cfg
     * @param cfg.primitive
     * @param cfg.positions Flat float Local-space positions array.
     * @param cfg.normals Flat float normals array.
     * @param cfg.indices Flat int indices array.
     * @param cfg.edgeIndices Flat int edges indices array.
     */
    constructor(model, cfg) {
        this.model = model;
        this._aabb = math.collapseAABB3();
        var primitiveName = cfg.primitive || "triangles";
        var primitive;
        const gl = model.scene.canvas.gl;
        switch (primitiveName) {
            case "points":
                primitive = gl.POINTS;
                break;
            case "lines":
                primitive = gl.LINES;
                break;
            case "line-loop":
                primitive = gl.LINE_LOOP;
                break;
            case "line-strip":
                primitive = gl.LINE_STRIP;
                break;
            case "triangles":
                primitive = gl.TRIANGLES;
                break;
            case "triangle-strip":
                primitive = gl.TRIANGLE_STRIP;
                break;
            case "triangle-fan":
                primitive = gl.TRIANGLE_FAN;
                break;
            default:
                throw `Unsupported value for 'primitive': '${primitiveName}' - supported values are 'points', 'lines', 'line-loop', 'line-strip', 'triangles', 'triangle-strip' and 'triangle-fan'. Defaulting to 'triangles'.`;
                primitive = gl.TRIANGLES;
                primitiveName = "triangles";
        }
        var stateCfg = {
            primitiveName: primitiveName,
            primitive: primitive,
            positionsDecodeMatrix: math.mat4(),
            numInstances: 0,
            obb: math.OBB3()
        };
        if (cfg.positions) {

            if (cfg.preCompressed) {

                let normalized = false;
                stateCfg.positionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, cfg.positions, cfg.positions.length, 3, gl.STATIC_DRAW, normalized);
                stateCfg.positionsDecodeMatrix.set(cfg.positionsDecodeMatrix);

                let localAABB = math.collapseAABB3();
                math.expandAABB3Points3(localAABB, cfg.positions);
                geometryCompressionUtils.decompressAABB(localAABB, stateCfg.positionsDecodeMatrix);
                math.AABB3ToOBB3(localAABB, stateCfg.obb);

            } else {

                let lenPositions = cfg.positions.length;
                let localAABB = math.collapseAABB3();
                math.expandAABB3Points3(localAABB, cfg.positions);
                math.AABB3ToOBB3(localAABB, stateCfg.obb);
                quantizePositions(cfg.positions, lenPositions, localAABB, quantizedPositions, stateCfg.positionsDecodeMatrix);
                let normalized = false;
                stateCfg.positionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, quantizedPositions, lenPositions, 3, gl.STATIC_DRAW, normalized);
            }
        }
        if (cfg.normals) {

            if (cfg.preCompressed) {

                let normalized = true; // For oct-encoded UInt8
                stateCfg.normalsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, cfg.normals, cfg.normals.length, 3, gl.STATIC_DRAW, normalized);

            } else {

                var lenCompressedNormals = octEncodeNormals(cfg.normals, cfg.normals.length, compressedNormals, 0);
                let normalized = true; // For oct-encoded UInt8
                stateCfg.normalsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, compressedNormals, lenCompressedNormals, 3, gl.STATIC_DRAW, normalized);
            }
        }

        if (cfg.indices) {
            stateCfg.indicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, bigIndicesSupported ? new Uint32Array(cfg.indices) : new Uint16Array(cfg.indices), cfg.indices.length, 1, gl.STATIC_DRAW);
        }

        var edgeIndices = cfg.edgeIndices;
        if (!edgeIndices) {
            edgeIndices = buildEdgeIndices(cfg.positions, cfg.indices, null, 10);
        }

        stateCfg.edgeIndicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, bigIndicesSupported ? new Uint32Array(edgeIndices) : new Uint16Array(edgeIndices), edgeIndices.length, 1, gl.STATIC_DRAW);

        this._state = new RenderState(stateCfg);

        // These counts are used to avoid unnecessary render passes
        this._numPortions = 0;
        this._numVisibleLayerPortions = 0;
        this._numTransparentLayerPortions = 0;
        this._numXRayedLayerPortions = 0;
        this._numHighlightedLayerPortions = 0;
        this._numSelectedLayerPortions = 0;
        this._numEdgesLayerPortions = 0;
        this._numPickableLayerPortions = 0;

        /** @private */
        this.numIndices = (cfg.indices) ? cfg.indices.length / 3 : 0;

        // Vertex arrays
        this._flags = [];
        this._flags2 = [];
        this._colors = [];
        this._pickColors = [];

        // Modeling matrix per instance, array for each column
        this._modelMatrixCol0 = [];
        this._modelMatrixCol1 = [];
        this._modelMatrixCol2 = [];

        // Modeling normal matrix per instance, array for each column
        this._modelNormalMatrixCol0 = [];
        this._modelNormalMatrixCol1 = [];
        this._modelNormalMatrixCol2 = [];

        this._portions = [];

        this._finalized = false;

        this._preCompressed = !!cfg.preCompressed;

        this.compileShaders();
    }

    /**
     * Creates a new portion within this InstancingLayer, returns the new portion ID.
     *
     * The portion will instance this InstancingLayer's geometry.
     *
     * Gives the portion the specified flags, color and matrix.
     *
     * @param flags Unsigned long int
     * @param rgbaInt Quantized RGBA color
     * @param opacity Opacity [0..255]
     * @param meshMatrix Flat float 4x4 matrix
     * @param [worldMatrix] Flat float 4x4 matrix
     * @param worldAABB Flat float AABB
     * @param pickColor Quantized pick color
     * @returns {number} Portion ID
     */
    createPortion(flags, rgbaInt, opacity, meshMatrix, worldMatrix, worldAABB, pickColor) {

        if (this._finalized) {
            throw "Already finalized";
        }

        // TODO: find AABB for portion by transforming the geometry local AABB by the given meshMatrix?

        var visible = !!(flags & RENDER_FLAGS.VISIBLE) ? 255 : 0;
        var xrayed = !!(flags & RENDER_FLAGS.XRAYED) ? 255 : 0;
        var highlighted = !!(flags & RENDER_FLAGS.HIGHLIGHTED) ? 255 : 0;
        var selected = !!(flags & RENDER_FLAGS.HIGHLIGHTED) ? 255 : 0;
        var clippable = !!(flags & RENDER_FLAGS.CLIPPABLE) ? 255 : 0;
        var edges = !!(flags & RENDER_FLAGS.EDGES) ? 255 : 0;
        var pickable = !!(flags & RENDER_FLAGS.PICKABLE) ? 255 : 0;

        this._flags.push(visible);
        this._flags.push(xrayed);
        this._flags.push(highlighted);
        this._flags.push(selected);

        this._flags2.push(clippable);
        this._flags2.push(edges);
        this._flags2.push(pickable);
        this._flags2.push(0); // Unused

        if (visible) {
            this._numVisibleLayerPortions++;
            this.model.numVisibleLayerPortions++;
        }
        if (xrayed) {
            this._numXRayedLayerPortions++;
            this.model.numXRayedLayerPortions++;
        }
        if (highlighted) {
            this._numHighlightedLayerPortions++;
            this.model.numHighlightedLayerPortions++;
        }
        if (selected) {
            this._numSelectedLayerPortions++;
            this.model.numSelectedLayerPortions++;
        }
        if (edges) {
            this._numEdgesLayerPortions++;
            this.model.numEdgesLayerPortions++;
        }
        if (pickable) {
            this._numPickableLayerPortions++;
            this.model.numPickableLayerPortions++;
        }

        const r = rgbaInt[0]; // Color is pre-quantized by PerformanceModel
        const g = rgbaInt[1];
        const b = rgbaInt[2];
        const a = rgbaInt[3];
        if (opacity < 255) {
            this._numTransparentLayerPortions++;
            this.model.numTransparentLayerPortions++;
        }
        this._colors.push(r);
        this._colors.push(g);
        this._colors.push(b);
        this._colors.push(opacity);

        this._modelMatrixCol0.push(meshMatrix[0]);
        this._modelMatrixCol0.push(meshMatrix[4]);
        this._modelMatrixCol0.push(meshMatrix[8]);
        this._modelMatrixCol0.push(meshMatrix[12]);

        this._modelMatrixCol1.push(meshMatrix[1]);
        this._modelMatrixCol1.push(meshMatrix[5]);
        this._modelMatrixCol1.push(meshMatrix[9]);
        this._modelMatrixCol1.push(meshMatrix[13]);

        this._modelMatrixCol2.push(meshMatrix[2]);
        this._modelMatrixCol2.push(meshMatrix[6]);
        this._modelMatrixCol2.push(meshMatrix[10]);
        this._modelMatrixCol2.push(meshMatrix[14]);

        // Note: order of inverse and transpose doesn't matter

        let transposedMat = math.transposeMat4(meshMatrix, math.mat4()); // TODO: Use cached matrix
        let normalMatrix = math.inverseMat4(transposedMat);

        this._modelNormalMatrixCol0.push(normalMatrix[0]);
        this._modelNormalMatrixCol0.push(normalMatrix[4]);
        this._modelNormalMatrixCol0.push(normalMatrix[8]);
        this._modelNormalMatrixCol0.push(normalMatrix[12]);

        this._modelNormalMatrixCol1.push(normalMatrix[1]);
        this._modelNormalMatrixCol1.push(normalMatrix[5]);
        this._modelNormalMatrixCol1.push(normalMatrix[9]);
        this._modelNormalMatrixCol1.push(normalMatrix[13]);

        this._modelNormalMatrixCol2.push(normalMatrix[2]);
        this._modelNormalMatrixCol2.push(normalMatrix[6]);
        this._modelNormalMatrixCol2.push(normalMatrix[10]);
        this._modelNormalMatrixCol2.push(normalMatrix[14]);

        // Per-vertex pick colors

        this._pickColors.push(pickColor[0]);
        this._pickColors.push(pickColor[1]);
        this._pickColors.push(pickColor[2]);
        this._pickColors.push(pickColor[3]);

        // Expand AABB

        math.collapseAABB3(worldAABB);
        var obb = this._state.obb;
        var lenPositions = obb.length;
        for (var i = 0; i < lenPositions; i += 4) {
            tempVec3a[0] = obb[i + 0];
            tempVec3a[1] = obb[i + 1];
            tempVec3a[2] = obb[i + 2];
            math.transformPoint4(meshMatrix, tempVec3a, tempVec3b);
            if (worldMatrix) {
                math.transformPoint4(worldMatrix, tempVec3b, tempVec3c);
                math.expandAABB3Point3(worldAABB, tempVec3c);
            } else {
                math.expandAABB3Point3(worldAABB, tempVec3b);
            }
        }

        this._state.numInstances++;

        var portionId = this._portions.length;
        this._portions.push({});

        this._numPortions++;
        this.model.numPortions++;

        return portionId;
    }

    finalize() {
        if (this._finalized) {
            throw "Already finalized";
        }
        const gl = this.model.scene.canvas.gl;
        if (this._colors.length > 0) {
            let normalized = false;
            this._state.colorsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Uint8Array(this._colors), this._colors.length, 4, gl.DYNAMIC_DRAW, normalized);
            this._colors = []; // Release memory
        }
        if (this._flags.length > 0) {
            let normalized = true;
            this._state.flagsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Uint8Array(this._flags), this._flags.length, 4, gl.DYNAMIC_DRAW, normalized);
            this._state.flags2Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Uint8Array(this._flags2), this._flags2.length, 4, gl.DYNAMIC_DRAW, normalized);
            this._flags = [];
            this._flags2 = [];
        }
        if (this._modelMatrixCol0.length > 0) {

            let normalized = false;

            this._state.modelMatrixCol0Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelMatrixCol0), this._modelMatrixCol0.length, 4, gl.STATIC_DRAW, normalized);
            this._state.modelMatrixCol1Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelMatrixCol1), this._modelMatrixCol1.length, 4, gl.STATIC_DRAW, normalized);
            this._state.modelMatrixCol2Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelMatrixCol2), this._modelMatrixCol2.length, 4, gl.STATIC_DRAW, normalized);
            this._modelMatrixCol0 = [];
            this._modelMatrixCol1 = [];
            this._modelMatrixCol2 = [];

            this._state.modelNormalMatrixCol0Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelNormalMatrixCol0), this._modelNormalMatrixCol0.length, 4, gl.STATIC_DRAW, normalized);
            this._state.modelNormalMatrixCol1Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelNormalMatrixCol1), this._modelNormalMatrixCol1.length, 4, gl.STATIC_DRAW, normalized);
            this._state.modelNormalMatrixCol2Buf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._modelNormalMatrixCol2), this._modelNormalMatrixCol2.length, 4, gl.STATIC_DRAW, normalized);
            this._modelNormalMatrixCol0 = [];
            this._modelNormalMatrixCol1 = [];
            this._modelNormalMatrixCol2 = [];
        }
        if (this._pickColors.length > 0) {
            let normalized = false;
            this._state.pickColorsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Uint8Array(this._pickColors), this._pickColors.length, 4, gl.STATIC_DRAW, normalized);
            this._pickColors = []; // Release memory
        }
        this._finalized = true;
    }

    // The following setters are called by PerformanceModelMesh, in turn called by PerformanceModelNode, only after the layer is finalized.
    // It's important that these are called after finalize() in order to maintain integrity of counts like _numVisibleLayerPortions etc.

    initFlags(portionId, flags) {
        if (flags & RENDER_FLAGS.VISIBLE) {
            this._numVisibleLayerPortions++;
            this.model.numVisibleLayerPortions++;
        }
        if (flags & RENDER_FLAGS.HIGHLIGHTED) {
            this._numHighlightedLayerPortions++;
            this.model.numHighlightedLayerPortions++;
        }
        if (flags & RENDER_FLAGS.XRAYED) {
            this._numXRayedLayerPortions++;
            this.model.numXRayedLayerPortions++;
        }
        if (flags & RENDER_FLAGS.SELECTED) {
            this._numSelectedLayerPortions++;
            this.model.numSelectedLayerPortions++;
        }
        if (flags & RENDER_FLAGS.EDGES) {
            this._numEdgesLayerPortions++;
            this.model.numEdgesLayerPortions++;
        }
        if (flags & RENDER_FLAGS.PICKABLE) {
            this._numPickableLayerPortions++;
            this.model.numPickableLayerPortions++;
        }
        this._setFlags(portionId, flags);
        this._setFlags2(portionId, flags);
    }

    setVisible(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.VISIBLE) {
            this._numVisibleLayerPortions++;
            this.model.numVisibleLayerPortions++;
        } else {
            this._numVisibleLayerPortions--;
            this.model.numVisibleLayerPortions--;
        }
        this._setFlags(portionId, flags);
    }

    setHighlighted(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.HIGHLIGHTED) {
            this._numHighlightedLayerPortions++;
            this.model.numHighlightedLayerPortions++;
        } else {
            this._numHighlightedLayerPortions--;
            this.model.numHighlightedLayerPortions--;
        }
        this._setFlags(portionId, flags);
    }

    setXRayed(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.XRAYED) {
            this._numXRayedLayerPortions++;
            this.model.numXRayedLayerPortions++;
        } else {
            this._numXRayedLayerPortions--;
            this.model.numXRayedLayerPortions--;
        }
        this._setFlags(portionId, flags);
    }

    setSelected(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.SELECTED) {
            this._numSelectedLayerPortions++;
            this.model.numSelectedLayerPortions++;
        } else {
            this._numSelectedLayerPortions--;
            this.model.numSelectedLayerPortions--;
        }
        this._setFlags(portionId, flags);
    }

    setEdges(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.EDGES) {
            this._numEdgesLayerPortions++;
            this.model.numEdgesLayerPortions++;
        } else {
            this._numEdgesLayerPortions--;
            this.model.numEdgesLayerPortions--;
        }
        this._setFlags2(portionId, flags);
    }

    setClippable(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        this._setFlags2(portionId, flags);
    }

    setCollidable(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
    }

    setPickable(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        if (flags & RENDER_FLAGS.PICKABLE) {
            this._numPickableLayerPortions++;
            this.model.numPickableLayerPortions++;
        } else {
            this._numPickableLayerPortions--;
            this.model.numPickableLayerPortions--;
        }
        this._setFlags2(portionId, flags);
    }

    setColor(portionId, color, setOpacity = false) { // RGBA color is normalized as ints
        if (!this._finalized) {
            throw "Not finalized";
        }
        tempUint8Vec4[0] = color[0];
        tempUint8Vec4[1] = color[1];
        tempUint8Vec4[2] = color[2];
        tempUint8Vec4[3] = color[3];
        if (setOpacity) {
            const opacity = color[3];
            if (opacity < 255) {
                this._numTransparentLayerPortions++;
                this.model.numTransparentLayerPortions++;
            } else {
                this._numTransparentLayerPortions--;
                this.model.numTransparentLayerPortions--;
            }
        }
        this._state.colorsBuf.setData(tempUint8Vec4, portionId * 4, 4);
    }

    // setMatrix(portionId, matrix) {
    //
    //     if (!this._finalized) {
    //         throw "Not finalized";
    //     }
    //
    //     var offset = portionId * 4;
    //
    //     tempFloat32Vec4[0] = matrix[0];
    //     tempFloat32Vec4[1] = matrix[4];
    //     tempFloat32Vec4[2] = matrix[8];
    //     tempFloat32Vec4[3] = matrix[12];
    //
    //     this._state.modelMatrixCol0Buf.setData(tempFloat32Vec4, offset, 4);
    //
    //     tempFloat32Vec4[0] = matrix[1];
    //     tempFloat32Vec4[1] = matrix[5];
    //     tempFloat32Vec4[2] = matrix[9];
    //     tempFloat32Vec4[3] = matrix[13];
    //
    //     this._state.modelMatrixCol1Buf.setData(tempFloat32Vec4, offset, 4);
    //
    //     tempFloat32Vec4[0] = matrix[2];
    //     tempFloat32Vec4[1] = matrix[6];
    //     tempFloat32Vec4[2] = matrix[10];
    //     tempFloat32Vec4[3] = matrix[14];
    //
    //     this._state.modelMatrixCol2Buf.setData(tempFloat32Vec4, offset, 4);
    // }

    _setFlags(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        var visible = !!(flags & RENDER_FLAGS.VISIBLE) ? 255 : 0;
        var xrayed = !!(flags & RENDER_FLAGS.XRAYED) ? 255 : 0;
        var highlighted = !!(flags & RENDER_FLAGS.HIGHLIGHTED) ? 255 : 0;
        var selected = !!(flags & RENDER_FLAGS.SELECTED) ? 255 : 0; // TODO
        tempUint8Vec4[0] = visible;
        tempUint8Vec4[1] = xrayed;
        tempUint8Vec4[2] = highlighted;
        tempUint8Vec4[3] = selected;
        this._state.flagsBuf.setData(tempUint8Vec4, portionId * 4, 4);
    }

    _setFlags2(portionId, flags) {
        if (!this._finalized) {
            throw "Not finalized";
        }
        var clippable = !!(flags & RENDER_FLAGS.CLIPPABLE) ? 255 : 0;
        var edges = !!(flags & RENDER_FLAGS.EDGES) ? 255 : 0;
        var pickable = !!(flags & RENDER_FLAGS.PICKABLE) ? 255 : 0;
        tempUint8Vec4[0] = clippable;
        tempUint8Vec4[1] = edges;
        tempUint8Vec4[2] = pickable;
        this._state.flags2Buf.setData(tempUint8Vec4, portionId * 4, 4);
    }

    //-- NORMAL --------------------------------------------------------------------------------------------------------

    drawNormalFillOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numTransparentLayerPortions === this._numPortions || this._numXRayedLayerPortions === this._numPortions) {
            return;
        }
        if (this._drawRenderer) {
            this._drawRenderer.drawLayer(frameCtx, this, RENDER_PASSES.NORMAL_OPAQUE);
        }
    }

    drawNormalEdgesOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numEdgesLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.NORMAL_OPAQUE);
        }
    }

    drawNormalFillTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numTransparentLayerPortions === 0 || this._numXRayedLayerPortions === this._numPortions) {
            return;
        }
        if (this._drawRenderer) {
            this._drawRenderer.drawLayer(frameCtx, this, RENDER_PASSES.NORMAL_TRANSPARENT);
        }
    }

    drawNormalTransparentEdges(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numEdgesLayerPortions === 0 || this._numTransparentLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.NORMAL_TRANSPARENT);
        }
    }

    //-- XRAYED--------------------------------------------------------------------------------------------------------

    drawXRayedFillOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numXRayedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.XRAYED); // TODO: pass in transparent flag
        }
    }

    drawXRayedEdgesOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numXRayedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.XRAYED);
        }
    }

    drawXRayedFillTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numXRayedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.XRAYED); // TODO: pass in transparent flag
        }
    }

    drawXRayedEdgesTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numXRayedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.XRAYED);
        }
    }

    //-- HIGHLIGHTED ---------------------------------------------------------------------------------------------------

    drawHighlightedFillOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numHighlightedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.HIGHLIGHTED);
        }
    }

    drawHighlightedEdgesOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numHighlightedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.HIGHLIGHTED);
        }
    }

    drawHighlightedFillTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numHighlightedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.HIGHLIGHTED);
        }
    }

    drawHighlightedEdgesTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numHighlightedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.HIGHLIGHTED);
        }
    }

    //-- SELECTED ------------------------------------------------------------------------------------------------------

    drawSelectedFillOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numSelectedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.SELECTED);
        }
    }

    drawSelectedEdgesOpaque(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numSelectedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.SELECTED);
        }
    }

    drawSelectedFillTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numSelectedLayerPortions === 0) {
            return;
        }
        if (this._fillRenderer) {
            this._fillRenderer.drawLayer(frameCtx, this, RENDER_PASSES.SELECTED);
        }
    }

    drawSelectedEdgesTransparent(frameCtx) {
        if (this._numVisibleLayerPortions === 0 || this._numSelectedLayerPortions === 0) {
            return;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.drawLayer(frameCtx, this, RENDER_PASSES.SELECTED);
        }
    }

    //---- PICKING ----------------------------------------------------------------------------------------------------

    drawPickMesh(frameCtx) {
        if (this._numVisibleLayerPortions === 0) {
            return;
        }
        if (this._pickMeshRenderer) {
            this._pickMeshRenderer.drawLayer(frameCtx, this);
        }
    }

    drawPickDepths(frameCtx) {
        if (this._numVisibleLayerPortions === 0) {
            return;
        }
        if (this._pickDepthRenderer) {
            this._pickDepthRenderer.drawLayer(frameCtx, this);
        }
    }

    drawPickNormals(frameCtx) {
        if (this._numVisibleLayerPortions === 0) {
            return;
        }
        if (this._pickNormalsRenderer) {
            this._pickNormalsRenderer.drawLayer(frameCtx, this);
        }
    }

    //---- OCCLUSION TESTING -------------------------------------------------------------------------------------------

    drawOcclusion(frameCtx) {
        if (this._numVisibleLayerPortions === 0) {
            return;
        }
        if (!this._occlusionRenderer) {
            this._occlusionRenderer = InstancingOcclusionRenderer.get(this);
        }
        if (this._occlusionRenderer) {
            this._occlusionRenderer.drawLayer(frameCtx, this);
        }
    }

    compileShaders() {
        if (this._drawRenderer && this._drawRenderer.getValid() === false) {
            this._drawRenderer.put();
            this._drawRenderer = null;
        }
        if (this._fillRenderer && this._fillRenderer.getValid() === false) {
            this._fillRenderer.put();
            this._fillRenderer = null;
        }
        if (this._edgesRenderer && this._edgesRenderer.getValid() === false) {
            this._edgesRenderer.put();
            this._edgesRenderer = null;
        }
        if (this._pickMeshRenderer && this._pickMeshRenderer.getValid() === false) {
            this._pickMeshRenderer.put();
            this._pickMeshRenderer = null;
        }
        if (this._pickDepthRenderer && this._pickDepthRenderer.getValid() === false) {
            this._pickDepthRenderer.put();
            this._pickDepthRenderer = null;
        }
        if (this._pickNormalsRenderer && this._pickNormalsRenderer.getValid() === false) {
            this._pickNormalsRenderer.put();
            this._pickNormalsRenderer = null;
        }
        if (this._occlusionRenderer && this._occlusionRenderer.getValid() === false) {
            this._occlusionRenderer.put();
            this._occlusionRenderer = null;
        }
        if (!this._drawRenderer) {
            this._drawRenderer = InstancingDrawRenderer.get(this);
        }
        if (!this._fillRenderer) {
            this._fillRenderer = InstancingFillRenderer.get(this);
        }
        if (!this._edgesRenderer) {
            this._edgesRenderer = InstancingEdgesRenderer.get(this);
        }
        if (!this._pickMeshRenderer) {
            this._pickMeshRenderer = InstancingPickMeshRenderer.get(this);
        }
        if (!this._pickDepthRenderer) {
            this._pickDepthRenderer = InstancingPickDepthRenderer.get(this);
        }
        if (!this._pickNormalsRenderer) {
            this._pickNormalsRenderer = InstancingPickNormalsRenderer.get(this);
        }

        // Lazy-get occlusion renderer in occlude(), only when we need it
    }

    destroy() {

        if (this._drawRenderer) {
            this._drawRenderer.put();
            this._drawRenderer = null;
        }
        if (this._fillRenderer) {
            this._fillRenderer.put();
            this._fillRenderer = null;
        }
        if (this._edgesRenderer) {
            this._edgesRenderer.put();
            this._edgesRenderer = null;
        }
        if (this._pickMeshRenderer) {
            this._pickMeshRenderer.put();
            this._pickMeshRenderer = null;
        }
        if (this._pickDepthRenderer) {
            this._pickDepthRenderer.put();
            this._pickDepthRenderer = null;
        }
        if (this._pickNormalsRenderer) {
            this._pickNormalsRenderer.put();
            this._pickNormalsRenderer = null;
        }
        if (this._occlusionRenderer) {
            this._occlusionRenderer.put();
            this._occlusionRenderer = null;
        }

        const state = this._state;
        if (state.positionsBuf) {
            state.positionsBuf.destroy();
            state.positionsBuf = null;
        }
        if (state.normalsBuf) {
            state.normalsBuf.destroy();
            state.normalsBuf = null;
        }
        if (state.colorsBuf) {
            state.colorsBuf.destroy();
            state.colorsBuf = null;
        }
        if (state.flagsBuf) {
            state.flagsBuf.destroy();
            state.flagsBuf = null;
        }
        if (state.flags2Buf) {
            state.flags2Buf.destroy();
            state.flags2Buf = null;
        }
        if (state.modelMatrixCol0Buf) {
            state.modelMatrixCol0Buf.destroy();
            state.modelMatrixCol0Buf = null;
        }
        if (state.modelMatrixCol1Buf) {
            state.modelMatrixCol1Buf.destroy();
            state.modelMatrixCol1Buf = null;
        }
        if (state.modelMatrixCol2Buf) {
            state.modelMatrixCol2Buf.destroy();
            state.modelMatrixCol2Buf = null;
        }
        if (state.modelNormalMatrixCol0Buf) {
            state.modelNormalMatrixCol0Buf.destroy();
            state.modelNormalMatrixCol0Buf = null;
        }
        if (state.modelNormalMatrixCol1Buf) {
            state.modelNormalMatrixCol1Buf.destroy();
            state.modelNormalMatrixCol1Buf = null;
        }
        if (state.modelNormalMatrixCol2Buf) {
            state.modelNormalMatrixCol2Buf.destroy();
            state.modelNormalMatrixCol2Buf = null;
        }
        if (state.indicesBuf) {
            state.indicesBuf.destroy();
            state.indicessBuf = null;
        }
        if (state.edgeIndicesBuf) {
            state.edgeIndicesBuf.destroy();
            state.edgeIndicessBuf = null;
        }
        if (state.pickColorsBuf) {
            state.pickColorsBuf.destroy();
            state.pickColorsBuf = null;
        }
        state.destroy();
    }
}

var quantizePositions = (function () { // http://cg.postech.ac.kr/research/mesh_comp_mobile/mesh_comp_mobile_conference.pdf
    const translate = math.mat4();
    const scale = math.mat4();
    const scalar = math.vec3();
    return function (positions, lenPositions, aabb, quantizedPositions, positionsDecodeMatrix) {

        const xmin = aabb[0];
        const ymin = aabb[1];
        const zmin = aabb[2];
        const xmax = aabb[3];
        const ymax = aabb[4];
        const zmax = aabb[5];
        const xwid = aabb[3] - xmin;
        const ywid = aabb[4] - ymin;
        const zwid = aabb[5] - zmin;
        const xMultiplier = xmax !== xmin ? 65535 / (xmax - xmin) : 0;
        const yMultiplier = ymax !== ymin ? 65535 / (ymax - ymin) : 0;
        const zMultiplier = zmax !== zmin ? 65535 / (zmax - zmin) : 0;
        let i;
        for (i = 0; i < lenPositions; i += 3) {
            quantizedPositions[i + 0] = Math.floor((positions[i + 0] - xmin) * xMultiplier);
            quantizedPositions[i + 1] = Math.floor((positions[i + 1] - ymin) * yMultiplier);
            quantizedPositions[i + 2] = Math.floor((positions[i + 2] - zmin) * zMultiplier);
        }
        math.identityMat4(translate);
        math.translationMat4v(aabb, translate);
        math.identityMat4(scale);
        scalar[0] = xwid / 65535;
        scalar[1] = ywid / 65535;
        scalar[2] = zwid / 65535;
        math.scalingMat4v(scalar, scale);
        math.mulMat4(translate, scale, positionsDecodeMatrix);
    };
})();

function octEncodeNormals(normals, lenNormals, compressedNormals, lenCompressedNormals) { // http://jcgt.org/published/0003/02/01/
    let oct, dec, best, currentCos, bestCos;
    for (let i = 0; i < lenNormals; i += 3) {
        // Test various combinations of ceil and floor to minimize rounding errors
        best = oct = octEncodeVec3(normals, i, "floor", "floor");
        dec = octDecodeVec2(oct);
        currentCos = bestCos = dot(normals, i, dec);
        oct = octEncodeVec3(normals, i, "ceil", "floor");
        dec = octDecodeVec2(oct);
        currentCos = dot(normals, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        oct = octEncodeVec3(normals, i, "floor", "ceil");
        dec = octDecodeVec2(oct);
        currentCos = dot(normals, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        oct = octEncodeVec3(normals, i, "ceil", "ceil");
        dec = octDecodeVec2(oct);
        currentCos = dot(normals, i, dec);
        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }
        compressedNormals[lenCompressedNormals + i + 0] = best[0];
        compressedNormals[lenCompressedNormals + i + 1] = best[1];
        compressedNormals[lenCompressedNormals + i + 2] = 0.0; // Unused
    }
    lenCompressedNormals += lenNormals;
    return lenCompressedNormals;
}

function octEncodeVec3(array, i, xfunc, yfunc) { // Oct-encode single normal vector in 2 bytes
    let x = array[i] / (Math.abs(array[i]) + Math.abs(array[i + 1]) + Math.abs(array[i + 2]));
    let y = array[i + 1] / (Math.abs(array[i]) + Math.abs(array[i + 1]) + Math.abs(array[i + 2]));
    if (array[i + 2] < 0) {
        let tempx = x;
        let tempy = y;
        tempx = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
        tempy = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
        x = tempx;
        y = tempy;
    }
    return new Int8Array([
        Math[xfunc](x * 127.5 + (x < 0 ? -1 : 0)),
        Math[yfunc](y * 127.5 + (y < 0 ? -1 : 0))
    ]);
}

function octDecodeVec2(oct) { // Decode an oct-encoded normal
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

function dot(array, i, vec3) { // Dot product of a normal in an array against a candidate decoding
    return array[i] * vec3[0] + array[i + 1] * vec3[1] + array[i + 2] * vec3[2];
}

export {InstancingLayer};