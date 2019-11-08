import {RENDER_FLAGS} from './renderFlags.js';

const tempFloatRGB = new Float32Array([0, 0, 0]);

/**
 * @private
 */
class PerformanceNode {

    /**
     * @private
     */
    constructor(model, isObject, id, meshes, flags, aabb) {

        this._isObject = isObject;

        /**
         * The PerformanceModel that contains this PerformanceModelNode.
         * @property model
         * @type {PerformanceModel}
         * @final
         */
        this.model = model;

        /**
         * The PerformanceModelMesh instances contained by this PerformanceModelNode
         * @property meshes
         * @type {{Array of PerformanceModelMesh}}
         * @final
         */
        this.meshes = meshes;

        for (var i = 0, len = this.meshes.length; i < len; i++) {  // TODO: tidier way? Refactor?
            const mesh = this.meshes[i];
            mesh.parent = this;
        }

        /**
         * ID of this PerformanceModelNode, unique within the {@link Scene}.
         * @property id
         * @type {String|Number
         * @final}
         */
        this.id = id;

        this._flags = flags;
        this._colorize = new Uint8Array([255, 255, 255, 255]);

        this._aabb = aabb;

        if (this._isObject) {
            model.scene._registerObject(this);
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // Entity members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that PerformanceModelNode is an {@link Entity}.
     * @type {Boolean}
     */
    get isEntity() {
        return true;
    }

    /**
     * Always returns ````false```` because a PerformanceModelNode can never represent a model.
     *
     * @type {Boolean}
     */
    get isModel() {
        return false;
    }

    /**
     * Returns ````true```` if this PerformanceModelNode represents an object.
     *
     * When ````true```` the PerformanceModelNode will be registered by {@link PerformanceNode#id} in
     * {@link Scene#objects} and may also have a {@link MetaObject} with matching {@link MetaObject#id}.
     *
     * @type {Boolean}
     */
    get isObject() {
        return this._isObject;
    }

    /**
     * World-space 3D axis-aligned bounding box (AABB) of this PerformanceModelNode.
     *
     * Represented by a six-element Float32Array containing the min/max extents of the
     * axis-aligned volume, ie. ````[xmin, ymin,zmin,xmax,ymax, zmax]````.
     *
     * @type {Number[]}
     */
    get aabb() {
        return this._aabb;
    }

    /**
     * Sets if this PerformanceModelNode is visible.
     *
     * Only rendered when {@link PerformanceNode#visible} is ````true```` and {@link PerformanceNode#culled} is ````false````.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#visible} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    set visible(visible) {
        if (!!(this._flags & RENDER_FLAGS.VISIBLE) === visible) {
            return; // Redundant update
        }
        if (visible) {
            this._flags = this._flags | RENDER_FLAGS.VISIBLE;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.VISIBLE;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setVisible(this._flags);
        }
        if (this._isObject) {
            this.model.scene._objectVisibilityUpdated(this);
        }
        this.model.glRedraw();
    }

    /**
     * Gets if this PerformanceModelNode is visible.
     *
     * Only rendered when {@link PerformanceNode#visible} is ````true```` and {@link PerformanceNode#culled} is ````false````.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#visible} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    get visible() {
        return this._getFlag(RENDER_FLAGS.VISIBLE);
    }

    _getFlag(flag) {
        return !!(this._flags & flag);
    }

    /**
     * Sets if this PerformanceModelNode is highlighted.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#highlighted} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    set highlighted(highlighted) {
        if (!!(this._flags & RENDER_FLAGS.HIGHLIGHTED) === highlighted) {
            return; // Redundant update
        }
        if (highlighted) {
            this._flags = this._flags | RENDER_FLAGS.HIGHLIGHTED;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.HIGHLIGHTED;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setHighlighted(this._flags);
        }
        if (this._isObject) {
            this.model.scene._objectHighlightedUpdated(this);
        }
        this.model.glRedraw();
    }

    /**
     * Gets if this PerformanceModelNode is highlighted.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#highlighted} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    get highlighted() {
        return this._getFlag(RENDER_FLAGS.HIGHLIGHTED);
    }

    /**
     * Sets if this PerformanceModelNode is xrayed.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#xrayed} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#xrayedObjects}.
     *
     * @type {Boolean}
     */
    set xrayed(xrayed) {
        if (!!(this._flags & RENDER_FLAGS.XRAYED) === xrayed) {
            return; // Redundant update
        }
        if (xrayed) {
            this._flags = this._flags | RENDER_FLAGS.XRAYED;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.XRAYED;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setXRayed(this._flags);
        }
        if (this._isObject) {
            this.model.scene._objectXRayedUpdated(this);
        }
        this.model.glRedraw();
    }

    /**
     * Gets if this PerformanceModelNode is xrayed.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#highlighted} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    get xrayed() {
        return this._getFlag(RENDER_FLAGS.XRAYED);
    }

    /**
     * Gets if this PerformanceModelNode is selected.
     *
     * When both {@link PerformanceNode#isObject} and {@link PerformanceNode#selected} are ````true```` the PerformanceModelNode will be
     * registered by {@link PerformanceNode#id} in {@link Scene#selectedObjects}.
     *
     * @type {Boolean}
     */
    set selected(selected) {
        if (!!(this._flags & RENDER_FLAGS.SELECTED) === selected) {
            return; // Redundant update
        }
        if (selected) {
            this._flags = this._flags | RENDER_FLAGS.SELECTED;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.SELECTED;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setSelected(this._flags);
        }
        if (this._isObject) {
            this.model.scene._objectSelectedUpdated(this);
        }
        this.model.glRedraw();
    }

    /**
     * Sets if this PerformanceModelNode's edges are enhanced.
     *
     * @type {Boolean}
     */
    get selected() {
        return this._getFlag(RENDER_FLAGS.SELECTED);
    }

    /**
     * Sets if this PerformanceModelNode's edges are enhanced.
     *
     * @type {Boolean}
     */
    set edges(edges) {
        if (!!(this._flags & RENDER_FLAGS.EDGES) === edges) {
            return; // Redundant update
        }
        if (edges) {
            this._flags = this._flags | RENDER_FLAGS.EDGES;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.EDGES;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setEdges(this._flags);
        }
        this.model.glRedraw();
    }

    /**
     * Gets if this PerformanceModelNode's edges are enhanced.
     *
     * @type {Boolean}
     */
    get edges() {
        return this._getFlag(RENDER_FLAGS.EDGES);
    }

    /**
     * Sets if this PerformanceModelNode is culled.
     *
     * Only rendered when {@link PerformanceNode#visible} is ````true```` and {@link PerformanceNode#culled} is ````false````.
     *
     * @type {Boolean}
     */
    set culled(culled) { // TODO
    }

    /**
     * Gets if this PerformanceModelNode is culled.
     *
     * Only rendered when {@link PerformanceNode#visible} is ````true```` and {@link PerformanceNode#culled} is ````false````.
     *
     * @type {Boolean}
     */
    get culled() { // TODO
        return false;
    }

    /**
     * Sets if this PerformanceModelNode is clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#sectionPlanes}.
     *
     * @type {Boolean}
     */
    set clippable(clippable) {
        if ((!!(this._flags & RENDER_FLAGS.CLIPPABLE)) === clippable) {
            return; // Redundant update
        }
        if (clippable) {
            this._flags = this._flags | RENDER_FLAGS.CLIPPABLE;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.CLIPPABLE;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setClippable(this._flags);
        }
        this.model.glRedraw();
    }

    /**
     * Gets if this PerformanceModelNode is clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#sectionPlanes}.
     *
     * @type {Boolean}
     */
    get clippable() {
        return this._getFlag(RENDER_FLAGS.CLIPPABLE);
    }

    /**
     * Sets if this PerformanceModelNode is included in boundary calculations.
     *
     * @type {Boolean}
     */
    set collidable(collidable) {
        if (!!(this._flags & RENDER_FLAGS.COLLIDABLE) === collidable) {
            return; // Redundant update
        }
        if (collidable) {
            this._flags = this._flags | RENDER_FLAGS.COLLIDABLE;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.COLLIDABLE;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setCollidable(this._flags);
        }
    }

    /**
     * Gets if this PerformanceModelNode is included in boundary calculations.
     *
     * @type {Boolean}
     */
    get collidable() {
        return this._getFlag(RENDER_FLAGS.COLLIDABLE);
    }

    /**
     * Sets if this PerformanceModelNode is pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * @type {Boolean}
     */
    set pickable(pickable) {
        if (!!(this._flags & RENDER_FLAGS.PICKABLE) === pickable) {
            return; // Redundant update
        }
        if (pickable) {
            this._flags = this._flags | RENDER_FLAGS.PICKABLE;
        } else {
            this._flags = this._flags & ~RENDER_FLAGS.PICKABLE;
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setPickable(this._flags);
        }
    }

    /**
     * Gets if this PerformanceModelNode is pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * @type {Boolean}
     */
    get pickable() {
        return this._getFlag(RENDER_FLAGS.PICKABLE);
    }

    /**
     * Gets the PerformanceModelNode's RGB colorize color, multiplies by the PerformanceModelNode's rendered fragment colors.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * @type {Number[]}
     */
    set colorize(color) { // [0..1, 0..1, 0..1]
        this._colorize[0] = Math.floor(color[0] * 255.0); // Quantize
        this._colorize[1] = Math.floor(color[1] * 255.0);
        this._colorize[2] = Math.floor(color[2] * 255.0);
        const setOpacity = false;
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setColor(this._colorize, setOpacity);
        }
        this.model.glRedraw();
    }

    /**
     * Gets the PerformanceModelNode's RGB colorize color, multiplies by the PerformanceModelNode's rendered fragment colors.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * @type {Number[]}
     */
    get colorize() { // [0..1, 0..1, 0..1]
        tempFloatRGB[0] = this._colorize[0] / 255.0; // Unquantize
        tempFloatRGB[1] = this._colorize[1] / 255.0;
        tempFloatRGB[2] = this._colorize[2] / 255.0;
        return tempFloatRGB;
    }

    /**
     * Sets the PerformanceModelNode's opacity factor, multiplies by the PerformanceModelNode's rendered fragment alphas.
     *
     * This is a factor in range ````[0..1]````.
     *
     * @type {Number}
     */
    set opacity(opacity) {
        if (opacity < 0) {
            opacity = 0;
        } else if (opacity > 1) {
            opacity = 1;
        }
        opacity = Math.floor(opacity * 255.0); // Quantize
        var lastOpacity = this._colorize[3];
        if (lastOpacity === opacity) {
            return;
        }
        this._colorize[3] = opacity; // Only set alpha
        const setOpacity = true;
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._setColor(this._colorize, setOpacity);
        }
        this.model.glRedraw();
    }

    /**
     * Gets the PerformanceModelNode's opacity factor.
     *
     * This is a factor in range ````[0..1]```` which multiplies by the rendered fragment alphas.
     *
     * @type {Number}
     */
    get opacity() {
        return this._colorize[3] / 255.0;
    }

    /**
     * Sets if to this PerformanceModelNode casts shadows.
     *
     * @type {Boolean}
     */
    set castsShadow(pickable) { // TODO

    }

    /**
     * Gets if this PerformanceModelNode casts shadows.
     *
     * @type {Boolean}
     */
    get castsShadow() { // TODO
        return false;
    }

    /**
     * Whether or not this PerformanceModelNode can have shadows cast upon it
     *
     * @type {Boolean}
     */
    set receivesShadow(pickable) { // TODO

    }

    /**
     * Whether or not this PerformanceModelNode can have shadows cast upon it
     *
     * @type {Boolean}
     */
    get receivesShadow() { // TODO
        return false;
    }

    _finalize() {
        const scene = this.model.scene;
        if (this._isObject) {
            if (this.visible) {
                scene._objectVisibilityUpdated(this);
            }
            if (this.highlighted) {
                scene._objectHighlightedUpdated(this);
            }
            if (this.xrayed) {
                scene._objectXRayedUpdated(this);
            }
            if (this.selected) {
                scene._objectSelectedUpdated(this);
            }
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._initFlags(this._flags);
        }
    }

    _destroy() { // Called by PerformanceModel
        const scene = this.model.scene;
        if (this._isObject) {
            scene._deregisterObject(this);
            if (this.visible) {
                scene._objectVisibilityUpdated(this, false);
            }
            if (this.xrayed) {
                scene._objectXRayedUpdated(this);
            }
            if (this.selected) {
                scene._objectSelectedUpdated(this);
            }
            if (this.highlighted) {
                scene._objectHighlightedUpdated(this);
            }
        }
        for (var i = 0, len = this.meshes.length; i < len; i++) {
            this.meshes[i]._destroy();
        }
        scene._aabbDirty = true;
    }

}

export {PerformanceNode};