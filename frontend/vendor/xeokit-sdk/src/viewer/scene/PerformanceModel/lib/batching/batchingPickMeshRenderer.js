import {Map} from "../../../utils/Map.js";
import {stats} from "../../../stats.js"
import {Program} from "../../../webgl/Program.js";
import {BatchingPickMeshShaderSource} from "./batchingPickMeshShaderSource.js";

const ids = new Map({});

/**
 * @private
 * @constructor
 */
const BatchingPickMeshRenderer = function (hash, layer) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = layer.model.scene;
    this._useCount = 0;
    this._shaderSource = new BatchingPickMeshShaderSource(layer);
    this._allocate(layer);
};

const renderers = {};

BatchingPickMeshRenderer.get = function (layer) {
    const scene = layer.model.scene;
    const hash = getHash(scene);
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new BatchingPickMeshRenderer(hash, layer);
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

BatchingPickMeshRenderer.prototype.getValid = function () {
    return this._hash === getHash(this._scene);
};

BatchingPickMeshRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

BatchingPickMeshRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

BatchingPickMeshRenderer.prototype.drawLayer = function (frameCtx, layer) {
    const model = layer.model;
    const scene = model.scene;
    const gl = scene.canvas.gl;
    const state = layer._state;
    if (!this._program) {
        this._allocate(layer);
    }
    if (frameCtx.lastProgramId !== this._program.id) {
        frameCtx.lastProgramId = this._program.id;
        this._bindProgram(frameCtx, layer);
    }
    gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, layer._state.positionsDecodeMatrix);
    gl.uniformMatrix4fv(this._uViewMatrix, false, frameCtx.pickViewMatrix ? model.getPickViewMatrix(frameCtx.pickViewMatrix) : model.viewMatrix);
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
    if (this._aPickColor) {
        this._aPickColor.bindArrayBuffer(state.pickColorsBuf);
        frameCtx.bindArray++;
    }
    state.indicesBuf.bind();
    frameCtx.bindArray++;
    gl.drawElements(state.primitive, state.indicesBuf.numItems, state.indicesBuf.itemType, 0);
    frameCtx.drawElements++;
};

BatchingPickMeshRenderer.prototype._allocate = function (layer) {
    var scene = layer.model.scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uPickInvisible = program.getLocation("pickInvisible");
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uSectionPlanes = [];
    const sectionPlanes = sectionPlanesState.sectionPlanes;
    for (var i = 0, len = sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._aPickColor = program.getAttribute("pickColor");
    this._aFlags = program.getAttribute("flags");
    this._aFlags2 = program.getAttribute("flags2");
};

BatchingPickMeshRenderer.prototype._bindProgram = function (frameCtx, layer) {
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const program = this._program;
    const sectionPlanesState = scene._sectionPlanesState;
    const camera = scene.camera;
    program.bind();
    frameCtx.useProgram++;
    gl.uniform1i(this._uPickInvisible, frameCtx.pickInvisible);
    gl.uniformMatrix4fv(this._uProjMatrix, false, frameCtx.pickProjMatrix || camera.project._state.matrix);
    if (sectionPlanesState.sectionPlanes.length > 0) {
        const sectionPlanes = scene._sectionPlanesState.sectionPlanes;
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (var i = 0, len = this._uSectionPlanes.length; i < len; i++) {
            sectionPlaneUniforms = this._uSectionPlanes[i];
            uSectionPlaneActive = sectionPlaneUniforms.active;
            sectionPlane = sectionPlanes[i];
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

export {BatchingPickMeshRenderer};
