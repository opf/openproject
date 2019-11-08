/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {Map} from "../../utils/Map.js";
import {EmphasisFillShaderSource} from "./EmphasisFillShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from '../../stats.js';

const ids = new Map({});

/**
 * @private
 */
const EmphasisFillRenderer = function (hash, mesh) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = mesh.scene;
    this._useCount = 0;
    this._shaderSource = new EmphasisFillShaderSource(mesh);
    this._allocate(mesh);
};

const xrayFillRenderers = {};

EmphasisFillRenderer.get = function (mesh) {
    const hash = [
        mesh.scene.id,
        mesh.scene.gammaOutput ? "go" : "", // Gamma input not needed
        mesh.scene._sectionPlanesState.getHash(),
        !!mesh._geometry._state.normalsBuf ? "n" : "",
        mesh._geometry._state.compressGeometry ? "cp" : "",
        mesh._state.hash
    ].join(";");
    let renderer = xrayFillRenderers[hash];
    if (!renderer) {
        renderer = new EmphasisFillRenderer(hash, mesh);
        xrayFillRenderers[hash] = renderer;
        stats.memory.programs++;
    }
    renderer._useCount++;
    return renderer;
};

EmphasisFillRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete xrayFillRenderers[this._hash];
        stats.memory.programs--;
    }
};

EmphasisFillRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

EmphasisFillRenderer.prototype.drawMesh = function (frame, mesh, mode) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const materialState = mode === 0 ? mesh._xrayMaterial._state : (mode === 1 ? mesh._highlightMaterial._state : mesh._selectedMaterial._state);
    const meshState = mesh._state;
    const geometryState = mesh._geometry._state;
    if (frame.lastProgramId !== this._program.id) {
        frame.lastProgramId = this._program.id;
        this._bindProgram(frame);
    }
    if (materialState.id !== this._lastMaterialId) {
        const fillColor = materialState.fillColor;
        const backfaces = materialState.backfaces;
        if (frame.backfaces !== backfaces) {
            if (backfaces) {
                gl.disable(gl.CULL_FACE);
            } else {
                gl.enable(gl.CULL_FACE);
            }
            frame.backfaces = backfaces;
        }
        gl.uniform4f(this._uFillColor, fillColor[0], fillColor[1], fillColor[2], materialState.fillAlpha);
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
    if (geometryState.id !== this._lastGeometryId) {
        if (this._uPositionsDecodeMatrix) {
            gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
        }
        if (this._uUVDecodeMatrix) {
            gl.uniformMatrix3fv(this._uUVDecodeMatrix, false, geometryState.uvDecodeMatrix);
        }
        if (this._aPosition) {
            this._aPosition.bindArrayBuffer(geometryState.positionsBuf);
            frame.bindArray++;
        }
        if (this._aNormal) {
            this._aNormal.bindArrayBuffer(geometryState.normalsBuf);
            frame.bindArray++;
        }
        if (geometryState.indicesBuf) {
            geometryState.indicesBuf.bind();
            frame.bindArray++;
            // gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
            // frame.drawElements++;
        } else if (geometryState.positionsBuf) {
            // gl.drawArrays(gl.TRIANGLES, 0, geometryState.positions.numItems);
            //  frame.drawArrays++;
        }
        this._lastGeometryId = geometryState.id;
    }
    if (geometryState.indicesBuf) {
        gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
        frame.drawElements++;
    } else if (geometryState.positionsBuf) {
        gl.drawArrays(gl.TRIANGLES, 0, geometryState.positionsBuf.numItems);
        frame.drawArrays++;
    }
};

EmphasisFillRenderer.prototype._allocate = function (mesh) {
    const lightsState = mesh.scene._lightsState;
    const sectionPlanesState = mesh.scene._sectionPlanesState;
    const gl = mesh.scene.canvas.gl;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uModelMatrix = program.getLocation("modelMatrix");
    this._uModelNormalMatrix = program.getLocation("modelNormalMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uViewNormalMatrix = program.getLocation("viewNormalMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uLightAmbient = [];
    this._uLightColor = [];
    this._uLightDir = [];
    this._uLightPos = [];
    this._uLightAttenuation = [];
    for (var i = 0, len = lightsState.lights.length; i < len; i++) {
        const light = lightsState.lights[i];
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
        }
    }
    this._uSectionPlanes = [];
    for (var i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._uFillColor = program.getLocation("fillColor");
    this._aPosition = program.getAttribute("position");
    this._aNormal = program.getAttribute("normal");
    this._uClippable = program.getLocation("clippable");
    this._uGammaFactor = program.getLocation("gammaFactor");
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
};

EmphasisFillRenderer.prototype._bindProgram = function (frame) {
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    const lightsState = scene._lightsState;
    const camera = scene.camera;
    const cameraState = camera._state;
    let light;
    const program = this._program;
    program.bind();
    frame.useProgram++;
    frame.textureUnit = 0;
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
    this._lastIndicesBufId = null;
    gl.uniformMatrix4fv(this._uViewMatrix, false, cameraState.matrix);
    gl.uniformMatrix4fv(this._uViewNormalMatrix, false, cameraState.normalMatrix);
    gl.uniformMatrix4fv(this._uProjMatrix, false, camera.project._state.matrix);
    for (var i = 0, len = lightsState.lights.length; i < len; i++) {
        light = lightsState.lights[i];
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
    if (this._uGammaFactor) {
        gl.uniform1f(this._uGammaFactor, scene.gammaFactor);
    }
};

export {EmphasisFillRenderer};
