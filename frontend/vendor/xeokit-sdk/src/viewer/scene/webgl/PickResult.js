/**
 * @desc Pick result returned by {@link Scene#pick}.
 *
 */
class PickResult {

    /**
     * @private
     * @param value
     */
    constructor() {

        /**
         * Picked entity.
         * Null when no entity was picked.
         * @property entity
         * @type {Entity|*}
         */
        this.entity = null;

        /**
         * Type of primitive that was picked - usually "triangle".
         * Null when no primitive was picked.
         * @property primitive
         * @type {String}
         */
        this.primitive = null;

        /**
         * Index of primitive that was picked.
         * -1 when no entity was picked.
         * @property primIndex
         * @type {number}
         */
        this.primIndex = -1;

        this._canvasPos = new Int16Array([0, 0]);
        this._origin = new Float32Array([0, 0, 0]);
        this._direction = new Float32Array([0, 0, 0]);
        this._indices = new Int32Array(3);
        this._localPos = new Float32Array([0, 0, 0]);
        this._worldPos = new Float32Array([0, 0, 0]);
        this._viewPos = new Float32Array([0, 0, 0]);
        this._bary = new Float32Array([0, 0, 0]);
        this._worldNormal = new Float32Array([0, 0, 0]);
        this._uv = new Float32Array([0, 0]);

        this.reset();
    }

    /**
     * Canvas coordinates when picking with a 2D pointer.
     * @property canvasPos
     * @type {Number[]}
     */
    get canvasPos() {
        return this._gotCanvasPos ? this._canvasPos : null;
    }

    /**
     * @private
     * @param value
     */
    set canvasPos(value) {
        if (value) {
            this._canvasPos[0] = value[0];
            this._canvasPos[1] = value[1];
            this._gotCanvasPos = true;
        } else {
            this._gotCanvasPos = false;
        }
    }

    /**
     * World-space 3D ray origin when raypicked.
     * @property origin
     * @type {Number[]}
     */
    get origin() {
        return this._gotOrigin ? this._origin : null;
    }

    /**
     * @private
     * @param value
     */
    set origin(value) {
        if (value) {
            this._origin[0] = value[0];
            this._origin[1] = value[1];
            this._origin[2] = value[2];
            this._gotOrigin = true;
        } else {
            this._gotOrigin = false;
        }
    }

    /**
     * World-space 3D ray direction when raypicked.
     * @property direction
     * @type {Number[]}
     */
    get direction() {
        return this._gotDirection ? this._direction : null;
    }

    /**
     * @private
     * @param value
     */
    set direction(value) {
        if (value) {
            this._direction[0] = value[0];
            this._direction[1] = value[1];
            this._direction[2] = value[2];
            this._gotDirection = true;
        } else {
            this._gotDirection = false;
        }
    }
    
    /**
     * Picked triangle's vertex indices.
     * Only defined when an entity and triangle was picked.
     * @property indices
     * @type {Int32Array}
     */
    get indices() {
        return this.entity && this._gotIndices ? this._indices : null;
    }

    /**
     * @private
     * @param value
     */
    set indices(value) {
        if (value) {
            this._indices[0] = value[0];
            this._indices[1] = value[1];
            this._indices[2] = value[2];
            this._gotIndices = true;
        } else {
            this._gotIndices = false;
        }
    }

    /**
     * Picked Local-space point on surface.
     * Only defined when an entity and a point on its surface was picked.
     * @property localPos
     * @type {Number[]}
     */
    get localPos() {
        return this.entity && this._gotLocalPos ? this._localPos : null;
    }

    /**
     * @private
     * @param value
     */
    set localPos(value) {
        if (value) {
            this._localPos[0] = value[0];
            this._localPos[1] = value[1];
            this._localPos[2] = value[2];
            this._gotLocalPos = true;
        } else {
            this._gotLocalPos = false;
        }
    }

    /**
     * Picked World-space point on surface.
     * Only defined when an entity and a point on its surface was picked.
     * @property worldPos
     * @type {Number[]}
     */
    get worldPos() {
        return this.entity && this._gotWorldPos ? this._worldPos : null;
    }

    /**
     * @private
     * @param value
     */
    set worldPos(value) {
        if (value) {
            this._worldPos[0] = value[0];
            this._worldPos[1] = value[1];
            this._worldPos[2] = value[2];
            this._gotWorldPos = true;
        } else {
            this._gotWorldPos = false;
        }
    }

    /**
     * Picked View-space point on surface.
     * Only defined when an entity and a point on its surface was picked.
     * @property viewPos
     * @type {Number[]}
     */
    get viewPos() {
        return this.entity && this._gotViewPos ? this._viewPos : null;
    }

    /**
     * @private
     * @param value
     */
    set viewPos(value) {
        if (value) {
            this._viewPos[0] = value[0];
            this._viewPos[1] = value[1];
            this._viewPos[2] = value[2];
            this._gotViewPos = true;
        } else {
            this._gotViewPos = false;
        }
    }

    /**
     * Barycentric coordinate within picked triangle.
     * Only defined when an entity and a point on its surface was picked.
     * @property bary
     * @type {Number[]}
     */
    get bary() {
        return this.entity && this._gotBary ? this._bary : null;
    }

    /**
     * @private
     * @param value
     */
    set bary(value) {
        if (value) {
            this._bary[0] = value[0];
            this._bary[1] = value[1];
            this._bary[2] = value[2];
            this._gotBary = true;
        } else {
            this._gotBary = false;
        }
    }

    /**
     * Normal vector at picked position on surface.
     * Only defined when an entity and a point on its surface was picked.
     * @property worldNormal
     * @type {Number[]}
     */
    get worldNormal() {
        return this.entity && this._gotWorldNormal ? this._worldNormal : null;
    }

    /**
     * @private
     * @param value
     */
    set worldNormal(value) {
        if (value) {
            this._worldNormal[0] = value[0];
            this._worldNormal[1] = value[1];
            this._worldNormal[2] = value[2];
            this._gotWorldNormal = true;
        } else {
            this._gotWorldNormal = false;
        }
    }

    /**
     * UV coordinates at picked position on surface.
     * Only defined when an entity and a point on its surface was picked.
     * @property uv
     * @type {Number[]}
     */
    get uv() {
        return this.entity && this._gotUV ? this._uv : null;
    }

    /**
     * @private
     * @param value
     */
    set uv(value) {
        if (value) {
            this._uv[0] = value[0];
            this._uv[1] = value[1];
            this._gotUV = true;
        } else {
            this._gotUV = false;
        }
    }

    /**
     * @private
     * @param value
     */
    reset() {
        this.entity = null;
        this.primIndex = -1;
        this.primitive = null;
        this._gotCanvasPos = false;
        this._gotOrigin = false;
        this._gotDirection = false;
        this._gotIndices = false;
        this._gotLocalPos = false;
        this._gotWorldPos = false;
        this._gotViewPos = false;
        this._gotBary = false;
        this._gotWorldNormal = false;
        this._gotUV = false;
    }
}

export {PickResult};