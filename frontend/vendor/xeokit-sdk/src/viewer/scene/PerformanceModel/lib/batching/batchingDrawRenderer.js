import {Map} from "../../../utils/Map.js";
import {stats} from "../../../stats.js"
import {Program} from "../../../webgl/Program.js";
import {BatchingDrawShaderSource} from "./batchingDrawShaderSource.js";
import {RENDER_PASSES} from '../renderPasses.js';

const ids = new Map({});

/**
 * @private
 * @constructor
 */
const BatchingDrawRenderer = function (hash, layer) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = layer.model.scene;
    this._useCount = 0;
    this._shaderSource = new BatchingDrawShaderSource(layer);
    this._allocate(layer);
};

const renderers = {};
const defaultColorize = new Float32Array([1.0, 1.0, 1.0, 1.0]);

BatchingDrawRenderer.get = function (layer) {
    const scene = layer.model.scene;
    const hash = getHash(scene);
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new BatchingDrawRenderer(hash, layer);
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
    return [scene.canvas.canvas.id, "", scene._lightsState.getHash(), scene._sectionPlanesState.getHash()].join(";")
}

BatchingDrawRenderer.prototype.getValid = function () {
    return this._hash === getHash(this._scene);
};

BatchingDrawRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

BatchingDrawRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

BatchingDrawRenderer.prototype.drawLayer = function (frameCtx, layer, renderPass) {
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
    gl.uniformMatrix4fv(this._uViewMatrix, false, model.viewMatrix);
    gl.uniformMatrix4fv(this._uViewNormalMatrix, false, model.viewNormalMatrix);
    gl.uniform1i(this._uRenderPass, renderPass);
    this._aPosition.bindArrayBuffer(state.positionsBuf);
    frameCtx.bindArray++;
    if (this._aNormal) {
        this._aNormal.bindArrayBuffer(state.normalsBuf);
        frameCtx.bindArray++;
    }
    if (this._aColor) {
        this._aColor.bindArrayBuffer(state.colorsBuf);
        frameCtx.bindArray++;
    }
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
        gl.uniform4f(this._uColorize, fillColor[0], fillColor[1], fillColor[2], fillAlpha);
    } else if (renderPass === RENDER_PASSES.HIGHLIGHTED) {
        const material = scene.highlightMaterial._state;
        const fillColor = material.fillColor;
        const fillAlpha = material.fillAlpha;
        gl.uniform4f(this._uColorize, fillColor[0], fillColor[1], fillColor[2], fillAlpha);
    } else {
        gl.uniform4fv(this._uColorize, defaultColorize);
    }
    gl.drawElements(state.primitive, state.indicesBuf.numItems, state.indicesBuf.itemType, 0);
    frameCtx.drawElements++;
};

BatchingDrawRenderer.prototype._allocate = function (layer) {
    var scene = layer.model.scene;
    const gl = scene.canvas.gl;
    const lightsState = scene._lightsState;
    const sectionPlanesState = scene._sectionPlanesState;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uRenderPass = program.getLocation("renderPass");
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uViewNormalMatrix = program.getLocation("viewNormalMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uColorize = program.getLocation("colorize");
    this._uLightAmbient = [];
    this._uLightColor = [];
    this._uLightDir = [];
    this._uLightPos = [];
    this._uLightAttenuation = [];
    const lights = lightsState.lights;
    let light;

    for (let i = 0, len = lights.length; i < len; i++) {
        light = lights[i];
        switch (light.type) {
            case "ambient":
                this._uLightAmbient[i] = program.getLocation("lightAmbient");
                break;
            case "dir":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = null;
                this._uLightDir[i] = program.getLocation("lightDir" + i);
                break;
            case "point":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = program.getLocation("lightPos" + i);
                this._uLightDir[i] = null;
                this._uLightAttenuation[i] = program.getLocation("lightAttenuation" + i);
                break;
            case "spot":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = program.getLocation("lightPos" + i);
                this._uLightDir[i] = program.getLocation("lightDir" + i);
                this._uLightAttenuation[i] = program.getLocation("lightAttenuation" + i);
                break;
        }
    }
    this._uSectionPlanes = [];
    const sectionPlanes = sectionPlanesState.sectionPlanes;
    for (let i = 0, len = sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._aNormal = program.getAttribute("normal");
    this._aColor = program.getAttribute("color");
    this._aFlags = program.getAttribute("flags");
    this._aFlags2 = program.getAttribute("flags2");
};

BatchingDrawRenderer.prototype._bindProgram = function (frameCtx, layer) {
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const program = this._program;
    const lightsState = scene._lightsState;
    const sectionPlanesState = scene._sectionPlanesState;
    const lights = lightsState.lights;
    let light;
    program.bind();
    frameCtx.useProgram++;
    const camera = scene.camera;
    gl.uniformMatrix4fv(this._uProjMatrix, false, camera._project._state.matrix);
    for (var i = 0, len = lights.length; i < len; i++) {
        light = lights[i];
        if (this._uLightAmbient[i]) {
            gl.uniform4f(this._uLightAmbient[i], light.color[0], light.color[1], light.color[2], light.intensity);
        } else {
            if (this._uLightColor[i]) {
                gl.uniform4f(this._uLightColor[i], light.color[0], light.color[1], light.color[2], light.intensity);
            }
            if (this._uLightPos[i]) {
                gl.uniform3fv(this._uLightPos[i], light.pos);
                if (this._uLightAttenuation[i]) {
                    gl.uniform1f(this._uLightAttenuation[i], light.attenuation);
                }
            }
            if (this._uLightDir[i]) {
                gl.uniform3fv(this._uLightDir[i], light.dir);
            }
        }
    }
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

export {BatchingDrawRenderer};
