/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {Map} from "../../utils/Map.js";
import {EmphasisEdgesShaderSource} from "./EmphasisEdgesShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from '../../stats.js';

const ids = new Map({});

/**
 * @private
 */
const EmphasisEdgesRenderer = function (hash, mesh) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = mesh.scene;
    this._useCount = 0;
    this._shaderSource = new EmphasisEdgesShaderSource(mesh);
    this._allocate(mesh);
};

const renderers = {};

EmphasisEdgesRenderer.get = function (mesh) {
    const hash = [
        mesh.scene.id,
        mesh.scene.gammaOutput ? "go" : "", // Gamma input not needed
        mesh.scene._sectionPlanesState.getHash(),
        mesh._geometry._state.compressGeometry ? "cp" : "",
        mesh._state.hash
    ].join(";");
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new EmphasisEdgesRenderer(hash, mesh);
        renderers[hash] = renderer;
        stats.memory.programs++;
    }
    renderer._useCount++;
    return renderer;
};

EmphasisEdgesRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

EmphasisEdgesRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

EmphasisEdgesRenderer.prototype.drawMesh = function (frame, mesh, mode) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const scene = this._scene;
    const gl = scene.canvas.gl;
    let materialState;
    const meshState = mesh._state;
    const geometry = mesh._geometry;
    const geometryState = geometry._state;
    if (frame.lastProgramId !== this._program.id) {
        frame.lastProgramId = this._program.id;
        this._bindProgram(frame);
    }
    switch (mode) {
        case 0:
            materialState = mesh._xrayMaterial._state;
            break;
        case 1:
            materialState = mesh._highlightMaterial._state;
            break;
        case 2:
            materialState = mesh._selectedMaterial._state;
            break;
        case 3:
        default:
            materialState = mesh._edgeMaterial._state;
            break;
    }
    if (materialState.id !== this._lastMaterialId) {
        const backfaces = materialState.backfaces;
        if (frame.backfaces !== backfaces) {
            if (backfaces) {
                gl.disable(gl.CULL_FACE);
            } else {
                gl.enable(gl.CULL_FACE);
            }
            frame.backfaces = backfaces;
        }
        if (frame.lineWidth !== materialState.edgeWidth) {
            gl.lineWidth(materialState.edgeWidth);
            frame.lineWidth = materialState.edgeWidth;
        }
        if (this._uEdgeColor) {
            const edgeColor = materialState.edgeColor;
            const edgeAlpha = materialState.edgeAlpha;
            gl.uniform4f(this._uEdgeColor, edgeColor[0], edgeColor[1], edgeColor[2], edgeAlpha);
        }
        this._lastMaterialId = materialState.id;
    }
    gl.uniformMatrix4fv(this._uModelMatrix, gl.FALSE, mesh.worldMatrix);
    if (this._uModelNormalMatrix) {
        gl.uniformMatrix4fv(this._uModelNormalMatrix, gl.FALSE, mesh.worldNormalMatrix);
    }
    if (this._uClippable) {
        gl.uniform1i(this._uClippable, meshState.clippable);
    }

    // Bind VBOs
    let indicesBuf;
    if (geometryState.primitive === gl.TRIANGLES) {
        indicesBuf = geometry._getEdgeIndices();
    } else if (geometryState.primitive === gl.LINES) {
        indicesBuf = geometryState.indicesBuf;
    }
    if (indicesBuf) {
        if (geometryState.id !== this._lastGeometryId) {
            if (this._uPositionsDecodeMatrix) {
                gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
            }
            if (this._aPosition) {
                this._aPosition.bindArrayBuffer(geometryState.positionsBuf, geometryState.compressGeometry ? gl.UNSIGNED_SHORT : gl.FLOAT);
                frame.bindArray++;
            }
            indicesBuf.bind();
            frame.bindArray++;
            this._lastGeometryId = geometryState.id;
        }
        gl.drawElements(gl.LINES, indicesBuf.numItems, indicesBuf.itemType, 0);
        frame.drawElements++;
    }
};

EmphasisEdgesRenderer.prototype._allocate = function (mesh) {
    const gl = mesh.scene.canvas.gl;
    const sectionPlanesState = mesh.scene._sectionPlanesState;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uModelMatrix = program.getLocation("modelMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uSectionPlanes = [];
    for (let i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._uEdgeColor = program.getLocation("edgeColor");
    this._aPosition = program.getAttribute("position");
    this._uClippable = program.getLocation("clippable");
    this._uGammaFactor = program.getLocation("gammaFactor");
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
};

EmphasisEdgesRenderer.prototype._bindProgram = function (frame) {
    const program = this._program;
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    const camera = scene.camera;
    const cameraState = camera._state;
    program.bind();
    frame.useProgram++;
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
    gl.uniformMatrix4fv(this._uViewMatrix, false, cameraState.matrix);
    gl.uniformMatrix4fv(this._uProjMatrix, false, camera.project._state.matrix);
    if (sectionPlanesState.sectionPlanes.length > 0) {
        const clips = sectionPlanesState.sectionPlanes;
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (let i = 0, len = this._uSectionPlanes.length; i < len; i++) {
            sectionPlaneUniforms = this._uSectionPlanes[i];
            uSectionPlaneActive = sectionPlaneUniforms.active;
            sectionPlane = clips[i];
            if (uSectionPlaneActive) {
                gl.uniform1i(uSectionPlaneActive, sectionPlane.active);
            }
            uSectionPlanePos = sectionPlaneUniforms.pos;
            if (uSectionPlanePos) {
                gl.uniform3fv(sectionPlaneUniforms.pos, sectionPlane.pos);
            }
            uSectionPlaneDir = sectionPlaneUniforms.dir;
            if (uSectionPlaneDir) {
                gl.uniform3fv(sectionPlaneUniforms.dir, sectionPlane.dir);
            }
        }
    }
    if (this._uGammaFactor) {
        gl.uniform1f(this._uGammaFactor, scene.gammaFactor);
    }
};

export {EmphasisEdgesRenderer};
