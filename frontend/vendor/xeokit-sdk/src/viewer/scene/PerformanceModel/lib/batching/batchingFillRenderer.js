import {Map} from "../../../utils/Map.js";
import {stats} from "../../../stats.js"
import {Program} from "../../../webgl/Program.js";
import {BatchingFillShaderSource} from "./batchingFillShaderSource.js";
import {RENDER_PASSES} from '../renderPasses.js';

const ids = new Map({});

/**
 * @private
 */
const BatchingFillRenderer = function (hash, layer) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = layer.model.scene;
    this._useCount = 0;
    this._shaderSource = new BatchingFillShaderSource(layer);
    this._allocate(layer);
};

const renderers = {};
const defaultColor = new Float32Array([1.0, 1.0, 1.0, 1.0]);

BatchingFillRenderer.get = function (layer) {
    const scene = layer.model.scene;
    const hash = getHash(scene);
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new BatchingFillRenderer(hash, layer);
        if (renderer.errors) {
            console.log(renderer.errors.join("\n"));
            return null;
        }
        renderers[hash] = renderer;
        stats.memory.programs++;
    }
    renderer._useCount++;
    return renderer;
};

function getHash(scene) {
    return [scene.canvas.canvas.id, "", scene._sectionPlanesState.getHash()].join(";")
}

BatchingFillRenderer.prototype.getValid = function () {
    return this._hash === getHash(this._scene);
};

BatchingFillRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

BatchingFillRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

BatchingFillRenderer.prototype.drawLayer = function (frameCtx, layer, renderPass) {
    const model = layer.model;
    const scene = model.scene;
    const gl = scene.canvas.gl;
    const state = layer._state;
    if (!this._program) {
        this._allocate(layer);
        if (this.errors) {
            return;
        }
    }

    if (frameCtx.lastProgramId !== this._program.id) {
        frameCtx.lastProgramId = this._program.id;
        this._bindProgram(frameCtx, layer);
    }
    gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, layer._state.positionsDecodeMatrix);
    gl.uniformMatrix4fv(this._uViewMatrix, false, model.viewMatrix);
    gl.uniformMatrix4fv(this._uViewNormalMatrix, false, model.viewNormalMatrix);
    gl.uniform1i(this._uRenderPass, renderPass);
    gl.uniformMatrix4fv(this._uModelMatrix, gl.FALSE, model.worldMatrix);

    this._aPosition.bindArrayBuffer(state.positionsBuf);
    frameCtx.bindArray++;
    if (this._aFlags) {
        this._aFlags.bindArrayBuffer(state.flagsBuf);
        frameCtx.bindArray++;
    }
    if (this._aFlags2) {
        this._aFlags2.bindArrayBuffer(state.flags2Buf);
        frameCtx.bindArray++;
    }
    state.indicesBuf.bind();
    frameCtx.bindArray++;
    if (renderPass === RENDER_PASSES.XRAYED) {
        const material = scene.xrayMaterial._state;
        const fillColor = material.fillColor;
        const fillAlpha = material.fillAlpha;
        gl.uniform4f(this._uColor, fillColor[0], fillColor[1], fillColor[2], fillAlpha);
    } else if (renderPass === RENDER_PASSES.HIGHLIGHTED) {
        const material = scene.highlightMaterial._state;
        const fillColor = material.fillColor;
        const fillAlpha = material.fillAlpha;
        gl.uniform4f(this._uColor, fillColor[0], fillColor[1], fillColor[2], fillAlpha);
    } else if (renderPass === RENDER_PASSES.SELECTED) {
        const material = scene.selectedMaterial._state;
        const fillColor = material.fillColor;
        const fillAlpha = material.fillAlpha;
        gl.uniform4f(this._uColor, fillColor[0], fillColor[1], fillColor[2], fillAlpha);
    } else {
        gl.uniform4fv(this._uColor, defaultColor);
    }
    gl.drawElements(state.primitive, state.indicesBuf.numItems, state.indicesBuf.itemType, 0);
    frameCtx.drawElements++;
};

BatchingFillRenderer.prototype._allocate = function (layer) {
    const scene = layer.model.scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uRenderPass = program.getLocation("renderPass");
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uModelMatrix = program.getLocation("modelMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uColor = program.getLocation("color");
    this._uSectionPlanes = [];
    const clips = sectionPlanesState.sectionPlanes;
    for (var i = 0, len = clips.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._aFlags = program.getAttribute("flags");
    this._aFlags2 = program.getAttribute("flags2");
};

BatchingFillRenderer.prototype._bindProgram = function (frameCtx, layer) {
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const program = this._program;
    const sectionPlanesState = scene._sectionPlanesState;
    program.bind();
    frameCtx.useProgram++;
    const camera = scene.camera;
    gl.uniformMatrix4fv(this._uProjMatrix, false, camera._project._state.matrix);
    if (sectionPlanesState.sectionPlanes.length > 0) {
        const clips = scene._sectionPlanesState.sectionPlanes;
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (var i = 0, len = this._uSectionPlanes.length; i < len; i++) {
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
};

export {BatchingFillRenderer};
