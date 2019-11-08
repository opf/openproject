import {utils} from "../utils.js";
import {Curve} from "./curve.js"

/**
 * @desc A complex curved path constructed from various {@link Curve} subtypes.
 *
 * * A Path can be constructed from these {@link Curve} subtypes: {@link SplineCurve}, {@link CubicBezierCurve} and {@link QuadraticBezierCurve}.
 * * You can sample a {@link Path#point} and a {@link Curve#tangent} vector on a Path for any given value of {@link Path#t} in the range ````[0..1]````.
 * * When you set {@link Path#t} on a Path, its {@link Path#point} and {@link Curve#tangent} properties will update accordingly.
 */
class Path extends Curve {

    /**
     * @constructor
     * @param {Component} [owner]  Owner component. When destroyed, the owner will destroy this SectionPlane as well.
     * @param {*} [cfg]  Path configuration
     * @param {String} [cfg.id]  Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {String []} [cfg.paths=[]] IDs or instances of {{#crossLink "path"}}{{/crossLink}} subtypes to add to this Path.
     * @param {Number} [cfg.t=0] Current position on this Path, in range between 0..1.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this._cachedLengths = [];
        this._dirty = true;
        this._curves = []; // Array of child Curve components
        this._t = 0;
        this._dirtySubs = []; // Subscriptions to "dirty" events from child Curve components
        this._destroyedSubs = []; // Subscriptions to "destroyed" events from child Curve components
        this.curves = cfg.curves || [];    // Add initial curves
        this.t = cfg.t; // Set initial progress
    }

    /**
     * Adds a {@link Curve} to this Path.
     *
     * @param {Curve} curve The {@link Curve} to add.
     */
    addCurve(curve) {
        this._curves.push(curve);
        this._dirty = true;
    }

    /**
     * Sets the {@link Curve}s in this Path.
     *
     * Default value is ````[]````.
     *
     * @param {{Array of Spline, Path, QuadraticBezierCurve or CubicBezierCurve}} value.
     */
    set curves(value) {

        value = value || [];

        var curve;
        // Unsubscribe from events on old curves
        var i;
        var len;
        for (i = 0, len = this._curves.length; i < len; i++) {
            curve = this._curves[i];
            curve.off(this._dirtySubs[i]);
            curve.off(this._destroyedSubs[i]);
        }

        this._curves = [];
        this._dirtySubs = [];
        this._destroyedSubs = [];

        var self = this;

        function curveDirty() {
            self._dirty = true;
        }

        function curveDestroyed() {
            var id = this.id;
            for (i = 0, len = self._curves.length; i < len; i++) {
                if (self._curves[i].id === id) {
                    self._curves = self._curves.slice(i, i + 1);
                    self._dirtySubs = self._dirtySubs.slice(i, i + 1);
                    self._destroyedSubs = self._destroyedSubs.slice(i, i + 1);
                    self._dirty = true;
                    return;
                }
            }
        }

        for (i = 0, len = value.length; i < len; i++) {
            curve = value[i];
            if (utils.isNumeric(curve) || utils.isString(curve)) {
                // ID given for curve - find the curve component
                var id = curve;
                curve = this.scene.components[id];
                if (!curve) {
                    this.error("Component not found: " + _inQuotes(id));
                    continue;
                }
            }

            var type = curve.type;

            if (type !== "xeokit.SplineCurve" &&
                type !== "xeokit.Path" &&
                type !== "xeokit.CubicBezierCurve" &&
                type !== "xeokit.QuadraticBezierCurve") {

                this.error("Component " + _inQuotes(curve.id)
                    + " is not a xeokit.SplineCurve, xeokit.Path or xeokit.QuadraticBezierCurve");

                continue;
            }

            this._curves.push(curve);
            this._dirtySubs.push(curve.on("dirty", curveDirty));
            this._destroyedSubs.push(curve.once("destroyed", curveDestroyed));
        }

        this._dirty = true;
    }

    /**
     * Gets the {@link Curve}s in this Path.
     *
     * @returns {{Array of Spline, Path, QuadraticBezierCurve or CubicBezierCurve}} the {@link Curve}s in this path.
     */
    get curves() {
        return this._curves;
    }

    /**
     * Sets the current point of progress along this Path.
     *
     * Automatically clamps to range ````[0..1]````.
     *
     * Default value is ````0````.
     *
     * @param {Number} value The current point of progress.
     */
    set t(value) {
        value = value || 0;
        this._t = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
    }

    /**
     * Gets the current point of progress along this Path.
     *
     * Default value is ````0````.
     *
     * @returns {Number} The current point of progress.
     */
    get t() {
        return this._t;
    }

    /**
     * Gets point on this Path corresponding to the current value of {@link Path#t}.
     *
     * @returns {{Number[]}} The point.
     */
    get point() {
        return this.getPoint(this._t);
    }

    /**
     * Length of this Path, which is the cumulative length of all {@link Curve}s currently in {@link Path#curves}.
     *
     * @return {Number} Length of this path.
     */
    get length() {
        var lens = this._getCurveLengths();
        return lens[lens.length - 1];
    }

    /**
     * Gets a point on this Path corresponding to the given progress position.
     *
     * @param {Number} t Indicates point of progress along this curve, in the range [0..1].
     * @returns {{Number[]}}
     */
    getPoint(t) {
        var d = t * this.length;
        var curveLengths = this._getCurveLengths();
        var i = 0, diff, curve;
        while (i < curveLengths.length) {
            if (curveLengths[i] >= d) {
                diff = curveLengths[i] - d;
                curve = this._curves[i];
                var u = 1 - diff / curve.length;
                return curve.getPointAt(u);
            }
            i++;
        }
        return null;
    }

    _getCurveLengths() {
        if (!this._dirty) {
            return this._cachedLengths;
        }
        var lengths = [];
        var sums = 0;
        var i, il = this._curves.length;
        for (i = 0; i < il; i++) {
            sums += this._curves[i].length;
            lengths.push(sums);

        }
        this._cachedLengths = lengths;
        this._dirty = false;
        return lengths;
    }

    _getJSON() {
        var curveIds = [];
        for (var i = 0, len = this._curves.length; i < len; i++) {
            curveIds.push(this._curves[i].id);
        }
        return {
            curves: curveIds,
            t: this._t
        };
    }

    /**
     * Destroys this Path.
     */
    destroy() {
        super.destroy();
        var i;
        var len;
        var curve;
        for (i = 0, len = this._curves.length; i < len; i++) {
            curve = this._curves[i];
            curve.off(this._dirtySubs[i]);
            curve.off(this._destroyedSubs[i]);
        }
    }
}

export {Path}