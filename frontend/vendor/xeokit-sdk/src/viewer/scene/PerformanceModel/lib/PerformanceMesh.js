import {math} from "../../math/math.js";

const tempIntRGBA = new Uint16Array([0, 0, 0, 0]);

/**
 * @private
 * @implements Pickable
 */
class PerformanceMesh {

    constructor(model, id, color, opacity, layer = null, portionId = 0) {

        /**
         * The PerformanceModel that contains this PerformanceModelMesh.
         *
         * A PerformanceModelMesh always belongs to exactly one PerformanceModel.
         *
         * @property model
         * @type {PerformanceModel}
         * @final
         */
        this.model = model;

        /**
         * The PerformanceNode that contains this PerformanceModelMesh.
         *
         * A PerformanceModelMesh always belongs to exactly one PerformanceNode.
         *
         * @property object
         * @type {PerformanceNode}
         * @final
         */
        this.object = null;

        /**
         * The PerformanceNode that contains this PerformanceModelMesh.
         *
         * A PerformanceModelMesh always belongs to exactly one PerformanceNode.
         *
         * @property object
         * @type {PerformanceNode}
         * @final
         */
        this.parent = null;

        /**
         * ID of this PerformanceModelMesh, unique within the xeokit.Scene.
         *
         * @property id
         * @type {String}
         * @final
         */
        this.id = id;

        /**
         *
         * @type {Number}
         * @private
         */
        this.pickId = this.model.scene._renderer.getPickID(this);

        /**
         * World-space 3D axis-aligned bounding box (AABB).
         *
         * Represented by a six-element Float32Array containing the min/max extents of the
         * axis-aligned volume, ie. ````[xmin, ymin,zmin,xmax,ymax, zmax]````.
         *
         * @property aabb
         * @final
         * @type {Number[]}
         */
        this.aabb = math.AABB3();

        this._layer = layer;
        this._portionId = portionId;

        this._color = [color[0], color[1], color[2], opacity]; // [0..255]
    }

    /**
     * @private
     */
    _initFlags(flags) {
        this._layer.initFlags(this._portionId, flags);
    }

    /**
     * @private
     */
    _setVisible(flags) {
        this._layer.setVisible(this._portionId, flags);
    }

    /**
     * @private
     */
    _setColor(color, setOpacity) {
        tempIntRGBA[0] = Math.floor((((this._color[0] / 255) * (color[0] / 255))) * 255);
        tempIntRGBA[1] = Math.floor((((this._color[1] / 255) * (color[1] / 255))) * 255);
        tempIntRGBA[2] = Math.floor((((this._color[2] / 255) * (color[2] / 255))) * 255);
        tempIntRGBA[3] = Math.floor((((this._color[3] / 255) * (color[3] / 255))) * 255);
        this._layer.setColor(this._portionId, tempIntRGBA, setOpacity);
    }

    /**
     * @private
     */
    _setHighlighted(flags) {
        this._layer.setHighlighted(this._portionId, flags);
    }

    /**
     * @private
     */
    _setXRayed(flags) {
        this._layer.setXRayed(this._portionId, flags);
    }

    /**
     * @private
     */
    _setSelected(flags) {
        this._layer.setSelected(this._portionId, flags);
    }

    /**
     * @private
     */
    _setEdges(flags) {
        this._layer.setEdges(this._portionId, flags);
    }

    /**
     * @private
     */
    _setClippable(flags) {
        this._layer.setClippable(this._portionId, flags);
    }

    /**
     * @private
     */
    _setCollidable(flags) {
        this._layer.setCollidable(this._portionId, flags);
    }

    /**
     * @private
     */
    _setPickable(flags) {
        this._layer.setPickable(this._portionId, flags);
    }

    /** @private */
    canPickTriangle() {
        return false;
    }

    /** @private */
    drawPickTriangles(frameCtx) {
        // NOP
    }

    /** @private */
    pickTriangleSurface(pickResult) {
        // NOP
    }

    /** @private */
    canPickWorldPos() {
        return true;
    }

    /** @private */
    drawPickDepths(frameCtx) {
        this.model.drawPickDepths(frameCtx);
    }

    /** @private */
    drawPickNormals(frameCtx) {
        this.model.drawPickNormals(frameCtx);
    }

    /**
     * @private
     * @returns {PerformanceNode}
     */
    delegatePickedEntity() {
        return this.parent;
    }

    /**
     * @private
     */
    _destroy() {
        this.model.scene._renderer.putPickID(this.pickId);
    }
}

export {PerformanceMesh};