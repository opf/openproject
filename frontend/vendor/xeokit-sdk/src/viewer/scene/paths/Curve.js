import {Component} from "../Component.js"
import {math} from "../math/math.js";

/**
 * @desc Abstract base class for curve classes.
 */
class Curve extends Component {

    /**
     * @constructor
     * @param {Component} [owner]  Owner component. When destroyed, the owner will destroy this Curve as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Curve}, generated automatically when omitted.
     * @param {Object} [cfg] Configs for this Curve.
     * @param {Number} [cfg.t=0] Current position on this Curve, in range between ````0..1````.
     */
    constructor(owner, cfg = {}) {
        super(owner, cfg);
        this.t = cfg.t;
    }

    /**
     * Sets the progress along this Curve.
     *
     * Automatically clamps to range ````[0..1]````.
     *
     * Default value is ````0````.
     *
     * @param {Number} value The progress value.
     */
    set t(value) {
        value = value || 0;
        this._t = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);
    }

    /**
     * Gets the progress along this Curve.
     *
     * @returns {Number} The progress value.
     */
    get t() {
        return this._t;
    }

    /**
     * Gets the tangent on this Curve at position {@link Curve#t}.
     *
     * @returns {{Number[]}} The tangent.
     */
    get tangent() {
        return this.getTangent(this._t);
    }

    /**
     * Gets the length of this Curve.
     *
     * @returns {Number} The Curve length.
     */
    get length() {
        var lengths = this._getLengths();
        return lengths[lengths.length - 1];
    }

    /**
     * Returns a normalized tangent vector on this Curve at the given position.
     *
     * @param {Number} t Position to get tangent at.
     * @returns {{Number[]}} Normalized tangent vector
     */
    getTangent(t) {
        var delta = 0.0001;
        if (t === undefined) {
            t = this._t;
        }
        var t1 = t - delta;
        var t2 = t + delta;
        if (t1 < 0) {
            t1 = 0;
        }
        if (t2 > 1) {
            t2 = 1;
        }
        var pt1 = this.getPoint(t1);
        var pt2 = this.getPoint(t2);
        var vec = math.subVec3(pt2, pt1, []);
        return math.normalizeVec3(vec, []);
    }

    getPointAt(u) {
        var t = this.getUToTMapping(u);
        return this.getPoint(t);
    }

    /**
     * Samples points on this Curve, at the given number of equally-spaced divisions.
     *
     * @param {Number} divisions The number of divisions.
     * @returns {{Array of Array}} Array of sampled 3D points.
     */
    getPoints(divisions) {
        if (!divisions) {
            divisions = 5;
        }
        var d, pts = [];
        for (d = 0; d <= divisions; d++) {
            pts.push(this.getPoint(d / divisions));
        }
        return pts;
    }

    _getLengths(divisions) {
        if (!divisions) {
            divisions = (this.__arcLengthDivisions) ? (this.__arcLengthDivisions) : 200;
        }
        if (this.cacheArcLengths && (this.cacheArcLengths.length === divisions + 1) && !this.needsUpdate) {
            return this.cacheArcLengths;

        }
        this.needsUpdate = false;
        var cache = [];
        var current;
        var last = this.getPoint(0);
        var p;
        var sum = 0;
        cache.push(0);
        for (p = 1; p <= divisions; p++) {
            current = this.getPoint(p / divisions);
            sum += math.lenVec3(math.subVec3(current, last, []));
            cache.push(sum);
            last = current;
        }
        this.cacheArcLengths = cache;
        return cache; // { sums: cache, sum:sum }, Sum is in the last element.
    }

    _updateArcLengths() {
        this.needsUpdate = true;
        this._getLengths();
    }

    // Given u ( 0 .. 1 ), get a t to find p. This gives you points which are equi distance

    getUToTMapping(u, distance) {
        var arcLengths = this._getLengths();
        var i = 0;
        var il = arcLengths.length;
        var t;
        var targetArcLength; // The targeted u distance value to get
        if (distance) {
            targetArcLength = distance;
        } else {
            targetArcLength = u * arcLengths[il - 1];
        }
        //var time = Date.now();
        var low = 0, high = il - 1, comparison;
        while (low <= high) {
            i = Math.floor(low + (high - low) / 2); // less likely to overflow, though probably not issue here, JS doesn't really have integers, all numbers are floats
            comparison = arcLengths[i] - targetArcLength;
            if (comparison < 0) {
                low = i + 1;
            } else if (comparison > 0) {
                high = i - 1;
            } else {
                high = i;
                break;
                // DONE
            }
        }
        i = high;
        if (arcLengths[i] === targetArcLength) {
            t = i / (il - 1);
            return t;
        }
        var lengthBefore = arcLengths[i];
        var lengthAfter = arcLengths[i + 1];
        var segmentLength = lengthAfter - lengthBefore;
        var segmentFraction = (targetArcLength - lengthBefore) / segmentLength;
        t = (i + segmentFraction) / (il - 1);
        return t;
    }
}

export {Curve}