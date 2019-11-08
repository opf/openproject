/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {PickTriangleShaderSource} from "./PickTriangleShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from "../../stats.js";

/**
 * @private
 */
const PickTriangleRenderer = function (hash, mesh) {
    this._hash = hash;
    this._scene = mesh.scene;
    this._useCount = 0;
    this._shaderSource = new PickTriangleShaderSource(mesh);
    this._allocate(mesh);
};

const renderers = {};

PickTriangleRenderer.get = function (mesh) {
    const hash = [
        mesh.scene.canvas.canvas.id,
        mesh.scene._sectionPlanesState.getHash(),
        mesh._geometry._state.compressGeometry ? "cp" : "",
        mesh._state.hash
    ].join(";");
    let renderer = renderers[hash];
    if (!renderer) {
        renderer = new PickTriangleRenderer(hash, mesh);
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

PickTriangleRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        if (this._program) {
            this._program.destroy();
        }
        delete renderers[this._hash];
        stats.memory.programs--;
    }
};

PickTriangleRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

PickTriangleRenderer.prototype.drawMesh = function (frame, mesh) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    const materialState = mesh._material._state;
    const meshState = mesh._state;
    const geometry = mesh._geometry;
    const geometryState = mesh._geometry._state;
    const backfaces = materialState.backfaces;
    const frontface = materialState.frontface;
    const positionsBuf = geometry._getPickTrianglePositions();
    const pickColorsBuf = geometry._getPickTriangleColors();
    const camera = scene.camera;
    const cameraState = camera._state;
    this._program.bind();
    frame.useProgram++;
    gl.uniformMatrix4fv(this._uViewMatrix, false, frame.pickViewMatrix);
    gl.uniformMatrix4fv(this._uProjMatrix, false, frame.pickProjMatrix);
    if (sectionPlanesState.sectionPlanes.length > 0) {
        const sectionPlanes = sectionPlanesState.sectionPlanes;
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (let i = 0, len = this._uSectionPlanes.length; i < len; i++) {
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
    if (frame.backfaces !== backfaces) {
        if (backfaces) {
            gl.disable(gl.CULL_FACE);
        } else {
            gl.enable(gl.CULL_FACE);
        }
        frame.backfaces = backfaces;
    }
    if (frame.frontface !== frontface) {
        if (frontface) {
            gl.frontFace(gl.CCW);
        } else {
            gl.frontFace(gl.CW);
        }
        frame.frontface = frontface;
    }
    this._lastMaterialId = materialState.id;
    gl.uniformMatrix4fv(this._uModelMatrix, false, mesh.worldMatrix);
    if (this._uClippable) {
        gl.uniform1i(this._uClippable, mesh._state.clippable);
    }
    if (this._uPositionsDecodeMatrix) {
        gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
        this._aPosition.bindArrayBuffer(positionsBuf, geometryState.compressGeometry ? gl.UNSIGNED_SHORT : gl.FLOAT);
    } else {
        this._aPosition.bindArrayBuffer(positionsBuf);
    }
    pickColorsBuf.bind();
    gl.enableVertexAttribArray(this._aColor.location);
    gl.vertexAttribPointer(this._aColor.location, pickColorsBuf.itemSize, pickColorsBuf.itemType, true, 0, 0); // Normalize
    gl.drawArrays(geometryState.primitive, 0, positionsBuf.numItems / 3);
};

PickTriangleRenderer.prototype._allocate = function (mesh) {
    const gl = mesh.scene.canvas.gl;
    this._program = new Program(gl, this._shaderSource);
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
    this._uSectionPlanes = [];
    const sectionPlanes = mesh.scene._sectionPlanesState.sectionPlanes;
    for (let i = 0, len = sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }
    this._aPosition = program.getAttribute("position");
    this._aColor = program.getAttribute("color");
    this._uClippable = program.getLocation("clippable");
};

export {PickTriangleRenderer};



