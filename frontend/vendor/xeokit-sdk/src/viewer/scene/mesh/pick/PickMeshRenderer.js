/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {PickMeshShaderSource} from "./PickMeshShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from "../../stats.js";

// No ID, because there is exactly one PickMeshRenderer per scene

/**
 * @private
 */
const PickMeshRenderer = function (hash, mesh) {
    this._hash = hash;
    this._shaderSource = new PickMeshShaderSource(mesh);
    this._scene = mesh.scene;
    this._useCount = 0;
    this._allocate(mesh);
};

const renderers = {};

PickMeshRenderer.get = function (mesh) {
    const hash = [
        mesh.scene.canvas.canvas.id,
        mesh.scene._sectionPlanesState.getHash(),
        mesh._geometry._state.hash,
        mesh._state.hash
    ].join(";");
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new PickMeshRenderer(hash, mesh);
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

PickMeshRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

PickMeshRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

PickMeshRenderer.prototype.drawMesh = function (frame, mesh) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const materialState = mesh._material._state;
    const geometryState = mesh._geometry._state;
    if (frame.lastProgramId !== this._program.id) {
        frame.lastProgramId = this._program.id;
        this._bindProgram(frame);
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
        const frontface = materialState.frontface;
        if (frame.frontface !== frontface) {
            if (frontface) {
                gl.frontFace(gl.CCW);
            } else {
                gl.frontFace(gl.CW);
            }
            frame.frontface = frontface;
        }
        this._lastMaterialId = materialState.id;
    }
    gl.uniformMatrix4fv(this._uViewMatrix, false, frame.pickViewMatrix);
    gl.uniformMatrix4fv(this._uProjMatrix, false, frame.pickProjMatrix);
    gl.uniformMatrix4fv(this._uModelMatrix, false, mesh.worldMatrix);
    // Mesh state
    if (this._uClippable) {
        gl.uniform1i(this._uClippable, mesh._state.clippable);
    }
    // Bind VBOs
    if (geometryState.id !== this._lastGeometryId) {
        if (this._uPositionsDecodeMatrix) {
            gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
        }
        if (this._aPosition) {
            this._aPosition.bindArrayBuffer(geometryState.positionsBuf, geometryState.compressGeometry ? gl.UNSIGNED_SHORT : gl.FLOAT);
            frame.bindArray++;
        }
        if (geometryState.indicesBuf) {
            geometryState.indicesBuf.bind();
            frame.bindArray++;
        }
        this._lastGeometryId = geometryState.id;
    }
    // Mesh-indexed color
    var pickID = mesh._state.pickID;
    const a = pickID >> 24 & 0xFF;
    const b = pickID >> 16 & 0xFF;
    const g = pickID >> 8 & 0xFF;
    const r = pickID & 0xFF;
    gl.uniform4f(this._uPickColor, r / 255, g / 255, b / 255, a / 255);
    if (geometryState.indicesBuf) {
        gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
        frame.drawElements++;
    } else if (geometryState.positions) {
        gl.drawArrays(gl.TRIANGLES, 0, geometryState.positions.numItems);
    }
};

PickMeshRenderer.prototype._allocate = function (mesh) {
    const gl = mesh.scene.canvas.gl;
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
    const clips = mesh.scene._sectionPlanesState.sectionPlanes;
    for (let i = 0, len = clips.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._uClippable = program.getLocation("clippable");
    this._uPickColor = program.getLocation("pickColor");
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
};

PickMeshRenderer.prototype._bindProgram = function (frame) {
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    this._program.bind();
    frame.useProgram++;
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
    if (sectionPlanesState.sectionPlanes.length > 0) {
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (let i = 0, len = this._uSectionPlanes.length; i < len; i++) {
            sectionPlaneUniforms = this._uSectionPlanes[i];
            uSectionPlaneActive = sectionPlaneUniforms.active;
            sectionPlane = sectionPlanesState.sectionPlanes[i];
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

export {PickMeshRenderer};
