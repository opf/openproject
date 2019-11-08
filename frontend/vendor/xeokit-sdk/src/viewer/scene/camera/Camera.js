import {math} from '../math/math.js';
import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {Perspective} from './Perspective.js';
import {Ortho} from './Ortho.js';
import {Frustum} from './Frustum.js';
import {CustomProjection} from './CustomProjection.js';

const tempVec3 = math.vec3();
const tempVec3b = math.vec3();
const tempVec3c = math.vec3();
const tempVec3d = math.vec3();
const tempVec3e = math.vec3();
const tempVec3f = math.vec3();
const tempMat = math.mat4();
const tempMatb = math.mat4();
const eyeLookVec = math.vec3();
const eyeLookVecNorm = math.vec3();
const eyeLookOffset = math.vec3();
const offsetEye = math.vec3();

/**
 * @desc Manages viewing and projection transforms for its {@link Scene}.
 *
 * * One Camera per {@link Scene}
 * * Scene is located at {@link Viewer#scene} and Camera is located at {@link Scene#camera}
 * * Controls viewing and projection transforms
 * * Has methods to pan, zoom and orbit (or first-person rotation)
 * * Dynamically configurable World-space axis
 * * Has {@link Perspective}, {@link Ortho} and {@link Frustum} and {@link CustomProjection}, which you can dynamically switch it between
 * * Switchable gimbal lock
 * * Can be "flown" to look at targets using a {@link CameraFlightAnimation}
 * * Can be animated along a path using a {@link CameraPathAnimation}
 *
 * ## Getting the Camera
 *
 * There is exactly one Camera per {@link Scene}:
 *
 * ````javascript
 * import {Viewer} from "viewer/Viewer.js";
 *
 * var camera = viewer.scene.camera;
 *
 * ````
 *
 * ## Setting the Camera Position
 *
 * Get and set the Camera's absolute position via {@link Camera#eye}, {@link Camera#look} and {@link Camera#up}:
 *
 * ````javascript
 * camera.eye = [-10,0,0];
 * camera.look = [-10,0,0];
 * camera.up = [0,1,0];
 * ````
 *
 * ## Camera View and Projection Matrices
 *
 * The Camera's view matrix transforms coordinates from World-space to View-space.
 *
 * Getting the view matrix:
 *
 * ````javascript
 * var viewMatrix = camera.viewMatrix;
 * var viewNormalMatrix = camera.normalMatrix;
 * ````
 *
 * The Camera's view normal matrix transforms normal vectors from World-space to View-space.
 *
 * Getting the view normal matrix:
 *
 * ````javascript
 * var viewNormalMatrix = camera.normalMatrix;
 * ````
 *
 * The Camera fires a ````"viewMatrix"```` event whenever the {@link Camera#viewMatrix} and {@link Camera#viewNormalMatrix} updates.
 *
 * Listen for view matrix updates:
 *
 * ````javascript
 * camera.on("viewMatrix", function(matrix) { ... });
 * ````
 *
 * ## Rotating the Camera
 *
 * Orbiting the {@link Camera#look} position:
 *
 * ````javascript
 * camera.orbitYaw(20.0);
 * camera.orbitPitch(10.0);
 * ````
 *
 * First-person rotation, rotates {@link Camera#look} and {@link Camera#up} about {@link Camera#eye}:
 *
 * ````javascript
 * camera.yaw(5.0);
 * camera.pitch(-10.0);
 * ````
 *
 * ## Panning the Camera
 *
 * Panning along the Camera's local axis (ie. left/right, up/down, forward/backward):
 *
 * ````javascript
 * camera.pan([-20, 0, 10]);
 * ````
 *
 * ## Zooming the Camera
 *
 * Zoom to vary distance between {@link Camera#eye} and {@link Camera#look}:
 *
 * ````javascript
 * camera.zoom(-5); // Move five units closer
 * ````
 *
 * Get the current distance between {@link Camera#eye} and {@link Camera#look}:
 *
 * ````javascript
 * var distance = camera.eyeLookDist;
 * ````
 *
 * ## Projection
 *
 * The Camera has a Component to manage each projection type, which are: {@link Perspective}, {@link Ortho}
 * and {@link Frustum} and {@link CustomProjection}.
 *
 * You can configure those components at any time, regardless of which is currently active:
 *
 * The Camera has a {@link Perspective} to manage perspective
 * ````javascript
 *
 * // Set some properties on Perspective
 * camera.perspective.near = 0.4;
 * camera.perspective.fov = 45;
 *
 * // Set some properties on Ortho
 * camera.ortho.near = 0.8;
 * camera.ortho.far = 1000;
 *
 * // Set some properties on Frustum
 * camera.frustum.left = -1.0;
 * camera.frustum.right = 1.0;
 * camera.frustum.far = 1000.0;
 *
 * // Set the matrix property on CustomProjection
 * camera.customProjection.matrix = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
 *
 * // Switch between the projection types
 * camera.projection = "perspective"; // Switch to perspective
 * camera.projection = "frustum"; // Switch to frustum
 * camera.projection = "ortho"; // Switch to ortho
 * camera.projection = "customProjection"; // Switch to custom
 * ````
 *
 * Camera provides the projection matrix for the currently active projection in {@link Camera#projMatrix}.
 *
 * Get the projection matrix:
 *
 * ````javascript
 * var projMatrix = camera.projMatrix;
 * ````
 *
 * Listen for projection matrix updates:
 *
 * ````javascript
 * camera.on("projMatrix", function(matrix) { ... });
 * ````
 *
 * ## Configuring World up direction
 *
 * We can dynamically configure the directions of the World-space coordinate system.
 *
 * Setting the +Y axis as World "up", +X as right and -Z as forwards (convention in some modeling software):
 *
 * ````javascript
 * camera.worldAxis = [
 *     1, 0, 0,    // Right
 *     0, 1, 0,    // Up
 *     0, 0,-1     // Forward
 * ];
 * ````
 *
 * Setting the +Z axis as World "up", +X as right and -Y as "up" (convention in most CAD and BIM viewers):
 *
 * ````javascript
 * camera.worldAxis = [
 *     1, 0, 0, // Right
 *     0, 0, 1, // Up
 *     0,-1, 0  // Forward
 * ];
 * ````
 *
 * The Camera has read-only convenience properties that provide each axis individually:
 *
 * ````javascript
 * var worldRight = camera.worldRight;
 * var worldForward = camera.worldForward;
 * var worldUp = camera.worldUp;
 * ````
 *
 * ### Gimbal locking
 *
 * By default, the Camera locks yaw rotation to pivot about the World-space "up" axis. We can dynamically lock and unlock that at any time:
 *
 * ````javascript
 * camera.gimbalLock = false; // Yaw rotation now happens about Camera's local Y-axis
 * camera.gimbalLock = true; // Yaw rotation now happens about World's "up" axis
 * ````
 *
 * See: <a href="https://en.wikipedia.org/wiki/Gimbal_lock">https://en.wikipedia.org/wiki/Gimbal_lock</a>
 */
class Camera extends Component {

    /**
     @private
     */
    get type() {
        return "Camera";
    }

    /**
     * @constructor
     * @private
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            deviceMatrix: math.mat4(),
            hasDeviceMatrix: false, // True when deviceMatrix set to other than identity
            matrix: math.mat4(),
            normalMatrix: math.mat4()
        });

        this._perspective = new Perspective(this);
        this._ortho = new Ortho(this);
        this._frustum = new Frustum(this);
        this._customProjection = new CustomProjection(this);
        this._project = this._perspective;

        this._eye = math.vec3([0, 0, 10.0]);
        this._look = math.vec3([0, 0, 0]);
        this._up = math.vec3([0, 1, 0]);

        this._worldUp = math.vec3([0, 1, 0]);
        this._worldRight = math.vec3([1, 0, 0]);
        this._worldForward = math.vec3([0, 0, -1]);

        this.deviceMatrix = cfg.deviceMatrix;
        this.eye = cfg.eye;
        this.look = cfg.look;
        this.up = cfg.up;
        this.worldAxis = cfg.worldAxis;
        this.gimbalLock = cfg.gimbalLock;
        this.constrainPitch = cfg.constrainPitch;

        this.projection = cfg.projection;

        this._perspective.on("matrix", () => {
            if (this._projectionType === "perspective") {
                this.fire("projMatrix", this._perspective.matrix);
            }
        });
        this._ortho.on("matrix", () => {
            if (this._projectionType === "ortho") {
                this.fire("projMatrix", this._ortho.matrix);
            }
        });
        this._frustum.on("matrix", () => {
            if (this._projectionType === "frustum") {
                this.fire("projMatrix", this._frustum.matrix);
            }
        });
        this._customProjection.on("matrix", () => {
            if (this._projectionType === "customProjection") {
                this.fire("projMatrix", this._customProjection.matrix);
            }
        });
    }

    _update() {
        const state = this._state;
        // In ortho mode, build the view matrix with an eye position that's translated
        // well back from look, so that the front sectionPlane plane doesn't unexpectedly cut
        // the front off the view (not a problem with perspective, since objects close enough
        // to be clipped by the front plane are usually too big to see anything of their cross-sections).
        let eye;
        if (this.projection === "ortho") {
            math.subVec3(this._eye, this._look, eyeLookVec);
            math.normalizeVec3(eyeLookVec, eyeLookVecNorm);
            math.mulVec3Scalar(eyeLookVecNorm, 1000.0, eyeLookOffset);
            math.addVec3(this._look, eyeLookOffset, offsetEye);
            eye = offsetEye;
        } else {
            eye = this._eye;
        }
        if (state.hasDeviceMatrix) {
            math.lookAtMat4v(eye, this._look, this._up, tempMatb);
            math.mulMat4(state.deviceMatrix, tempMatb, state.matrix);
            //state.matrix.set(state.deviceMatrix);
        } else {
            math.lookAtMat4v(eye, this._look, this._up, state.matrix);
        }
        math.inverseMat4(this._state.matrix, this._state.normalMatrix);
        math.transposeMat4(this._state.normalMatrix);
        this.glRedraw();
        this.fire("matrix", this._state.matrix);
        this.fire("viewMatrix", this._state.matrix);
    }

    /**
     * Rotates {@link Camera#eye} about {@link Camera#look}, around the {@link Camera#up} vector
     *
     * @param {Number} angleInc Angle of rotation in degrees
     */
    orbitYaw(angleInc) {
        let lookEyeVec = math.subVec3(this._eye, this._look, tempVec3);
        math.rotationMat4v(angleInc * 0.0174532925, this._gimbalLock ? this._worldUp : this._up, tempMat);
        lookEyeVec = math.transformPoint3(tempMat, lookEyeVec, tempVec3b);
        this.eye = math.addVec3(this._look, lookEyeVec, tempVec3c); // Set eye position as 'look' plus 'eye' vector
        this.up = math.transformPoint3(tempMat, this._up, tempVec3d); // Rotate 'up' vector
    }

    /**
     * Rotates {@link Camera#eye} about {@link Camera#look} around the right axis (orthogonal to {@link Camera#up} and "look").
     *
     * @param {Number} angleInc Angle of rotation in degrees
     */
    orbitPitch(angleInc) {
        if (this._constrainPitch) {
            angleInc = math.dotVec3(this._up, this._worldUp) / math.DEGTORAD;
            if (angleInc < 1) {
                return;
            }
        }
        let eye2 = math.subVec3(this._eye, this._look, tempVec3);
        const left = math.cross3Vec3(math.normalizeVec3(eye2, tempVec3b), math.normalizeVec3(this._up, tempVec3c));
        math.rotationMat4v(angleInc * 0.0174532925, left, tempMat);
        eye2 = math.transformPoint3(tempMat, eye2, tempVec3d);
        this.up = math.transformPoint3(tempMat, this._up, tempVec3e);
        this.eye = math.addVec3(eye2, this._look, tempVec3f);
    }

    /**
     * Rotates {@link Camera#look} about {@link Camera#eye}, around the {@link Camera#up} vector.
     *
     * @param {Number} angleInc Angle of rotation in degrees
     */
    yaw(angleInc) {
        let look2 = math.subVec3(this._look, this._eye, tempVec3);
        math.rotationMat4v(angleInc * 0.0174532925, this._gimbalLock ? this._worldUp : this._up, tempMat);
        look2 = math.transformPoint3(tempMat, look2, tempVec3b);
        this.look = math.addVec3(look2, this._eye, tempVec3c);
        if (this._gimbalLock) {
            this.up = math.transformPoint3(tempMat, this._up, tempVec3d);
        }
    }

    /**
     * Rotates {@link Camera#look} about {@link Camera#eye}, around the right axis (orthogonal to {@link Camera#up} and "look").

     * @param {Number} angleInc Angle of rotation in degrees
     */
    pitch(angleInc) {
        if (this._constrainPitch) {
            angleInc = math.dotVec3(this._up, this._worldUp) / math.DEGTORAD;
            if (angleInc < 1) {
                return;
            }
        }
        let look2 = math.subVec3(this._look, this._eye, tempVec3);
        const left = math.cross3Vec3(math.normalizeVec3(look2, tempVec3b), math.normalizeVec3(this._up, tempVec3c));
        math.rotationMat4v(angleInc * 0.0174532925, left, tempMat);
        this.up = math.transformPoint3(tempMat, this._up, tempVec3f);
        look2 = math.transformPoint3(tempMat, look2, tempVec3d);
        this.look = math.addVec3(look2, this._eye, tempVec3e);
    }

    /**
     * Pans the Camera along its local X, Y and Z axis.
     *
     * @param pan The pan vector
     */
    pan(pan) {
        const eye2 = math.subVec3(this._eye, this._look, tempVec3);
        const vec = [0, 0, 0];
        let v;
        if (pan[0] !== 0) {
            const left = math.cross3Vec3(math.normalizeVec3(eye2, []), math.normalizeVec3(this._up, tempVec3b));
            v = math.mulVec3Scalar(left, pan[0]);
            vec[0] += v[0];
            vec[1] += v[1];
            vec[2] += v[2];
        }
        if (pan[1] !== 0) {
            v = math.mulVec3Scalar(math.normalizeVec3(this._up, tempVec3c), pan[1]);
            vec[0] += v[0];
            vec[1] += v[1];
            vec[2] += v[2];
        }
        if (pan[2] !== 0) {
            v = math.mulVec3Scalar(math.normalizeVec3(eye2, tempVec3d), pan[2]);
            vec[0] += v[0];
            vec[1] += v[1];
            vec[2] += v[2];
        }
        this.eye = math.addVec3(this._eye, vec, tempVec3e);
        this.look = math.addVec3(this._look, vec, tempVec3f);
    }

    /**
     * Increments/decrements the Camera's zoom factor, which is the distance between {@link Camera#eye} and {@link Camera#look}.
     *
     * @param {Number} delta Zoom factor increment.
     */
    zoom(delta) {
        const vec = math.subVec3(this._eye, this._look, tempVec3);
        const lenLook = Math.abs(math.lenVec3(vec, tempVec3b));
        const newLenLook = Math.abs(lenLook + delta);
        if (newLenLook < 0.5) {
            return;
        }
        const dir = math.normalizeVec3(vec, tempVec3c);
        this.eye = math.addVec3(this._look, math.mulVec3Scalar(dir, newLenLook), tempVec3d);
    }

    /**
     * Sets the position of the Camera's eye.
     *
     * Default value is ````[0,0,10]````.
     *
     * @emits "eye" event on change, with the value of this property.
     * @type {Number[]} New eye position.
     */
    set eye(eye) {
        this._eye.set(eye || [0, 0, 10]);
        this._needUpdate(0); // Ensure matrix built on next "tick"
        this.fire("eye", this._eye);
    }

    /**
     * Gets the position of the Camera's eye.
     *
     * Default vale is ````[0,0,10]````.
     *
     * @type {Number[]} New eye position.
     */
    get eye() {
        return this._eye;
    }

    /**
     * Sets the position of this Camera's point-of-interest.
     *
     * Default value is ````[0,0,0]````.
     *
     * @emits "look" event on change, with the value of this property.
     *
     * @param {Number[]} look Camera look position.
     */
    set look(look) {
        this._look.set(look || [0, 0, 0]);
        this._needUpdate(0); // Ensure matrix built on next "tick"
        this.fire("look", this._look);
    }

    /**
     * Gets the position of this Camera's point-of-interest.
     *
     * Default value is ````[0,0,0]````.
     *
     * @returns {Number[]} Camera look position.
     */
    get look() {
        return this._look;
    }

    /**
     * Sets the direction of this Camera's {@link Camera#up} vector.
     *
     * @emits "up" event on change, with the value of this property.
     *
     * @param {Number[]} up Direction of "up".
     */
    set up(up) {
        this._up.set(up || [0, 1, 0]);
        this._needUpdate(0);
        this.fire("up", this._up);
    }

    /**
     * Gets the direction of this Camera's {@link Camera#up} vector.
     *
     * @returns {Number[]} Direction of "up".
     */
    get up() {
        return this._up;
    }

    /**
     * Sets an optional matrix to premultiply into {@link Camera#matrix} matrix.
     *
     * This is intended to be used for stereo rendering with WebVR etc.
     *
     * @param {Number[]} matrix The matrix.
     */
    set deviceMatrix(matrix) {
        this._state.deviceMatrix.set(matrix || [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
        this._state.hasDeviceMatrix = !!matrix;
        this._needUpdate(0);

        /**
         Fired whenever this CustomProjection's {@link CustomProjection/matrix} property changes.

         @event deviceMatrix
         @param value The property's new value
         */
        this.fire("deviceMatrix", this._state.deviceMatrix);
    }

    /**
     * Gets an optional matrix to premultiply into {@link Camera#matrix} matrix.
     *
     * @returns {Number[]} The matrix.
     */
    get deviceMatrix() {
        return this._state.deviceMatrix;
    }

    /**
     * Sets the up, right and forward axis of the World coordinate system.
     *
     * Has format: ````[rightX, rightY, rightZ, upX, upY, upZ, forwardX, forwardY, forwardZ]````
     *
     * Default axis is ````[1, 0, 0, 0, 1, 0, 0, 0, 1]````
     *
     * @param {Number[]} axis The new Wworld coordinate axis.
     */
    set worldAxis(axis) {
        axis = axis || [1, 0, 0, 0, 1, 0, 0, 0, 1];
        if (!this._worldAxis) {
            this._worldAxis = new Float32Array(axis);
        } else {
            this._worldAxis.set(axis);
        }
        this._worldRight[0] = this._worldAxis[0];
        this._worldRight[1] = this._worldAxis[1];
        this._worldRight[2] = this._worldAxis[2];
        this._worldUp[0] = this._worldAxis[3];
        this._worldUp[1] = this._worldAxis[4];
        this._worldUp[2] = this._worldAxis[5];
        this._worldForward[0] = this._worldAxis[6];
        this._worldForward[1] = this._worldAxis[7];
        this._worldForward[2] = this._worldAxis[8];

        /**
         * Fired whenever this Camera's {@link Camera#worldAxis} property changes.
         *
         * @event worldAxis
         * @param axis The property's new axis
         */
        this.fire("worldAxis", this._worldAxis);
    }

    /**
     * Gets the up, right and forward axis of the World coordinate system.
     *
     * Has format: ````[rightX, rightY, rightZ, upX, upY, upZ, forwardX, forwardY, forwardZ]````
     *
     * Default axis is ````[1, 0, 0, 0, 1, 0, 0, 0, 1]````
     *
     * @returns {Number[]} The current World coordinate axis.
     */
    get worldAxis() {
        return this._worldAxis;
    }

    /**
     * Gets the direction of World-space "up".
     *
     * This is set by {@link Camera#worldAxis}.
     *
     * Default value is ````[0,1,0]````.
     *
     * @returns {Number[]} The "up" vector.
     */
    get worldUp() {
        return this._worldUp;
    }

    /**
     * Gets if the World-space X-axis is "up".
     * @returns {boolean}
     */
    get xUp() {
        return this._worldUp[0] > this._worldUp[1] && this._worldUp[0] > this._worldUp[2];
    }

    /**
     * Gets if the World-space Y-axis is "up".
     * @returns {boolean}
     */
    get yUp() {
        return this._worldUp[1] > this._worldUp[0] && this._worldUp[1] > this._worldUp[2];
    }

    /**
     * Gets if the World-space Z-axis is "up".
     * @returns {boolean}
     */
    get zUp() {
        return this._worldUp[2] > this._worldUp[0] && this._worldUp[2] > this._worldUp[1];
    }

    /**
     * Gets the direction of World-space "right".
     *
     * This is set by {@link Camera#worldAxis}.
     *
     * Default value is ````[1,0,0]````.
     *
     * @returns {Number[]} The "up" vector.
     */
    get worldRight() {
        return this._worldRight;
    }

    /**
     * Gets the direction of World-space "forwards".
     *
     * This is set by {@link Camera#worldAxis}.
     *
     * Default value is ````[0,0,1]````.
     *
     * @returns {Number[]} The "up" vector.
     */
    get worldForward() {
        return this._worldForward;
    }

    /**
     * Sets whether to lock yaw rotation to pivot about the World-space "up" axis.
     *
     * Fires a {@link Camera#gimbalLock:event} event on change.
     *
     * @params {Boolean} gimbalLock Set true to lock gimbal.
     */
    set gimbalLock(value) {
        this._gimbalLock = value !== false;

        /**
         Fired whenever this Camera's  {@link Camera#gimbalLock} property changes.

         @event gimbalLock
         @param value The property's new value
         */
        this.fire("gimbalLock", this._gimbalLock);
    }

    /**
     * Gets whether to lock yaw rotation to pivot about the World-space "up" axis.
     *
     * @returns {Boolean} Returns ````true```` if gimbal is locked.
     */
    get gimbalLock() {
        return this._gimbalLock;
    }

    /**
     * Sets whether to prevent camera from being pitched upside down.
     *
     * The camera is upside down when the angle between {@link Camera#up} and {@link Camera#worldUp} is less than one degree.
     *
     * Fires a {@link Camera#constrainPitch:event} event on change.
     *
     * Default value is ````false````.
     *
     * @param {Boolean} value Set ````true```` to contrain pitch rotation.
     */
    set constrainPitch(value) {
        this._constrainPitch = !!value;

        /**
         Fired whenever this Camera's  {@link Camera#constrainPitch} property changes.

         @event constrainPitch
         @param value The property's new value
         */
        this.fire("constrainPitch", this._constrainPitch);
    }

    /**
     * Gets whether to prevent camera from being pitched upside down.
     *
     * The camera is upside down when the angle between {@link Camera#up} and {@link Camera#worldUp} is less than one degree.
     *
     * Default value is ````false````.
     *
     * @returns {Boolean} ````true```` if pitch rotation is currently constrained.
     get constrainPitch() {
        return this._constrainPitch;
    }

     /**
     * Gets distance from {@link Camera#look} to {@link Camera#eye}.
     *
     * @returns {Number} The distance.
     */
    get eyeLookDist() {
        return math.lenVec3(math.subVec3(this._look, this._eye, tempVec3));
    }

    /**
     * Gets the Camera's viewing transformation matrix.
     *
     * Fires a {@link Camera#matrix:event} event on change.
     *
     * @returns {Number[]} The viewing transform matrix.
     */
    get matrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.matrix;
    }

    /**
     * Gets the Camera's viewing transformation matrix.
     *
     * Fires a {@link Camera#matrix:event} event on change.
     *
     * @returns {Number[]} The viewing transform matrix.
     */
    get viewMatrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.matrix;
    }

    /**
     * The Camera's viewing normal transformation matrix.
     *
     * Fires a {@link Camera#matrix:event} event on change.
     *
     * @returns {Number[]} The viewing normal transform matrix.
     */
    get normalMatrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.normalMatrix;
    }

    /**
     * The Camera's viewing normal transformation matrix.
     *
     * Fires a {@link Camera#matrix:event} event on change.
     *
     * @returns {Number[]} The viewing normal transform matrix.
     */
    get viewNormalMatrix() {
        if (this._updateScheduled) {
            this._doUpdate();
        }
        return this._state.normalMatrix;
    }

    /**
     * Gets the Camera's projection transformation projMatrix.
     *
     * Fires a {@link Camera#projMatrix:event} event on change.
     *
     * @returns {Number[]} The projection matrix.
     */
    get projMatrix() {
        return this[this.projection].matrix;
    }

    /**
     * Gets the Camera's perspective projection.
     *
     * The Camera uses this while {@link Camera#projection} equals ````perspective````.
     *
     * @returns {Perspective} The Perspective component.
     */
    get perspective() {
        return this._perspective;
    }

    /**
     * Gets the Camera's orthographic projection.
     *
     * The Camera uses this while {@link Camera#projection} equals ````ortho````.
     *
     * @returns {Ortho} The Ortho component.
     */
    get ortho() {
        return this._ortho;
    }

    /**
     * Gets the Camera's frustum projection.
     *
     * The Camera uses this while {@link Camera#projection} equals ````frustum````.
     *
     * @returns {Frustum} The Ortho component.
     */
    get frustum() {
        return this._frustum;
    }

    /**
     * Gets the Camera's custom projection.
     *
     * This is used while {@link Camera#projection} equals "customProjection".
     *
     * @returns {CustomProjection} The custom projection.
     */
    get customProjection() {
        return this._customProjection;
    }

    /**
     * Sets the active projection type.
     *
     * Accepted values are ````"perspective"````, ````"ortho"````, ````"frustum"```` and ````"customProjection"````.
     *
     * Default value is ````"perspective"````.
     *
     * @param {String} value Identifies the active projection type.
     */
    set projection(value) {
        value = value || "perspective";
        if (this._projectionType === value) {
            return;
        }
        if (value === "perspective") {
            this._project = this._perspective;
        } else if (value === "ortho") {
            this._project = this._ortho;
        } else if (value === "frustum") {
            this._project = this._frustum;
        } else if (value === "customProjection") {
            this._project = this._customProjection;
        } else {
            this.error("Unsupported value for 'projection': " + value + " defaulting to 'perspective'");
            this._project = this._perspective;
            value = "perspective";
        }
        this._project._update();
        this._projectionType = value;
        this.glRedraw();
        this._update(); // Need to rebuild lookat matrix with full eye, look & up
        this.fire("dirty");
        /**
         Fired whenever this Camera's  {@link Camera#projection} property changes.

         @event projection
         @param value The property's new value
         */
        this.fire("projection",  this._projectionType);
    }

    /**
     * Gets the active projection type.
     *
     * Possible values are ````"perspective"````, ````"ortho"````, ````"frustum"```` and ````"customProjection"````.
     *
     * Default value is ````"perspective"````.
     *
     * @returns {String} Identifies the active projection type.
     */
    get projection() {
        return this._projectionType;
    }

    /**
     * Gets the currently active projection for this Camera.
     *
     * The currently active project is selected with {@link Camera#projection}.
     *
     * @returns {Perspective|Ortho|Frustum|CustomProjection} The currently active projection is active.
     */
    get project() {
        return this._project;
    }

    /**
     * Destroys this Camera.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {Camera};
