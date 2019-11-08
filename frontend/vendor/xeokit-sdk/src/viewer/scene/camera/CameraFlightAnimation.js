import {math} from '../math/math.js';
import {utils} from '../utils.js';
import {core} from '../core.js';
import {Component} from '../Component.js';

const tempVec3 = math.vec3();
const newLook = math.vec3();
const newEye = math.vec3();
const newUp = math.vec3();
const newLookEyeVec = math.vec3();

/**
 * @desc Jumps or flies the {@link Scene}'s {@link Camera} to a given target.
 *
 * * Located at {@link Viewer#cameraFlight}
 * * Can fly or jump to its target.
 * * While flying, can be stopped, or redirected to a different target.
 * * Can also smoothly transition between ortho and perspective projections.
 *
 *
 * A CameraFlightAnimation's target can be:
 *
 * * specific ````eye````, ````look```` and ````up```` positions,
 * * an axis-aligned World-space bounding box (AABB), or
 * * an instance or ID of any {@link Component} subtype that provides a World-space AABB.
 *
 * A target can also contain a ````projection```` type to transition into. For example, if your {@link Camera#projection} is
 * currently ````"perspective"```` and you supply {@link CameraFlightAnimation#flyTo} with a ````projection```` property
 * equal to "ortho", then CameraFlightAnimation will smoothly transition the Camera into an orthographic projection.
 *
 * Configure {@link CameraFlightAnimation#fit} and {@link CameraFlightAnimation#fitFOV} to make it stop at the point
 * where the target occupies a certain amount of the field-of-view.
 *
 * ## Flying to an Entity
 *
 * Flying to an {@link Entity}:
 *
 * ````Javascript
 * var entity = new Mesh(viewer.scene);
 *
 * // Fly to the Entity's World-space AABB
 * viewer.cameraFlight.flyTo(entity);
 * ````
 * ## Flying to a Position
 *
 * Flying the CameraFlightAnimation from the previous example to specified eye, look and up positions:
 *
 * ````Javascript
 * viewer.cameraFlight.flyTo({
 *    eye: [-5,-5,-5],
 *    look: [0,0,0]
 *    up: [0,1,0],
 *    duration: 1 // Default, seconds
 * },() => {
 *      // Done
 * });
 * ````
 *
 * ## Flying to an AABB
 *
 * Flying the CameraFlightAnimation from the previous two examples explicitly to the {@link Boundary3D"}}Boundary3D's{{/crossLink}}
 * axis-aligned bounding box:
 *
 * ````Javascript
 * viewer.cameraFlight.flyTo(entity.aabb);
 * ````
 *
 * ## Transitioning Between Projections
 *
 * CameraFlightAnimation also allows us to smoothly transition between Camera projections. We can do that by itself, or
 * in addition to flying the Camera to a target.
 *
 * Let's transition the Camera to orthographic projection:
 *
 * [[Run example](http://xeokit.github.io/xeokit-sdk/examples/#camera_CameraFlightAnimation_projection)]
 *
 * ````Javascript
 * viewer.cameraFlight.flyTo({ projection: "ortho", () => {
 *      // Done
 * });
 * ````
 *
 * Now let's transition the Camera back to perspective projection:
 *
 * ````Javascript
 * viewer.cameraFlight.flyTo({ projection: "perspective"}, () => {
 *      // Done
 * });
 * ````
 *
 * Fly Camera to a position, while transitioning to orthographic projection:
 *
 * ````Javascript
 * viewer.cameraFlight.flyTo({
 *     eye: [-100,20,2],
 *     look: [0,0,-40],
 *     up: [0,1,0],
 *     projection: "ortho", () => {
 *        // Done
 * });
 * ````
 */
class CameraFlightAnimation extends Component {

    /**
     * @private
     */
    get type() {
        return "CameraFlightAnimation";
    }

    /**
     @constructor
     @private
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._look1 = math.vec3();
        this._eye1 = math.vec3();
        this._up1 = math.vec3();
        this._look2 = math.vec3();
        this._eye2 = math.vec3();
        this._up2 = math.vec3();
        this._orthoScale1 = 1;
        this._orthoScale2 = 1;
        this._flying = false;
        this._flyEyeLookUp = false;
        this._flyingEye = false;
        this._flyingLook = false;
        this._callback = null;
        this._callbackScope = null;
        this._time1 = null;
        this._time2 = null;
        this.easing = cfg.easing !== false;

        this.duration = cfg.duration;
        this.fit = cfg.fit;
        this.fitFOV = cfg.fitFOV;
        this.trail = cfg.trail;
    }

    /**
     * Flies the {@link Camera} to a target.
     *
     *  * When the target is a boundary, the {@link Camera} will fly towards the target and stop when the target fills most of the canvas.
     *  * When the target is an explicit {@link Camera} position, given as ````eye````, ````look```` and ````up````, then CameraFlightAnimation will interpolate the {@link Camera} to that target and stop there.
     *
     * @param {Object|Component} [params=Scene] Either a parameters object or a {@link Component} subtype that has
     * an AABB. Defaults to the {@link Scene}, which causes the {@link Camera} to fit the Scene in view.
     * @param {Number} [params.arc=0] Factor in range ````[0..1]```` indicating how much the {@link Camera#eye} position
     * will swing away from its {@link Camera#look} position as it flies to the target.
     * @param {Number|String|Component} [params.component] ID or instance of a component to fly to. Defaults to the entire {@link Scene}.
     * @param {Number[]} [params.aabb] World-space axis-aligned bounding box (AABB) target to fly to.
     * @param {Number[]} [params.eye] Position to fly the eye position to.
     * @param {Number[]} [params.look] Position to fly the look position to.
     * @param {Number[]} [params.up] Position to fly the up vector to.
     * @param {String} [params.projection] Projection type to transition into as we fly. Can be any of the values of {@link Camera.projection}.
     * @param {Boolean} [params.fit=true] Whether to fit the target to the view volume. Overrides {@link CameraFlightAnimation#fit}.
     * @param {Number} [params.fitFOV] How much of field-of-view, in degrees, that a target {@link Entity} or its AABB should
     * fill the canvas on arrival. Overrides {@link CameraFlightAnimation#fitFOV}.
     * @param {Number} [params.duration] Flight duration in seconds.  Overrides {@link CameraFlightAnimation#duration}.
     * @param {Number} [params.orthoScale] Animate the Camera's orthographic scale to this target value. See {@link Ortho#scale}.
     * @param {Function} [callback] Callback fired on arrival.
     * @param {Object} [scope] Optional scope for callback.
     */
    flyTo(params, callback, scope) {

        params = params || this.scene;

        if (this._flying) {
            this.stop();
        }

        this._flying = false;
        this._flyingEye = false;
        this._flyingLook = false;
        this._flyingEyeLookUp = false;

        this._callback = callback;
        this._callbackScope = scope;

        const camera = this.scene.camera;
        const flyToProjection = (!!params.projection) && (params.projection !== camera.projection);

        this._eye1[0] = camera.eye[0];
        this._eye1[1] = camera.eye[1];
        this._eye1[2] = camera.eye[2];

        this._look1[0] = camera.look[0];
        this._look1[1] = camera.look[1];
        this._look1[2] = camera.look[2];

        this._up1[0] = camera.up[0];
        this._up1[1] = camera.up[1];
        this._up1[2] = camera.up[2];

        this._orthoScale1 = camera.ortho.scale;
        this._orthoScale2 = params.orthoScale || this._orthoScale1;

        let aabb;
        let eye;
        let look;
        let up;
        let componentId;

        if (params.aabb) {
            aabb = params.aabb;

        } else if (params.length === 6) {
            aabb = params;

        } else if ((params.eye && params.look) || params.up) {
            eye = params.eye;
            look = params.look;
            up = params.up;

        } else if (params.eye) {
            eye = params.eye;

        } else if (params.look) {
            look = params.look;

        } else { // Argument must be an instance or ID of a Component (subtype)

            let component = params;

            if (utils.isNumeric(component) || utils.isString(component)) {

                componentId = component;
                component = this.scene.components[componentId];

                if (!component) {
                    this.error("Component not found: " + utils.inQuotes(componentId));
                    if (callback) {
                        if (scope) {
                            callback.call(scope);
                        } else {
                            callback();
                        }
                    }
                    return;
                }
            }
            if (!flyToProjection) {
                aabb = component.aabb || this.scene.aabb;
            }
        }

        const poi = params.poi;

        if (aabb) {

            if (aabb[3] < aabb[0] || aabb[4] < aabb[1] || aabb[5] < aabb[2]) { // Don't fly to an inverted boundary
                return;
            }

            if (aabb[3] === aabb[0] && aabb[4] === aabb[1] && aabb[5] === aabb[2]) { // Don't fly to an empty boundary
                return;
            }

            aabb = aabb.slice();
            const aabbCenter = math.getAABB3Center(aabb);

            this._look2 = poi || aabbCenter;

            const eyeLookVec = math.subVec3(this._eye1, this._look1, tempVec3);
            const eyeLookVecNorm = math.normalizeVec3(eyeLookVec);
            const diag = poi ? math.getAABB3DiagPoint(aabb, poi) : math.getAABB3Diag(aabb);
            const fitFOV = params.fitFOV || this._fitFOV;
            const sca = Math.abs(diag / Math.tan(fitFOV * math.DEGTORAD));

            this._orthoScale2 = diag * 1.1;

            this._eye2[0] = this._look2[0] + (eyeLookVecNorm[0] * sca);
            this._eye2[1] = this._look2[1] + (eyeLookVecNorm[1] * sca);
            this._eye2[2] = this._look2[2] + (eyeLookVecNorm[2] * sca);

            this._up2[0] = this._up1[0];
            this._up2[1] = this._up1[1];
            this._up2[2] = this._up1[2];

            this._flyingEyeLookUp = true;

        } else if (eye || look || up) {

            this._flyingEyeLookUp = !!eye && !!look && !!up;
            this._flyingEye = !!eye && !look;
            this._flyingLook = !!look && !eye;

            if (eye) {
                this._eye2[0] = eye[0];
                this._eye2[1] = eye[1];
                this._eye2[2] = eye[2];
            }

            if (look) {
                this._look2[0] = look[0];
                this._look2[1] = look[1];
                this._look2[2] = look[2];
            }

            if (up) {
                this._up2[0] = up[0];
                this._up2[1] = up[1];
                this._up2[2] = up[2];
            }
        }

        if (flyToProjection) {

            if (params.projection === "ortho" && camera.projection !== "ortho") {
                this._projection2 = "ortho";
                this._projMatrix1 = camera.projMatrix.slice();
                camera.ortho.scale = this._orthoScale2;
                this._projMatrix2 = camera.ortho.matrix.slice();
                camera.projection = "customProjection";
            }

            if (params.projection === "perspective" && camera.projection !== "perspective") {
                this._projection2 = "perspective";
                this._projMatrix1 = camera.projMatrix.slice();
                this._projMatrix2 = camera.perspective.matrix.slice();
                camera.projection = "customProjection";
            }
        }

        this.fire("started", params, true);

        this._time1 = Date.now();
        this._time2 = this._time1 + (params.duration ? params.duration * 1000 : this._duration);

        this._flying = true; // False as soon as we stop

        core.scheduleTask(this._update, this);
    }

    /**
     * Jumps the {@link Scene}'s {@link Camera} to the given target.
     *
     * * When the target is a boundary, this CameraFlightAnimation will position the {@link Camera} at where the target fills most of the canvas.
     * * When the target is an explicit {@link Camera} position, given as ````eye````, ````look```` and ````up```` vectors, then this CameraFlightAnimation will jump the {@link Camera} to that target.
     *
     * @param {*|Component} params  Either a parameters object or a {@link Component} subtype that has a World-space AABB.
     * @param {Number} [params.arc=0]  Factor in range [0..1] indicating how much the {@link Camera#eye} will swing away from its {@link Camera#look} as it flies to the target.
     * @param {Number|String|Component} [params.component] ID or instance of a component to fly to.
     * @param {Number[]} [params.aabb]  World-space axis-aligned bounding box (AABB) target to fly to.
     * @param {Number[]} [params.eye] Position to fly the eye position to.
     * @param {Number[]} [params.look]  Position to fly the look position to.
     * @param {Number[]} [params.up] Position to fly the up vector to.
     * @param {String} [params.projection] Projection type to transition into. Can be any of the values of {@link Camera.projection}.
     * @param {Number} [params.fitFOV] How much of field-of-view, in degrees, that a target {@link Entity} or its AABB should fill the canvas on arrival. Overrides {@link CameraFlightAnimation#fitFOV}.
     * @param {Boolean} [params.fit] Whether to fit the target to the view volume. Overrides {@link CameraFlightAnimation#fit}.
     */
    jumpTo(params) {
        this._jumpTo(params);
    }

    _jumpTo(params) {

        if (this._flying) {
            this.stop();
        }

        const camera = this.scene.camera;

        var aabb;
        var componentId;
        var newEye;
        var newLook;
        var newUp;

        if (params.aabb) { // Boundary3D
            aabb = params.aabb;

        } else if (params.length === 6) { // AABB
            aabb = params;

        } else if (params.eye || params.look || params.up) { // Camera pose
            newEye = params.eye;
            newLook = params.look;
            newUp = params.up;

        } else { // Argument must be an instance or ID of a Component (subtype)

            let component = params;

            if (utils.isNumeric(component) || utils.isString(component)) {
                componentId = component;
                component = this.scene.components[componentId];
                if (!component) {
                    this.error("Component not found: " + utils.inQuotes(componentId));
                    return;
                }
            }
            aabb = component.aabb || this.scene.aabb;
        }

        const poi = params.poi;

        if (aabb) {

            if (aabb[3] <= aabb[0] || aabb[4] <= aabb[1] || aabb[5] <= aabb[2]) { // Don't fly to an empty boundary
                return;
            }

            var diag = poi ? math.getAABB3DiagPoint(aabb, poi) : math.getAABB3Diag(aabb);

            newLook = poi || math.getAABB3Center(aabb, newLook);

            if (this._trail) {
                math.subVec3(camera.look, newLook, newLookEyeVec);
            } else {
                math.subVec3(camera.eye, camera.look, newLookEyeVec);
            }

            math.normalizeVec3(newLookEyeVec);
            let dist;
            const fit = (params.fit !== undefined) ? params.fit : this._fit;

            if (fit) {
                dist = Math.abs((diag) / Math.tan((params.fitFOV || this._fitFOV) * math.DEGTORAD));

            } else {
                dist = math.lenVec3(math.subVec3(camera.eye, camera.look, tempVec3));
            }

            math.mulVec3Scalar(newLookEyeVec, dist);

            camera.eye = math.addVec3(newLook, newLookEyeVec, tempVec3);
            camera.look = newLook;

            this.scene.camera.ortho.scale = diag * 1.1;

        } else if (newEye || newLook || newUp) {

            if (newEye) {
                camera.eye = newEye;
            }
            if (newLook) {
                camera.look = newLook;
            }
            if (newUp) {
                camera.up = newUp;
            }
        }

        if (params.projection) {
            camera.projection = params.projection;
        }
    }

    _update() {
        if (!this._flying) {
            return;
        }
        const time = Date.now();
        let t = (time - this._time1) / (this._time2 - this._time1);
        const stopping = (t >= 1);

        if (t > 1) {
            t = 1;
        }

        const tFlight = this.easing ? CameraFlightAnimation._ease(t, 0, 1, 1) : t;
        const camera = this.scene.camera;

        if (this._flyingEye || this._flyingLook) {

            if (this._flyingEye) {
                math.subVec3(camera.eye, camera.look, newLookEyeVec);
                camera.eye = math.lerpVec3(tFlight, 0, 1, this._eye1, this._eye2, newEye);
                camera.look = math.subVec3(newEye, newLookEyeVec, newLook);
            } else if (this._flyingLook) {
                camera.look = math.lerpVec3(tFlight, 0, 1, this._look1, this._look2, newLook);
                //    camera.eye = math.addVec3(newLook, newLookEyeVec, newEye);
                camera.up = math.lerpVec3(tFlight, 0, 1, this._up1, this._up2, newUp);
            }

        } else if (this._flyingEyeLookUp) {

            camera.eye = math.lerpVec3(tFlight, 0, 1, this._eye1, this._eye2, newEye);
            camera.look = math.lerpVec3(tFlight, 0, 1, this._look1, this._look2, newLook);
            camera.up = math.lerpVec3(tFlight, 0, 1, this._up1, this._up2, newUp);
        }

        if (this._projection2) {
            const tProj = (this._projection2 === "ortho") ? CameraFlightAnimation._easeOutExpo(t, 0, 1, 1) : CameraFlightAnimation._easeInCubic(t, 0, 1, 1);
            camera.customProjection.matrix = math.lerpMat4(tProj, 0, 1, this._projMatrix1, this._projMatrix2);

        } else {
            camera.ortho.scale = this._orthoScale1 + (t * (this._orthoScale2 - this._orthoScale1));
        }

        if (stopping) {
            this.stop();
            return;
        }
        core.scheduleTask(this._update, this); // Keep flying
    }

    static _ease(t, b, c, d) { // Quadratic easing out - decelerating to zero velocity http://gizma.com/easing
        t /= d;
        return -c * t * (t - 2) + b;
    }

    static _easeInCubic(t, b, c, d) {
        t /= d;
        return c * t * t * t + b;
    }

    static _easeOutExpo(t, b, c, d) {
        return c * (-Math.pow(2, -10 * t / d) + 1) + b;
    }

    /**
     * Stops an earlier flyTo, fires arrival callback.
     */
    stop() {
        if (!this._flying) {
            return;
        }
        this._flying = false;
        this._time1 = null;
        this._time2 = null;
        if (this._projection2) {
            this.scene.camera.projection = this._projection2;
        }
        const callback = this._callback;
        if (callback) {
            this._callback = null;
            if (this._callbackScope) {
                callback.call(this._callbackScope);
            } else {
                callback();
            }
        }
        this.fire("stopped", true, true);
    }

    /**
     * Cancels an earlier flyTo without calling the arrival callback.
     */
    cancel() {
        if (!this._flying) {
            return;
        }
        this._flying = false;
        this._time1 = null;
        this._time2 = null;
        if (this._callback) {
            this._callback = null;
        }
        this.fire("canceled", true, true);
    }

    /**
     * Sets the flight duration, in seconds, when calling {@link CameraFlightAnimation#flyTo}.
     *
     * Stops any flight currently in progress.
     *
     * default value is ````0.5````.
     *
     * @param {Number} value New duration value.
     */
    set duration(value) {
        this._duration = value ? (value * 1000.0) : 500;
        this.stop();
    }

    /**
     * Gets the flight duration, in seconds, when calling {@link CameraFlightAnimation#flyTo}.
     *
     * default value is ````0.5````.
     *
     * @returns {Number} New duration value.
     */
    get duration() {
        return this._duration / 1000.0;
    }

    /**
     * Sets if, when CameraFlightAnimation is flying to a boundary, it will always adjust the distance between the
     * {@link Camera#eye} and {@link Camera#look} so as to ensure that the target boundary is always filling the view volume.
     *
     * When false, the eye will remain at its current distance from the look position.
     *
     * Default value is ````true````.
     *
     * @param {Boolean} value Set ````true```` to activate this behaviour.
     */
    set fit(value) {
        this._fit = value !== false;
    }

    /**
     * Gets if, when CameraFlightAnimation is flying to a boundary, it will always adjust the distance between the
     * {@link Camera#eye} and {@link Camera#look} so as to ensure that the target boundary is always filling the view volume.
     *
     * When false, the eye will remain at its current distance from the look position.
     *
     * Default value is ````true````.
     *
     * @returns {Boolean} value Set ````true```` to activate this behaviour.
     */
    get fit() {
        return this._fit;
    }

    /**
     * Sets how much of the perspective field-of-view, in degrees, that a target {@link Entity#aabb} should
     * fill the canvas when calling {@link CameraFlightAnimation#flyTo} or {@link CameraFlightAnimation#jumpTo}.
     *
     * Default value is ````45````.
     *
     * @param {Number} value New FOV value.
     */
    set fitFOV(value) {
        this._fitFOV = value || 45;
    }

    /**
     * Gets how much of the perspective field-of-view, in degrees, that a target {@link Entity#aabb} should
     * fill the canvas when calling {@link CameraFlightAnimation#flyTo} or {@link CameraFlightAnimation#jumpTo}.
     *
     * Default value is ````45````.
     *
     * @returns {Number} Current FOV value.
     */
    get fitFOV() {
        return this._fitFOV;
    }

    /**
     * Sets if this CameraFlightAnimation to point the {@link Camera}
     * in the direction that it is travelling when flying to a target after calling {@link CameraFlightAnimation#flyTo}.
     *
     * Default value is ````true````.
     *
     * @param {Boolean} value Set ````true```` to activate trailing behaviour.
     */
    set trail(value) {
        this._trail = !!value;
    }

    /**
     * Gets if this CameraFlightAnimation points the {@link Camera}
     * in the direction that it is travelling when flying to a target after calling {@link CameraFlightAnimation#flyTo}.
     *
     * Default value is ````true````.
     *
     * @returns {Boolean} True if trailing behaviour is active.
     */
    get trail() {
        return this._trail;
    }
}

export {CameraFlightAnimation};
