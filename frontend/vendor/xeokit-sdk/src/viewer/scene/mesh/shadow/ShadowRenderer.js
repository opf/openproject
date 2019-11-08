/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {ShadowShaderSource} from "./ShadowShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from "../../stats.js";

/**
 * @private
 */
const ShadowRenderer = function (hash, mesh) {
    this._hash = hash;
    this._shaderSource = new ShadowShaderSource(mesh);
    this._scene = mesh.scene;
    this._useCount = 0;
    this._allocate(mesh);
};

const renderers = {};

ShadowRenderer.get = function (mesh) {
    const scene = mesh.scene;
    const hash = [
        scene.canvas.canvas.id,
        scene._sectionPlanesState.getHash(),
        mesh._geometry._state.hash,
        mesh._state.hash].join(";");
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new ShadowRenderer(hash, mesh);
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

ShadowRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

ShadowRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};


ShadowRenderer.prototype.drawMesh = function (frame, mesh, light) {
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
    frame.textureUnit = 0;
    if (light.id !== this._lastLightId) {
        gl.uniformMatrix4fv(this._uViewMatrix, false, light.getShadowViewMatrix());
        gl.uniformMatrix4fv(this._uProjMatrix, false, light.getShadowProjMatrix());
        this._lastLightId = light.id;
    }
    // gl.uniformMatrix4fv(this._uViewMatrix, false, this._scene.viewTransform.matrix);
    // gl.uniformMatrix4fv(this._uProjMatrix, false, this._scene.projTransform.matrix);
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
        if (frame.lineWidth !== materialState.lineWidth) {
            gl.lineWidth(materialState.lineWidth);
            frame.lineWidth = materialState.lineWidth;
        }
        if (this._uPointSize) {
            gl.uniform1i(this._uPointSize, materialState.pointSize);
        }
        this._lastMaterialId = materialState.id;
    }
    gl.uniformMatrix4fv(this._uModelMatrix, gl.FALSE, mesh.worldMatrix);
    if (geometryState.combineGeometry) {
        const vertexBufs = mesh.vertexBufs;
        if (vertexBufs.id !== this._lastVertexBufsId) {
            if (vertexBufs.positionsBuf && this._aPosition) {
                this._aPosition.bindArrayBuffer(vertexBufs.positionsBuf, vertexBufs.compressGeometry ? gl.UNSIGNED_SHORT : gl.FLOAT);
                frame.bindArray++;
            }
            this._lastVertexBufsId = vertexBufs.id;
        }
    }
    if (this._uClippable) {
        gl.uniform1i(this._uClippable, mesh._state.clippable);
    }
    if (geometryState.id !== this._lastGeometryId) {
        if (this._uPositionsDecodeMatrix) {
            gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
        }
        if (geometryState.combineGeometry) { // VBOs were bound by the preceding VertexBufs chunk
            if (geometryState.indicesBufCombined) {
                geometryState.indicesBufCombined.bind();
                frame.bindArray++;
            }
        } else {
            if (this._aPosition) {
                this._aPosition.bindArrayBuffer(geometryState.positionsBuf, geometryState.compressGeometry ? gl.UNSIGNED_SHORT : gl.FLOAT);
                frame.bindArray++;
            }
            if (geometryState.indicesBuf) {
                geometryState.indicesBuf.bind();
                frame.bindArray++;
            }
        }
        this._lastGeometryId = geometryState.id;
    }
    if (geometryState.combineGeometry) {
        if (geometryState.indicesBufCombined) {
            gl.drawElements(geometryState.primitive, geometryState.indicesBufCombined.numItems, geometryState.indicesBufCombined.itemType, 0);
            frame.drawElements++;
        } else {
            // TODO: drawArrays() with VertexBufs positions
        }
    } else {
        if (geometryState.indicesBuf) {
            gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
            frame.drawElements++;
        } else if (geometryState.positions) {
            gl.drawArrays(gl.TRIANGLES, 0, geometryState.positions.numItems);
            frame.drawArrays++;
        }
    }
};

ShadowRenderer.prototype._allocate = function (mesh) {
    const scene = mesh.scene;
    const gl = scene.canvas.gl;
    this._program = new Program(gl, this._shaderSource);
    this._scene = scene;
    this._useCount = 0;
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uModelMatrix = program.getLocation("modelMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uSectionPlanes = {};
    const clips = scene._sectionPlanesState.sectionPlanes;
    for (let i = 0, len = clips.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._uClippable = program.getLocation("clippable");
    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;
};

ShadowRenderer.prototype._bindProgram = function (frame) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    this._program.bind();
    frame.useProgram++;
    this._lastLightId = null;
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

export {ShadowRenderer};
