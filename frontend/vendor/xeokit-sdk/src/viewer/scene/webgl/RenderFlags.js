/**
 * @desc Passed to each {@link Drawable#getRenderFlags} method as xeokit is about to render it, to query what rendering methods xeokit should call on the {@link Drawable} to render it.
 * @private
 */
class RenderFlags {

    /**
     * @private
     */
    constructor() {
        this.reset();
    }

    /**
     * @private
     */
    reset() {

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawNormalFillOpaque}.
         * @property normalFillOpaque
         * @type {boolean}
         */
        this.normalFillOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawNormalEdgesOpaque}.
         * @property normalEdgesOpaque
         * @type {boolean}
         */
        this.normalEdgesOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawNormalFillTransparent}.
         * @property normalFillTransparent
         * @type {boolean}
         */
        this.normalFillTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawNormalEdgesTransparent}.
         * @property normalEdgesTransparent
         * @type {boolean}
         */
        this.normalEdgesTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawXRayedFillOpaque}.
         * @property xrayedFillOpaque
         * @type {boolean}
         */
        this.xrayedFillOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawXRayedEdgesOpaque}.
         * @property xrayedEdgesOpaque
         * @type {boolean}
         */
        this.xrayedEdgesOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawXRayedFillTransparent}.
         * @property xrayedFillTransparent
         * @type {boolean}
         */
        this.xrayedFillTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #xrayedEdgesTransparent}.
         * @property xrayedEdgesTransparent
         * @type {boolean}
         */
        this.xrayedEdgesTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #drawHighlightedFillOpaque}.
         * @property highlightedFillOpaque
         * @type {boolean}
         */
        this.highlightedFillOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #highlightedEdgesOpaque}.
         * @property highlightedEdgesOpaque
         * @type {boolean}
         */
        this.highlightedEdgesOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #highlightedFillTransparent}.
         * @property highlightedFillTransparent
         * @type {boolean}
         */
        this.highlightedFillTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #highlightedEdgesTransparent}.
         * @property highlightedEdgesTransparent
         * @type {boolean}
         */
        this.highlightedEdgesTransparent = false;


        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #selectedFillOpaque}.
         * @property selectedFillOpaque
         * @type {boolean}
         */
        this.selectedFillOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #selectedEdgesOpaque}.
         * @property selectedEdgesOpaque
         * @type {boolean}
         */
        this.selectedEdgesOpaque = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #selectedFillTransparent}.
         * @property selectedFillTransparent
         * @type {boolean}
         */
        this.selectedFillTransparent = false;

        /**
         * Set by {@link Drawable#getRenderFlags} to indicate the {@link Drawable} needs {@link Drawable #selectedEdgesTransparent}.
         * @property selectedEdgesTransparent
         * @type {boolean}
         */
        this.selectedEdgesTransparent = false;
    }
}

export {RenderFlags};