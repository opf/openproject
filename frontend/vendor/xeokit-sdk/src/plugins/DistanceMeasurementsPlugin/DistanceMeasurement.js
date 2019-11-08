import {Marker} from "../../viewer/scene/marker/Marker.js";
import {Wire} from "../lib/html/Wire.js";
import {Dot} from "../lib/html/Dot.js";
import {Label} from "../lib/html/Label.js";
import {math} from "../../viewer/scene/math/math.js";
import {Component} from "../../viewer/scene/Component.js";


var distVec3 = new Float32Array(3);

const lengthWire = (x1, y1, x2, y2) => {
    var a = x1 - x2;
    var b = y1 - y2;
    return Math.sqrt(a * a + b * b);
};

/**
 * @desc Measures the distance between two 3D points.
 *
 * See {@link DistanceMeasurementsPlugin} for more info.
 */
class DistanceMeasurement extends Component {

    /**
     * @private
     */
    constructor(plugin, cfg = {}) {

        super(plugin.viewer.scene, cfg);

        /**
         * The {@link DistanceMeasurementsPlugin} that owns this DistanceMeasurement.
         * @type {DistanceMeasurementsPlugin}
         */
        this.plugin = plugin;

        this._container = cfg.container;
        if (!this._container) {
            throw "config missing: container";
        }

        this._eventSubs = {};

        var scene = this.plugin.viewer.scene;

        this._originMarker = new Marker(scene, cfg.origin);
        this._targetMarker = new Marker(scene, cfg.target);

        this._originWorld = new Float32Array(3);
        this._targetWorld = new Float32Array(3);

        this._wp = new Float32Array(24);
        this._vp = new Float32Array(24);
        this._pp = new Float32Array(24);
        this._cp = new Int16Array(8);

        this._xAxisLabelCulled = false;
        this._yAxisLabelCulled = false;
        this._zAxisLabelCulled = false;

        this._originDot = new Dot(this._container, {
        });

        this._targetDot = new Dot(this._container, {
        });

        this._lengthWire = new Wire(this._container, {
            color: "#00BBFF",
            thickness: 2
        });

        this._xAxisWire = new Wire(this._container, {
            color: "red",
            thickness: 1
        });

        this._yAxisWire = new Wire(this._container, {
            color: "green",
            thickness: 1
        });

        this._zAxisWire = new Wire(this._container, {
            color: "blue",
            thickness: 1
        });

        this._lengthLabel = new Label(this._container, {
            fillColor: "#00BBFF",
            prefix: "",
            text: ""
        });

        this._xAxisLabel = new Label(this._container, {
            fillColor: "red",
            prefix: "X",
            text: ""
        });

        this._yAxisLabel = new Label(this._container, {
            fillColor: "green",
            prefix: "Y",
            text: ""
        });

        this._zAxisLabel = new Label(this._container, {
            fillColor: "blue",
            prefix: "Z",
            text: ""
        });

        this._wpDirty = false;
        this._vpDirty = false;
        this._cpDirty = false;

        this._visible = false;
        this._originVisible = false;
        this._targetVisible = false;
        this._wireVisible = false;
        this._axisVisible = false;

        this._originMarker.on("worldPos", (value) => {
            this._originWorld.set(value || [0, 0, 0]);
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

        this._onMetricsUnits = scene.metrics.on("units", () => {
            this._cpDirty = true;
            this._needUpdate();
        });

        this._onMetricsScale = scene.metrics.on("scale", () => {
            this._cpDirty = true;
            this._needUpdate();
        });

        this._onMetricsOrigin = scene.metrics.on("origin", () => {
            this._cpDirty = true;
            this._needUpdate();
        });

        this.visible = cfg.visible;
        this.originVisible = cfg.originVisible;
        this.targetVisible = cfg.targetVisible;
        this.wireVisible = cfg.wireVisible;
        this.axisVisible = cfg.axisVisible;
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

            this._wp[4] = this._targetWorld[0];
            this._wp[5] = this._originWorld[1];
            this._wp[6] = this._originWorld[2];
            this._wp[7] = 1.0;

            this._wp[8] = this._targetWorld[0];
            this._wp[9] = this._targetWorld[1];
            this._wp[10] = this._originWorld[2];
            this._wp[11] = 1.0;

            this._wp[12] = this._targetWorld[0];
            this._wp[13] = this._targetWorld[1];
            this._wp[14] = this._targetWorld[2];
            this._wp[15] = 1.0;

            this._wpDirty = false;
            this._vpDirty = true;
        }

        if (this._vpDirty) {

            math.transformPositions4(scene.camera.viewMatrix, this._wp, this._vp);

            this._vp[3] = 1.0;
            this._vp[7] = 1.0;
            this._vp[11] = 1.0;
            this._vp[15] = 1.0;

            this._vpDirty = false;
            this._cpDirty = true;
        }

        const near = -0.3;
        const vpz1 = this._originMarker.viewPos[2];
        const vpz2 = this._targetMarker.viewPos[2];

        if (vpz1 > near || vpz2 > near) {

            this._xAxisLabel.setVisible(false);
            this._yAxisLabel.setVisible(false);
            this._zAxisLabel.setVisible(false);
            this._lengthLabel.setVisible(false);

            this._xAxisWire.setVisible(false);
            this._yAxisWire.setVisible(false);
            this._zAxisWire.setVisible(false);
            this._lengthWire.setVisible(false);

            this._originDot.setVisible(false);
            this._targetDot.setVisible(false);

            return;
        }

        if (this._cpDirty) {

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
                cp[j] = left +  Math.floor((1 + pp[i + 0] / pp[i + 3]) * canvasWidth / 2);
                cp[j + 1] = top + Math.floor((1 - pp[i + 1] / pp[i + 3]) * canvasHeight / 2);
                j += 2;
            }

            this._originDot.setPos(cp[0], cp[1]);
            this._targetDot.setPos(cp[6], cp[7]);

            this._lengthWire.setStartAndEnd(cp[0], cp[1], cp[6], cp[7]);

            this._xAxisWire.setStartAndEnd(cp[0], cp[1], cp[2], cp[3]);
            this._yAxisWire.setStartAndEnd(cp[2], cp[3], cp[4], cp[5]);
            this._zAxisWire.setStartAndEnd(cp[4], cp[5], cp[6], cp[7]);

            this._lengthLabel.setPosOnWire(cp[0], cp[1], cp[6], cp[7]);
            this._xAxisLabel.setPosOnWire(cp[0], cp[1], cp[2], cp[3]);
            this._yAxisLabel.setPosOnWire(cp[2], cp[3], cp[4], cp[5]);
            this._zAxisLabel.setPosOnWire(cp[4], cp[5], cp[6], cp[7]);

            this._lengthLabel.setText((Math.abs(math.lenVec3(math.subVec3(this._targetWorld, this._originWorld, distVec3)) * scale).toFixed(2)) + unitAbbrev);

            const xAxisCanvasLength = Math.abs(lengthWire(cp[0], cp[1], cp[2], cp[3]));
            const yAxisCanvasLength = Math.abs(lengthWire(cp[2], cp[3], cp[4], cp[5]));
            const zAxisCanvasLength = Math.abs(lengthWire(cp[4], cp[5], cp[6], cp[7]));

            const labelMinAxisLength = this.plugin.labelMinAxisLength;

            this._xAxisLabelCulled = (xAxisCanvasLength < labelMinAxisLength);
            this._yAxisLabelCulled = (yAxisCanvasLength < labelMinAxisLength);
            this._zAxisLabelCulled = (zAxisCanvasLength < labelMinAxisLength);

            if (!this._xAxisLabelCulled) {
                this._xAxisLabel.setText(Math.abs(this._targetWorld[0] - this._originWorld[0] * scale).toFixed(2) + unitAbbrev);
                this._xAxisLabel.setVisible(true);
            } else {
                this._xAxisLabel.setVisible(false);
            }

            if (!this._yAxisLabelCulled) {
                this._yAxisLabel.setText(Math.abs(this._targetWorld[1] - this._originWorld[1] * scale).toFixed(2) + unitAbbrev);
                this._yAxisLabel.setVisible(true);
            } else {
                this._yAxisLabel.setVisible(false);
            }

            if (!this._zAxisLabelCulled) {
                this._zAxisLabel.setText(Math.abs(this._targetWorld[2] - this._originWorld[2] * scale).toFixed(2) + unitAbbrev);
                this._zAxisLabel.setVisible(true);
            } else {
                this._zAxisLabel.setVisible(false);
            }

            this._originDot.setVisible(this._visible && this._originVisible);
            this._targetDot.setVisible(this._visible && this._targetVisible);
            this._xAxisWire.setVisible(true);
            this._yAxisWire.setVisible(true);
            this._zAxisWire.setVisible(true);
            this._lengthWire.setVisible(true);

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
     * Gets the target {@link Marker}.
     *
     * @type {Marker}
     */
    get target() {
        return this._targetMarker;
    }

    /**
     * Gets the World-space direct point-to-point distance between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target}.
     *
     * @type {Number}
     */
    get length() {
        this._update();
        const scale = this.plugin.viewer.scene.metrics.scale;
        return this._length * scale;
    }

    /**
     * Sets whether this DistanceMeasurement is visible or not.
     *
     * @type Boolean
     */
    set visible(value) {
        value = value !== false;
        this._visible = value;
        this._originDot.setVisible(this._visible && this._originVisible);
        this._targetDot.setVisible(this._visible && this._targetVisible);
        this._lengthWire.setVisible(this._visible && this._wireVisible);
        var axisVisible = this._visible && this._axisVisible;
        this._xAxisWire.setVisible(axisVisible);
        this._yAxisWire.setVisible(axisVisible);
        this._zAxisWire.setVisible(axisVisible);
        this._lengthLabel.setVisible(axisVisible);
        this._xAxisLabel.setVisible(axisVisible && !this._xAxisLabelCulled);
        this._yAxisLabel.setVisible(axisVisible && !this._yAxisLabelCulled);
        this._zAxisLabel.setVisible(axisVisible && !this._zAxisLabelCulled);
    }

    /**
     * Gets whether this DistanceMeasurement is visible or not.
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
     * Sets if the axis-aligned wires between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target} are visible.
     *
     * @type {Boolean}
     */
    set axisVisible(value) {
        value = value !== false;
        this._axisVisible = value;
        var axisVisible = this._visible && this._axisVisible;
        this._xAxisWire.setVisible(axisVisible);
        this._yAxisWire.setVisible(axisVisible);
        this._zAxisWire.setVisible(axisVisible);
        this._xAxisLabel.setVisible(axisVisible && !this._xAxisLabelCulled);
        this._yAxisLabel.setVisible(axisVisible && !this._yAxisLabelCulled);
        this._zAxisLabel.setVisible(axisVisible && !this._zAxisLabelCulled);
    }

    /**
     * Gets if the axis-aligned wires between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target} are visible.
     *
     * @type {Boolean}
     */
    get axisVisible() {
        return this._axisVisible;
    }

    /**
     * Sets if the direct point-to-point wire between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target} is visible.
     *
     * @type {Boolean}
     */
    set wireVisible(value) {
        value = value !== false;
        this._wireVisible = value;
        var wireVisible = this._visible && this._wireVisible;
        this._lengthLabel.setVisible(wireVisible);
        this._lengthWire.setVisible(wireVisible);
    }

    /**
     * Gets if the direct point-to-point wire between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target} is visible.
     *
     * @type {Boolean}
     */
    get wireVisible() {
        return this._wireVisible;
    }

    /**
     * @private
     */
    destroy() {

        const scene = this.plugin.viewer.scene;
        const metrics = scene.metrics;

        if (this._onViewMatrix) {
            scene.camera.off(this._onViewMatrix);
        }
        if (this._onProjMatrix) {
            scene.camera.off(this._onProjMatrix);
        }
        if (this._onCanvasBoundary) {
            scene.canvas.off(this._onCanvasBoundary);
        }

        if (this._onMetricsUnits) {
            metrics.off(this._onMetricsUnits);
        }
        if (this._onMetricsScale) {
            metrics.off(this._onMetricsScale);
        }
        if (this._onMetricsOrigin) {
            metrics.off(this._onMetricsOrigin);
        }

        this._originDot.destroy();
        this._targetDot.destroy();
        this._xAxisWire.destroy();
        this._yAxisWire.destroy();
        this._zAxisWire.destroy();
        this._lengthLabel.destroy();
        this._xAxisLabel.destroy();
        this._yAxisLabel.destroy();
        this._zAxisLabel.destroy();
        this._lengthWire.destroy();

        super.destroy();
    }
}

export {DistanceMeasurement};