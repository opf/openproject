import {math} from '../math/math.js';
import {Program} from "./Program.js";
import {ArrayBuf} from "./ArrayBuf.js";
import {RenderBuffer} from "./RenderBuffer.js";

const TEST_MODE = false;
const MARKER_COLOR = math.vec3([1.0, 0.0, 0.0]);
const POINT_SIZE = 20;

/**
 * Manages occlusion testing. Private member of a Renderer.
 */
class OcclusionTester {

    constructor(scene) {

        this._scene = scene;
        this._markers = {};                     // ID map of Markers
        this._markerList = [];                  // Ordered array of Markers
        this._markerIndices = {};               // ID map of Marker indices in _markerList
        this._numMarkers = 0;                   // Length of _markerList
        this._positions = [];                   // Packed array of World-space marker positions
        this._indices = [];                     // Indices corresponding to array above
        this._positionsBuf = null;              // Positions VBO to render marker positions
        this._indicesBuf = null;                // Indices VBO
        this._occlusionTestList = [];           // List of
        this._lenOcclusionTestList = 0;
        this._pixels = [];
        this._shaderSource = null;
        this._program = null;

        this._shaderSourceHash = null;

        this._shaderSourceDirty = true;         // Need to build shader source code ?
        this._programDirty = false;             // Need to build shader program ?
        this._markerListDirty = false;          // Need to (re)build _markerList ?
        this._positionsDirty = false;           // Need to (re)build _positions and _indices ?
        this._vbosDirty = false;                // Need to rebuild _positionsBuf and _indicesBuf ?
        this._occlusionTestListDirty = false;   // Need to build _occlusionTestList ?

        this._lenPositionsBuf = 0;

        scene.camera.on("viewMatrix", () => {
            this._occlusionTestListDirty = true;
        });

        scene.camera.on("projMatrix", () => {
            this._occlusionTestListDirty = true;
        });

        scene.canvas.on("boundary", () => {
            this._occlusionTestListDirty = true;
        });
    }

    /**
     * Adds a Marker for occlusion testing.
     * @param marker
     */
    addMarker(marker) {
        this._markers[marker.id] = marker;
        this._markerListDirty = true;
    }

    /**
     * Notifies OcclusionTester that a Marker has updated its World-space position.
     * @param marker
     */
    markerWorldPosUpdated(marker) {
        if (!this._markers[marker.id]) { // Not added
            return;
        }
        const i = this._markerIndices[marker.id];
        this._positions[i * 3 + 0] = marker.worldPos[0];
        this._positions[i * 3 + 1] = marker.worldPos[1];
        this._positions[i * 3 + 2] = marker.worldPos[2];

        this._positionsDirty = true; // TODO: avoid reallocating VBO each time
    }

    /**
     * Removes a Marker from occlusion testing.
     * @param marker
     */
    removeMarker(marker) {
        delete this._markers[marker.id];
        this._markerListDirty = true;
    }

    /**
     * Prepares for an occlusion test.
     * Binds render buffer.
     */
    bindRenderBuf() {

        const shaderSourceHash = [this._scene.canvas.canvas.id, this._scene._sectionPlanesState.getHash()].join(";");
        if (shaderSourceHash !== this._shaderSourceHash) {
            this._shaderSourceHash = shaderSourceHash;
            this._shaderSourceDirty = true;
        }

        if (this._shaderSourceDirty) { // TODO: Set this when hash changes
            this._buildShaderSource();
            this._shaderSourceDirty = false;
            this._programDirty = true;
        }

        if (this._programDirty) {
            this._buildProgram();
            this._programDirty = false;
            this._occlusionTestListDirty = true;
        }

        if (this._markerListDirty) {
            this._buildMarkerList();
            this._markerListDirty = false;
            this._positionsDirty = true;
            this._occlusionTestListDirty = true;
        }

        if (this._positionsDirty) { //////////////  TODO: Don't rebuild this when positions change, very wasteful
            this._buildPositions();
            this._positionsDirty = false;
            this._vbosDirty = true;
        }

        if (this._vbosDirty) {
            this._buildVBOs();
            this._vbosDirty = false;
        }

        if (this._occlusionTestListDirty) {
            this._buildOcclusionTestList();
        }

        if (!TEST_MODE) {
            this._readPixelBuf = this._readPixelBuf || (this._readPixelBuf = new RenderBuffer(this._scene.canvas.canvas, this._scene.canvas.gl));
            this._readPixelBuf.bind();
            this._readPixelBuf.clear();
        }
    }

    _buildShaderSource() {
        this._shaderSource = {
            vertex: this._buildVertexShaderSource(),
            fragment: this._buildFragmentShaderSource()
        };
    }

    _buildVertexShaderSource() {
        const scene = this._scene;
        const clipping = scene._sectionPlanesState.sectionPlanes.length > 0;
        const src = [];
        src.push("// Mesh occlusion vertex shader");
        src.push("attribute vec3 position;");
        src.push("uniform mat4 modelMatrix;");
        src.push("uniform mat4 viewMatrix;");
        src.push("uniform mat4 projMatrix;");
        if (clipping) {
            src.push("varying vec4 vWorldPosition;");
        }
        src.push("void main(void) {");
        src.push("vec4 worldPosition = vec4(position, 1.0); ");
        src.push("   vec4 viewPosition = viewMatrix * worldPosition;");
        if (clipping) {
            src.push("   vWorldPosition = worldPosition;");
        }
        src.push("   gl_Position = projMatrix * viewPosition;");
        src.push("   gl_PointSize = " + POINT_SIZE + ".0;");
        src.push("}");
        return src;
    }

    _buildFragmentShaderSource() {
        const scene = this._scene;
        const sectionPlanesState = scene._sectionPlanesState;
        const clipping = sectionPlanesState.sectionPlanes.length > 0;
        const src = [];
        src.push("// Mesh occlusion fragment shader");
        src.push("precision lowp float;");
        if (clipping) {
            src.push("varying vec4 vWorldPosition;");
            for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
                src.push("uniform bool sectionPlaneActive" + i + ";");
                src.push("uniform vec3 sectionPlanePos" + i + ";");
                src.push("uniform vec3 sectionPlaneDir" + i + ";");
            }
        }
        src.push("void main(void) {");
        if (clipping) {
            src.push("  float dist = 0.0;");
            for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
                src.push("if (sectionPlaneActive" + i + ") {");
                src.push("   dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
                src.push("}");
            }
            src.push("  if (dist > 0.0) { discard; }");
        }
        src.push("   gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); ");
        src.push("}");
        return src;
    }

    _buildProgram() {
        if (this._program) {
            this._program.destroy();
        }
        const scene = this._scene;
        const gl = scene.canvas.gl;
        const sectionPlanesState = scene._sectionPlanesState;
        this._program = new Program(gl, this._shaderSource);
        if (this._program.errors) {
            this.errors = this._program.errors;
            return;
        }
        const program = this._program;
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
    }

    _buildMarkerList() {
        this._numMarkers = 0;
        for (var id in this._markers) {
            if (this._markers.hasOwnProperty(id)) {
                this._markerList[this._numMarkers] = this._markers[id];
                this._markerIndices[id] = this._numMarkers;
                this._numMarkers++;
            }
        }
        this._markerList.length = this._numMarkers;
    }

    _buildPositions() {
        var j = 0;
        for (var i = 0; i < this._numMarkers; i++) {
            if (this._markerList[i]) {
                const marker = this._markerList[i];
                const worldPos = marker.worldPos;
                this._positions[j++] = worldPos[0];
                this._positions[j++] = worldPos[1];
                this._positions[j++] = worldPos[2];
                this._indices[i] = i;
            }
        }
        this._positions.length = this._numMarkers * 3;
        this._indices.length = this._numMarkers;
    }

    _buildVBOs() {
        if (this._positionsBuf) {
            if (this._lenPositionsBuf === this._positions.length) { // Just updating buffer elements, don't need to reallocate
                this._positionsBuf.setData(this._positions); // Indices don't need updating
                return;
            }
            this._positionsBuf.destroy();
            this._positionsBuf = null;
            this._indicesBuf.destroy();
            this._indicesBuf = null;
        }
        const gl = this._scene.canvas.gl;
        const lenPositions = this._numMarkers * 3;
        const lenIndices = this._numMarkers;
        this._positionsBuf = new ArrayBuf(gl, gl.ARRAY_BUFFER, new Float32Array(this._positions), lenPositions, 3, gl.STATIC_DRAW);
        this._indicesBuf = new ArrayBuf(gl, gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(this._indices), lenIndices, 1, gl.STATIC_DRAW);
        this._lenPositionsBuf = this._positions.length;
    }

    _buildOcclusionTestList() {
        const canvas = this._scene.canvas;
        const near = this._scene.camera.perspective.near; // Assume near enough to ortho near
        let marker;
        let canvasPos;
        let viewPos;
        let canvasX;
        let canvasY;
        let lenPixels = 0;
        let i;
        const boundary = canvas.boundary;
        const canvasWidth = boundary[2];
        const canvasHeight = boundary[3];
        this._lenOcclusionTestList = 0;
        for (i = 0; i < this._numMarkers; i++) {
            marker = this._markerList[i];
            viewPos = marker.viewPos;
            if (viewPos[2] > -near) { // Clipped by near plane
                marker._setVisible(false);
                continue;
            }
            canvasPos = marker.canvasPos;
            canvasX = canvasPos[0];
            canvasY = canvasPos[1];
            if ((canvasX + 10) < 0 || (canvasY + 10) < 0 || (canvasX - 10) > canvasWidth || (canvasY - 10) > canvasHeight) {
                marker._setVisible(false);
                continue;
            }
            if (marker.entity && !marker.entity.visible) {
                marker._setVisible(false);
                continue;
            }
            if (marker.occludable) {
                this._occlusionTestList[this._lenOcclusionTestList++] = marker;
                this._pixels[lenPixels++] = canvasX;
                this._pixels[lenPixels++] = canvasY;
                continue;
            }
            marker._setVisible(true);
        }
    }

    /**
     * Draws {@link Marker}s to the render buffer.
     * @param frameCtx
     */
    drawMarkers(frameCtx) {
        const scene = this._scene;
        const gl = scene.canvas.gl;
        const program = this._program;
        const sectionPlanesState = scene._sectionPlanesState;
        const camera = scene.camera;
        const cameraState = camera._state;
        program.bind();
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
        gl.uniformMatrix4fv(this._uViewMatrix, false, cameraState.matrix);
        gl.uniformMatrix4fv(this._uProjMatrix, false, camera._project._state.matrix);
        this._aPosition.bindArrayBuffer(this._positionsBuf);
        this._indicesBuf.bind();
        gl.drawElements(gl.POINTS, this._indicesBuf.numItems, this._indicesBuf.itemType, 0);
    }

    /**
     * Reads render buffer and updates visibility states of {@link Marker}s if they can be found in the buffer.
     */
    doOcclusionTest() {
        if (!TEST_MODE) {
            const markerR = MARKER_COLOR[0] * 255;
            const markerG = MARKER_COLOR[1] * 255;
            const markerB = MARKER_COLOR[2] * 255;
            for (var i = 0; i < this._lenOcclusionTestList; i++) {
                const marker = this._occlusionTestList[i];
                const j = i * 2;
                const k = i * 4;
                const color = this._readPixelBuf.read(this._pixels[j], this._pixels[j + 1]);
                const visible = (color[0] === markerR) && (color[1] === markerG) && (color[2] === markerB);
                marker._setVisible(visible);
            }
        }
    }

    /**
     * Unbinds render buffer.
     */
    unbindRenderBuf() {
        if (!TEST_MODE) {
            this._readPixelBuf.unbind();
        }
    }

    /**
     * Destroys this OcclusionTester.
     */
    destroy() {
        this._markers = {};
        this._markerList.length = 0;

        if (this._positionsBuf) {
            this._positionsBuf.destroy();
        }
        if (this._indicesBuf) {
            this._indicesBuf.destroy();
        }
        if (this._program) {
            this._program.destroy();
        }
    }
}

export {OcclusionTester};