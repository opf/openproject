import {Component} from "../Component.js"
import {CameraFlightAnimation} from "./CameraFlightAnimation.js"


/**
 * @desc Animates the {@link Scene}'s's {@link Camera} along a {@link CameraPath}.
 *
 * ## Usage
 *
 * In the example below, we'll load a model using a {@link GLTFLoaderPlugin}, then animate a {@link Camera}
 * through the frames in a {@link CameraPath}.
 *
 *  * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#camera_CameraPathAnimation)]
 *
 * ````Javascript
 * import {Viewer} from "viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 * import {CameraPath} from "../src/scene/camera/CameraPath.js";
 * import {CameraPathAnimation} from "../src/scene/camera/CameraPathAnimation.js";
 *
 * // Create a Viewer and arrange camera
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas",
 *     transparent: true
 * });
 *
 * viewer.camera.eye = [124.86756896972656, -93.50288391113281, 173.2632598876953];
 * viewer.camera.look = [102.14186096191406, -90.24193572998047, 173.4224395751953];
 * viewer.camera.up = [0.23516440391540527, 0.9719591736793518, -0.0016466031083837152];
 *
 * // Load model
 *
 * const gltfLoader = new GLTFLoaderPlugin(viewer);
 *
 * const model = gltfLoader.load({
 *     id: "myModel",
 *     src: "./models/gltf/modern_office/scene.gltf",
 *     edges: true,
 *     edgeThreshold: 20,
 *     xrayed: false
 * });
 *
 * // Create a CameraPath
 *
 * var cameraPath = new CameraPath(viewer.scene, {
 *     frames: [
 *         {
 *             t:    0,
 *             eye:  [124.86, -93.50, 173.26],
 *             look: [102.14, -90.24, 173.42],
 *             up:   [0.23, 0.97, -0.00]
 *         },
 *         {
 *             t:    1,
 *             eye:  [79.75, -85.98, 226.57],
 *             look: [99.24, -84.11, 238.56],
 *             up:   [-0.14, 0.98, -0.09]
 *         },
 *         // Rest of the frames omitted for brevity
 *     ]
 * });
 *
 * // Create a CameraPathAnimation to play our CameraPath
 *
 * var cameraPathAnimation = new CameraPathAnimation(viewer.scene, {
 *     cameraPath: cameraPath,
 *     playingRate: 0.2 // Playing 0.2 time units per second
 * });
 *
 * // Once model loaded, start playing after a couple of seconds delay
 *
 * model.on("loaded", function () {
 *     setTimeout(function () {
 *         cameraPathAnimation.play(0); // Play from the beginning of the CameraPath
 *     }, 2000);
 * });
 * ````
 */
class CameraPathAnimation extends Component {

    /**
     * Returns "CameraPathAnimation".
     *
     * @private
     * @returns {string} "CameraPathAnimation"
     */
    get type() {
        return "CameraPathAnimation"
    }

    /**
     * @constructor
     * @param {Component} [owner]  Owner component. When destroyed, the owner will destroy this CameraPathAnimation as well.
     * @param {*} [cfg] Configuration
     * @param {String} [cfg.id]  Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {CameraPath} [cfg.eyeCurve] A {@link CameraPath} that defines the path of a {@link Camera}.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._cameraFlightAnimation = new CameraFlightAnimation(this);
        this._t = 0;
        this.state = CameraPathAnimation.SCRUBBING;
        this._playingFromT = 0;
        this._playingToT = 0;
        this._playingRate = cfg.playingRate || 1.0;
        this._playingDir = 1.0;
        this._lastTime = null;

        this.cameraPath = cfg.cameraPath;

        this._tick = this.scene.on("tick", this._updateT, this);
    }

    _updateT() {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        const f = 0.002;
        let numFrames;
        let t;
        const time = performance.now();
        const elapsedSecs = (this._lastTime) ? (time - this._lastTime) * 0.001 : 0;
        this._lastTime = time;
        if (elapsedSecs === 0) {
            return;
        }
        switch (this.state) {
            case CameraPathAnimation.SCRUBBING:
                return;
            case CameraPathAnimation.PLAYING:
                this._t += this._playingRate * elapsedSecs;
                numFrames = this._cameraPath.frames.length;
                if (numFrames === 0 || (this._playingDir < 0 && this._t <= 0) || (this._playingDir > 0 && this._t >= this._cameraPath.frames[numFrames - 1].t)) {
                    this.state = CameraPathAnimation.SCRUBBING;
                    this._t = this._cameraPath.frames[numFrames - 1].t;
                    this.fire("stopped");
                    return;
                }
                cameraPath.loadFrame(this._t);
                break;
            case CameraPathAnimation.PLAYING_TO:
                t = this._t + (this._playingRate * elapsedSecs * this._playingDir);
                if ((this._playingDir < 0 && t <= this._playingToT) || (this._playingDir > 0 && t >= this._playingToT)) {
                    t = this._playingToT;
                    this.state = CameraPathAnimation.SCRUBBING;
                    this.fire("stopped");
                }
                this._t = t;
                cameraPath.loadFrame(this._t);
                break;
        }
    }

    /*
    * @private
     */
    _ease(t, b, c, d) {
        t /= d;
        return -c * t * (t - 2) + b;
    }

    /**
     * Sets the {@link CameraPath} animated by this CameraPathAnimation.
     *
     @param {CameraPath} value The new CameraPath.
     */
    set cameraPath(value) {
        this._cameraPath = value;
    }

    /**
     * Gets the {@link CameraPath} animated by this CameraPathAnimation.
     *
     @returns {CameraPath} The CameraPath.
     */
    get cameraPath() {
        return this._cameraPath;
    }

    /**
     * Sets the rate at which the CameraPathAnimation animates the {@link Camera} along the {@link CameraPath}.
     *
     *  @param {Number} value The amount of progress per second.
     */
    set rate(value) {
        this._playingRate = value;
    }

    /**
     * Gets the rate at which the CameraPathAnimation animates the {@link Camera} along the {@link CameraPath}.
     *
     * @returns {*|number} The current playing rate.
     */
    get rate() {
        return this._playingRate;
    }

    /**
     * Begins animating the {@link Camera} along CameraPathAnimation's {@link CameraPath} from the beginning.
     */
    play() {
        if (!this._cameraPath) {
            return;
        }
        this._lastTime = null;
        this.state = CameraPathAnimation.PLAYING;
    }

    /**
     * Begins animating the {@link Camera} along CameraPathAnimation's {@link CameraPath} from the given time.
     *
     * @param {Number} t Time instant.
     */
    playToT(t) {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        this._playingFromT = this._t;
        this._playingToT = t;
        this._playingDir = (this._playingToT - this._playingFromT) < 0 ? -1 : 1;
        this._lastTime = null;
        this.state = CameraPathAnimation.PLAYING_TO;
    }

    /**
     * Animates the {@link Camera} along CameraPathAnimation's {@link CameraPath} to the given frame.
     *
     * @param {Number} frameIdx Index of the frame to play to.
     */
    playToFrame(frameIdx) {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        const frame = cameraPath.frames[frameIdx];
        if (!frame) {
            this.error("playToFrame - frame index out of range: " + frameIdx);
            return;
        }
        this.playToT(frame.t);
    }

    /**
     * Flies the {@link Camera} directly to the given frame on the CameraPathAnimation's {@link CameraPath}.
     *
     * @param {Number} frameIdx Index of the frame to play to.
     * @param {Function} [ok] Callback to fire when playing is complete.
     */
    flyToFrame(frameIdx, ok) {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        const frame = cameraPath.frames[frameIdx];
        if (!frame) {
            this.error("flyToFrame - frame index out of range: " + frameIdx);
            return;
        }
        this.state = CameraPathAnimation.SCRUBBING;
        this._cameraFlightAnimation.flyTo(frame, ok);
    }

    /**
     * Scrubs the {@link Camera} to the given time on the CameraPathAnimation's {@link CameraPath}.
     *
     * @param {Number} t Time instant.
     */
    scrubToT(t) {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        const camera = this.scene.camera;
        if (!camera) {
            return;
        }
        this._t = t;
        cameraPath.loadFrame(this._t);
        this.state = CameraPathAnimation.SCRUBBING;
    }

    /**
     * Scrubs the {@link Camera} to the given frame on the CameraPathAnimation's {@link CameraPath}.
     *
     * @param {Number} frameIdx Index of the frame to scrub to.
     */
    scrubToFrame(frameIdx) {
        const cameraPath = this._cameraPath;
        if (!cameraPath) {
            return;
        }
        const camera = this.scene.camera;
        if (!camera) {
            return;
        }
        const frame = cameraPath.frames[frameIdx];
        if (!frame) {
            this.error("playToFrame - frame index out of range: " + frameIdx);
            return;
        }
        cameraPath.loadFrame(this._t);
        this.state = CameraPathAnimation.SCRUBBING;
    }

    /**
     * Stops playing this CameraPathAnimation.
     */
    stop() {
        this.state = CameraPathAnimation.SCRUBBING;
        this.fire("stopped");
    }

    destroy() {
        super.destroy();
        this.scene.off(this._tick);
    }
}

CameraPathAnimation.STOPPED = 0;
CameraPathAnimation.SCRUBBING = 1;
CameraPathAnimation.PLAYING = 2;
CameraPathAnimation.PLAYING_TO = 3;

export {CameraPathAnimation}