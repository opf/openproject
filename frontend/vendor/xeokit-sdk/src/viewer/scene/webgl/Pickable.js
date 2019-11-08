/**
 * @desc A pickable {@link Scene} element.
 *
 * @interface
 * @abstract
 * @private
 */
class Pickable {

    /**
     * Called by xeokit to get if it's possible to pick a triangle on the surface of this Drawable.
     */
    canPickTriangle() {
    }

    /**
     * Picks a triangle on this Drawable.
     */
    drawPickTriangles(frameCtx) {
    }

    /**
     * Given a {@link PickResult} that contains a {@link PickResult#primIndex}, which indicates that a primitive was picked on the Drawable, then add more information to the PickResult about the picked position on the surface of the Drawable.
     *
     * Architecturally, this delegates collection of that Drawable-specific info to the Drawable, allowing it to provide whatever info it's able to.
     *
     * @param {PickResult} pickResult The PickResult to augment with pick intersection information specific to this Mesh.
     * @param [pickResult.primIndex] Index of the primitive that was picked on this Mesh.
     * @param [pickResult.canvasPos] Canvas coordinates, provided when picking through the Canvas.
     * @param [pickResult.origin] World-space 3D ray origin, when ray picking.
     * @param [pickResult.direction] World-space 3D ray direction, provided when ray picking.
     */
    pickTriangleSurface(pickResult) {
    }

    /**
     * Called by xeokit to get if it's possible to pick a 3D point on the surface of this Drawable.
     * Returns false if canPickTriangle returns true, and vice-versa.
     */
    canPickWorldPos() {
    }

    /**
     * Renders color-encoded fragment depths of this Drawable.
     * @param frameCtx
     */
    drawPickDepths(frameCtx) {
    }

    /**
     * Delegates an {@link Entity} as representing what was actually picked in place of this Pickable.
     * @returns {PerformanceNode}
     */
    delegatePickedEntity() {
        return this.parent;
    }
}

export {Pickable};