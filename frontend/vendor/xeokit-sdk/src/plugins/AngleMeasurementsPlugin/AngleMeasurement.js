import {Marker} from "../../viewer/scene/marker/Marker.js";
import {Wire} from "../lib/html/Wire.js";
import {Dot} from "../lib/html/Dot.js";
import {Label} from "../lib/html/Label.js";
import {math} from "../../viewer/scene/math/math.js";
import {Component} from "../../viewer/scene/Component.js";

var originVec = new Float32Array(3);
var targetVec = new Float32Array(3);

/**
 * @desc Measures the angle indicated by three 3D points.
 *
 * See {@link AngleMeasurementsPlugin} for more info.
 */
class AngleMeasurement extends Component {

    /**
     * @private
     */
    constructor(plugin, cfg = {}) {

        super(plugin.viewer.scene, cfg);

        /**
         * The {@link AngleMeasurementsPlugin} that owns this AngleMeasurement.
         * @type {AngleMeasurementsPlugin}
         */
        this.plugin = plugin;

        this._container = cfg.container;
        if (!this._container) {
            throw "config missing: container";
        }

        var scene = this.plugin.viewer.scene;

        this._originMarker = new Marker(scene, cfg.origin);
        this._cornerMarker = new Marker(scene, cfg.corner);
        this._targetMarker = new Marker(scene, cfg.target);

        this._originWorld = new Float32Array(3);
        this._cornerWorld = new Float32Array(3);
        this._targetWorld = new Float32Array(3);

        this._wp = new Float32Array(12);
        this._vp = new Float32Array(12);
        this._pp = new Float32Array(12);
        this._cp = new Int16Array(6);

        this._originDot = new Dot(this._container, {});
        this._cornerDot = new Dot(this._container, {});
        this._targetDot = new Dot(this._container, {});

        this._originWire = new Wire(this._container, {color: "blue", thickness: 1});
        this._targetWire = new Wire(this._container, {color: "red", thickness: 1});

        this._angleLabel = new Label(this._container, {fillColor: "#00BBFF", prefix: "", text: ""});

        this._wpDirty = false;
        this._vpDirty = false;
        this._cpDirty = false;

        this._visible = false;
        this._originVisible = false;
        this._cornerVisible = false;
        this._targetVisible = false;

        this._originWireVisible = false;
        this._targetWireVisible = false;

        this._angleVisible = false;

        this._originMarker.on("worldPos", (value) => {
            this._originWorld.set(value || [0, 0, 0]);
            this._wpDirty = true;
            this._needUpdate(0); // No lag
        });

        this._cornerMarker.on("worldPos", (value) => {
            this._cornerWorld.set(value || [0, 0, 0]);
            this._wpDirty = true;
            this._needUpdate(0); // No lag
        });

        this._targetMarker.on("worldPos", (value) => {
            this._targetWorld.set(value || [0, 0, 0]);
            this._wpDirty = true;
            this._needUpdate(0); // No lag
        });

        this._onViewMatrix = scene.camera.on("viewMatrix", () => {
            this._vpDirty = true;
            this._needUpdate(0); // No lag
        });

        this._onProjMatrix = scene.camera.on("projMatrix", () => {
            this._cpDirty = true;
            this._needUpdate();
        });

        this._onCanvasBoundary = scene.canvas.on("boundary", () => {
            this._cpDirty = true;
            this._needUpdate(0); // No lag
        });

        this.visible = cfg.visible;

        this.originVisible = cfg.originVisible;
        this.cornerVisible = cfg.cornerVisible;
        this.targetVisible = cfg.targetVisible;

        this.originWireVisible = cfg.originWireVisible;
        this.targetWireVisible = cfg.targetWireVisible;

        this.angleVisible = cfg.angleVisible;
    }

    _update() {

        if (!this._visible) {
            return;
        }

        const scene = this.plugin.viewer.scene;

        if (this._wpDirty) {

            this._wp[0] = this._originWorld[0];
            this._wp[1] = this._originWorld[1];
            this._wp[2] = this._originWorld[2];
            this._wp[3] = 1.0;

            this._wp[4] = this._cornerWorld[0];
            this._wp[5] = this._cornerWorld[1];
            this._wp[6] = this._cornerWorld[2];
            this._wp[7] = 1.0;

            this._wp[8] = this._targetWorld[0];
            this._wp[9] = this._targetWorld[1];
            this._wp[10] = this._targetWorld[2];
            this._wp[11] = 1.0;

            this._wpDirty = false;
            this._vpDirty = true;
        }

        if (this._vpDirty) {

            math.transformPositions4(scene.camera.viewMatrix, this._wp, this._vp);

            this._vp[3] = 1.0;
            this._vp[7] = 1.0;
            this._vp[11] = 1.0;

            this._vpDirty = false;
            this._cpDirty = true;
        }

        if (this._cpDirty) {

            const near = -0.3;
            const zOrigin = this._originMarker.viewPos[2];
            const zCorner = this._cornerMarker.viewPos[2];
            const zTarget = this._targetMarker.viewPos[2];

            if (zOrigin > near || zCorner > near || zTarget > near) {

                this._originDot.setVisible(false);
                this._cornerDot.setVisible(false);
                this._targetDot.setVisible(false);

                this._originWire.setVisible(false);
                this._targetWire.setVisible(false);

                this._angleLabel.setVisible(false);

                return;
            }

            math.transformPositions4(scene.camera.project.matrix, this._vp, this._pp);

            var pp = this._pp;
            var cp = this._cp;

            var canvas = scene.canvas.canvas;
            var offsets = canvas.getBoundingClientRect();
            var top = offsets.top;
            var left = offsets.left;
            var aabb = scene.canvas.boundary;
            var canvasWidth = aabb[2];
            var canvasHeight = aabb[3];
            var j = 0;

            const metrics = this.plugin.viewer.scene.metrics;
            const scale = metrics.scale;
            const units = metrics.units;
            const unitInfo = metrics.unitsInfo[units];
            const unitAbbrev = unitInfo.abbrev;

            for (var i = 0, len = pp.length; i < len; i += 4) {
                cp[j] = left + Math.floor((1 + pp[i + 0] / pp[i + 3]) * canvasWidth / 2);
                cp[j + 1] = top + Math.floor((1 - pp[i + 1] / pp[i + 3]) * canvasHeight / 2);
                j += 2;
            }

            this._originDot.setPos(cp[0], cp[1]);
            this._cornerDot.setPos(cp[2], cp[3]);
            this._targetDot.setPos(cp[4], cp[5]);

            this._originWire.setStartAndEnd(cp[0], cp[1], cp[2], cp[3]);
            this._targetWire.setStartAndEnd(cp[2], cp[3], cp[4], cp[5]);

            this._angleLabel.setPosBetweenWires(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5]);


            math.subVec3(this._originWorld, this._cornerWorld, originVec);
            math.subVec3(this._targetWorld, this._cornerWorld, targetVec);

            var validVecs =
                (originVec[0] !== 0 || originVec[1] !== 0 || originVec[2] !== 0) &&
                (targetVec[0] !== 0 || targetVec[1] !== 0 || targetVec[2] !== 0);

            if (validVecs) {
                math.normalizeVec3(originVec);
                math.normalizeVec3(targetVec);
                var angle = Math.abs(math.angleVec3(originVec, targetVec));
                this._angle = angle / math.DEGTORAD;
                this._angleLabel.setText("" + this._angle.toFixed(2) + "°");
            } else {
                this._angleLabel.setText("");
            }

            // this._angleLabel.setText((Math.abs(math.lenVec3(math.subVec3(this._targetWorld, this._originWorld, distVec3)) * scale).toFixed(2)) + unitAbbrev);

            this._originDot.setVisible(this._visible && this._originVisible);
            this._cornerDot.setVisible(this._visible && this._cornerVisible);
            this._targetDot.setVisible(this._visible && this._targetVisible);

            this._originWire.setVisible(this._visible && this._originWireVisible);
            this._targetWire.setVisible(this._visible && this._targetWireVisible);

            this._angleLabel.setVisible(this._visible && this._angleVisible);

            this._cpDirty = false;
        }
    }

    /**
     * Gets the origin {@link Marker}.
     *
     * @type {Marker}
     */
    get origin() {
        return this._originMarker;
    }

    /**
     * Gets the corner {@link Marker}.
     *
     * @type {Marker}
     */
    get corner() {
        return this._cornerMarker;
    }

    /**
     * Gets the target {@link Marker}.
     *
     * @type {Marker}
     */
    get target() {
        return this._targetMarker;
    }

    /**
     * Gets the angle between two connected 3D line segments, given
     * as three positions on the surface(s) of one or more {@link Entity}s.
     *
     * @type {Number}
     */
    get angle() {
        this._update();
        return this._angle;
    }

    /**
     * Sets whether this AngleMeasurement is visible or not.
     *
     * @type Boolean
     */
    set visible(value) {
        value = value !== false;
        this._visible = value;
        this._originDot.setVisible(this._visible && this._originVisible);
        this._cornerDot.setVisible(this._visible && this._cornerVisible);
        this._targetDot.setVisible(this._visible && this._targetVisible);
        this._originWire.setVisible(this._visible && this._originWireVisible);
        this._targetWire.setVisible(this._visible && this._targetWireVisible);
        this._angleLabel.setVisible(this._visible && this._angleVisible);
    }

    /**
     * Gets whether this AngleMeasurement is visible or not.
     *
     * @type Boolean
     */
    get visible() {
        return this._visible;
    }

    /**
     * Sets if the origin {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    set originVisible(value) {
        value = value !== false;
        this._originVisible = value;
        this._originDot.setVisible(this._visible && this._originVisible);
    }

    /**
     * Gets if the origin {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    get originVisible() {
        return this._originVisible;
    }

    /**
     * Sets if the corner {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    set cornerVisible(value) {
        value = value !== false;
        this._cornerVisible = value;
        this._cornerDot.setVisible(this._visible && this._cornerVisible);
    }

    /**
     * Gets if the corner {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    get cornerVisible() {
        return this._cornerVisible;
    }

    /**
     * Sets if the target {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    set targetVisible(value) {
        value = value !== false;
        this._targetVisible = value;
        this._targetDot.setVisible(this._visible && this._targetVisible);
    }

    /**
     * Gets if the target {@link Marker} is visible.
     *
     * @type {Boolean}
     */
    get targetVisible() {
        return this._targetVisible;
    }

    /**
     * Sets if the wire between the origin and the corner is visible.
     *
     * @type {Boolean}
     */
    set originWireVisible(value) {
        value = value !== false;
        this._originWireVisible = value;
        this._originWire.setVisible(this._visible && this._originWireVisible);
    }

    /**
     * Gets if the wire between the origin and the corner is visible.
     *
     * @type {Boolean}
     */
    get originWireVisible() {
        return this._originWireVisible;
    }

    /**
     * Sets if the wire between the target and the corner is visible.
     *
     * @type {Boolean}
     */
    set targetWireVisible(value) {
        value = value !== false;
        this._targetWireVisible = value;
        this._targetWire.setVisible(this._visible && this._targetWireVisible);
    }

    /**
     * Gets if the wire between the target and the corner is visible.
     *
     * @type {Boolean}
     */
    get targetWireVisible() {
        return this._targetWireVisible;
    }

    /**
     * Sets if the angle label is visible.
     *
     * @type {Boolean}
     */
    set angleVisible(value) {
        value = value !== false;
        this._angleVisible = value;
        this._angleLabel.setVisible(this._visible && this._angleVisible);
    }

    /**
     * Gets if the angle label is visible.
     *
     * @type {Boolean}
     */
    get angleVisible() {
        return this._angleVisible;
    }

    /**
     * @private
     */
    destroy() {

        const scene = this.plugin.viewer.scene;

        if (this._onViewMatrix) {
            scene.camera.off(this._onViewMatrix);
        }
        if (this._onProjMatrix) {
            scene.camera.off(this._onProjMatrix);
        }
        if (this._onCanvasBoundary) {
            scene.canvas.off(this._onCanvasBoundary);
        }

        this._originDot.destroy();
        this._cornerDot.destroy();
        this._targetDot.destroy();

        this._originWire.destroy();
        this._targetWire.destroy();

        this._angleLabel.destroy();

        super.destroy();
    }
}

export {AngleMeasurement};