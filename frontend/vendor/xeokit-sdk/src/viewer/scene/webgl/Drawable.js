/**
 * @desc A drawable {@link Scene} element.
 *
 * @interface
 * @abstract
 * @private
 */
class Drawable {

    /**
     * Returns true to indicate that this is a Drawable.
     * @type {Boolean}
     * @abstract
     */
    get isDrawable() {
    }

    //------------------------------------------------------------------------------------------------------------------
    // Emphasis materials
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Configures the appearance of this Drawable when xrayed.
     *
     * Set to {@link Scene#xrayMaterial} by default.
     *
     * @type {EmphasisMaterial}
     * @abstract
     */
    get xrayMaterial() {
    }

    /**
     * Configures the appearance of this Drawable when highlighted.
     *
     * Set to {@link Scene#highlightMaterial} by default.
     *
     * @type {EmphasisMaterial}
     * @abstract
     */
    get highlightMaterial() {
    }

    /**
     * Configures the appearance of this Drawable when selected.
     *
     * Set to {@link Scene#selectedMaterial} by default.
     *
     * @type {EmphasisMaterial}
     * @abstract
     */
    get selectedMaterial() {
    }

    /**
     * Configures the appearance of this Drawable when edges are enhanced.
     *
     * @type {EdgeMaterial}
     * @abstract
     */
    get edgeMaterial() {
    }

    //------------------------------------------------------------------------------------------------------------------
    // Rendering
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Property with final value ````true```` to indicate that xeokit should render this Drawable in sorted order, relative to other Drawable of the same class.
     *
     * The sort order is determined by {@link Drawable#stateSortCompare}.
     *
     * Sorting is essential for rendering performance, so that xeokit is able to avoid applying runs of the same state changes to the GPU, ie. can collapse them.
     *
     * @type {boolean}
     * @abstract
     */
    get isStateSortable() {
    }

    /**
     * Comparison function used by the renderer to determine the order in which xeokit should render the Drawable, relative to to other Drawablees.
     *
     * Sorting is essential for rendering performance, so that xeokit is able to avoid needlessly applying runs of the same rendering state changes to the GPU, ie. can collapse them.
     *
     * @param {Drawable} drawable1
     * @param {Drawable} drawable2
     * @returns {number}
     * @abstract
     */
    stateSortCompare(drawable1, drawable2) {
    }

    /**
     * Called by xeokit when about to render this Drawable, to get flags indicating what rendering effects to apply for it.
     *
     * @param {RenderFlags} renderFlags Returns the rendering flags.
     * @abstract
     */
    getRenderFlags(renderFlags) {
    }

    /**
     * Renders opaque edges using {@link Drawable#edgeMaterial}.
     *
     * See {@link RenderFlags#normalFillOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawNormalFillOpaque(frameCtx) {
    }

    /**
     * Renders opaque edges using {@link Drawable#edgeMaterial}.
     *
     * See {@link RenderFlags#normalEdgesOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawNormalEdgesOpaque(frameCtx) {
    }

    /**
     * Renders transparent filled surfaces using normal appearance attributes.
     *
     * See {@link RenderFlags#normalEdgesOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawNormalFillTransparent(frameCtx) {
    }

    /**
     * Renders opaque edges using {@link Drawable#edgeMaterial}.
     *
     * See {@link RenderFlags#normalEdgesTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawNormalEdgesTransparent(frameCtx) {
    }

    /**
     * Renders xrayed opaque fill using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#xrayedFillOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawXRayedFillOpaque(frameCtx) {
    }

    /**
     * Renders xrayed opaque edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#xrayedEdgesOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawXRayedEdgesOpaque(frameCtx) {
    }

    /**
     * Renders xrayed transparent edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#xrayedFillTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawXRayedFillTransparent(frameCtx) {
    }

    /**
     * Renders xrayed transparent edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#xrayedEdgesTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawXRayedEdgesTransparent(frameCtx) {
    }

    /**
     * Renders highlighted opaque fill using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#highlightedFillOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawHighlightedFillOpaque(frameCtx) {
    }

    /**
     * Renders highlighted opaque edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#highlightedEdgesOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawHighlightedEdgesOpaque(frameCtx) {
    }

    /**
     * Renders highlighted transparent fill using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#highlightedFillTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawHighlightedFillTransparent(frameCtx) {
    }

    /**
     * Renders highlighted transparent edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#highlightedEdgesTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawHighlightedEdgesTransparent(frameCtx) {
    }

    /**
     * Renders highlighted opaque fill using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#highlightedFillOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawSelectedFillOpaque(frameCtx) {
    }

    /**
     * Renders selected opaque edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#selectedEdgesOpaque}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawSelectedEdgesOpaque(frameCtx) {
    }

    /**
     * Renders selected transparent fill using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#selectedFillTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawSelectedFillTransparent(frameCtx) {
    }

    /**
     * Renders selected transparent edges using {@link Drawable#xrayMaterial}.
     *
     * See {@link RenderFlags#selectedEdgesTransparent}.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawSelectedEdgesTransparent(frameCtx) {
    }

    /**
     * Renders occludable elements to a frame buffer where they will be tested to see if they occlude any occlusion probe markers.
     *
     * @param {FrameContext} frameCtx Renderer frame context.
     * @abstract
     */
    drawOcclusion(frameCtx) {
    }
}

export {Drawable};