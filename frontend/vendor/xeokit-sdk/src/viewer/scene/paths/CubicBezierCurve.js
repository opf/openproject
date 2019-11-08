import {Curve} from "./Curve.js"
import {math} from "../math/math.js";

/**
 * @desc A {@link Curve} along which a 3D position can be animated.
 *
 * * As shown in the diagram below, a CubicBezierCurve is defined by four control points.
 * * You can sample a {@link CubicBezierCurve#point} and a {@link CubicBezierCurve#tangent} vector on a CubicBezierCurve for any given value of {@link CubicBezierCurve#t} in the range [0..1].
 * * When you set {@link CubicBezierCurve#t} on a CubicBezierCurve, its {@link CubicBezierCurve#point} and {@link CubicBezierCurve#tangent} properties will update accordingly.
 * * To build a complex path, you can combine an unlimited combination of CubicBezierCurves, {@link QuadraticBezierCurve}s and {@link SplineCurve}s into a {@link Path}.
 *
 * <br>
 * <img style="border:1px solid;" src="https://upload.wikimedia.org/wikipedia/commons/thumb/d/db/B%C3%A9zier_3_big.gif/240px-B%C3%A9zier_3_big.gif"/>
 * <br>
 * [Cubic Bezier Curve from WikiPedia](https://en.wikipedia.org/wiki/B%C3%A9zier_curve)
 */
class CubicBezierCurve extends Curve {

    /**
     * @constructor
     * @param {Component} [owner]  Owner component. When destroyed, the owner will destroy this CubicBezierCurve as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Number[]} [cfg.v0=[0,0,0]] The starting point.
     * @param {Number[]} [cfg.v1=[0,0,0]] The first control point.
     * @param {Number[]} [cfg.v2=[0,0,0]] The middle control point.
     * @param {Number[]} [cfg.v3=[0,0,0]] The ending point.
     * @param {Number} [cfg.t=0] Current position on this CubicBezierCurve, in range between 0..1.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this.v0 = cfg.v0;
        this.v1 = cfg.v1;
        this.v2 = cfg.v2;
        this.v3 = cfg.v3;
        this.t = cfg.t;
    }

    /**
     * Sets the starting point on this CubicBezierCurve.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @param {Number[]} value The starting point.
     */
    set v0(value) {
        this._v0 = value || math.vec3([0, 0, 0]);
    }

    /**
     * Gets the starting point on this CubicBezierCurve.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @returns {Number[]} The starting point.
     */
    get v0() {
        return this._v0;
    }

    /**
     * Sets the first control point on this CubicBezierCurve.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @param {Number[]} value The first control point.
     */
    set v1(value) {
        this._v1 = value || math.vec3([0, 0, 0]);
    }

    /**
     * Gets the first control point on this CubicBezierCurve.
     *
     * Fires a {@link CubicBezierCurve#v1:event} event on change.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @returns {Number[]} The first control point.
     */
    get v1() {
        return this._v1;
    }

    /**
     * Sets the second control point on this CubicBezierCurve.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @param {Number[]} value The second control point.
     */
    set v2(value) {
        this._v2 = value || math.vec3([0, 0, 0]);
    }

    /**
     * Gets the second control point on this CubicBezierCurve.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @returns {Number[]} The second control point.
     */
    get v2() {
        return this._v2;
    }

    /**
     * Sets the end point on this CubicBezierCurve.
     *
     * Fires a {@link CubicBezierCurve#v3:event} event on change.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @param {Number[]} value The end point.
     */
    set v3(value) {
        this.fire("v3", this._v3 = value || math.vec3([0, 0, 0]));
    }

    /**
     * Gets the end point on this CubicBezierCurve.
     *
     * Fires a {@link CubicBezierCurve#v3:event} event on change.
     *
     * Default value is ````[0.0, 0.0, 0.0]````
     *
     * @returns {Number[]} The end point.
     */
    get v3() {
        return this._v3;
    }

    /**
     * Sets the current position of progress along this CubicBezierCurve.
     *
     * Automatically clamps to range ````[0..1]````.
     *
     * @param {Number} value New progress time value.
     */
    set t(value) {
        value = value || 0;
        this._t = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
    }

    /**
     * Gets the current position of progress along this CubicBezierCurve.
     *
     * @returns {Number} Current progress time value.
     */
    get t() {
        return this._t;
    }

    /**
     * Returns point on this CubicBezierCurve at the given position.
     *
     * @param {Number} t Position to get point at.
     *
     * @returns {{Number[]}} The point at the given position.
     */
    get point() {
        return this.getPoint(this._t);
    }

    /**
     * Returns point on this CubicBezierCurve at the given position.
     *
     * @param {Number} t Position to get point at.
     *
     * @returns {{Number[]}} The point at the given position.
     */
    getPoint(t) {

        var vector = math.vec3();

        vector[0] = math.b3(t, this._v0[0], this._v1[0], this._v2[0], this._v3[0]);
        vector[1] = math.b3(t, this._v0[1], this._v1[1], this._v2[1], this._v3[1]);
        vector[2] = math.b3(t, this._v0[2], this._v1[2], this._v2[2], this._v3[2]);

        return vector;
    }

    getJSON() {
        return {
            v0: this._v0,
            v1: this._v1,
            v2: this._v2,
            v3: this._v3,
            t: this._t
        };
    }
}

export {CubicBezierCurve}
