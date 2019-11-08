import {Marker} from "../../viewer/scene/marker/Marker.js";
import {utils} from "../../viewer/scene/utils.js";

/**
 * A {@link Marker} with an HTML label attached to it, managed by an {@link AnnotationsPlugin}.
 *
 * See {@link AnnotationsPlugin} for more info.
 */
class Annotation extends Marker {

    /**
     * @private
     */
    constructor(owner, cfg) {

        super(owner, cfg);

        /**
         * The {@link AnnotationsPlugin} this Annotation was created by.
         * @type {AnnotationsPlugin}
         */
        this.plugin = cfg.plugin;

        this._container = cfg.container;
        if (!this._container) {
            throw "config missing: container";
        }

        if ((!cfg.markerElement) && (!cfg.markerHTML)) {
            throw "config missing: need either markerElement or markerHTML";
        }
        if ((!cfg.labelElement) && (!cfg.labelHTML)) {
            throw "config missing: need either labelElement or labelHTML";
        }

        this._htmlDirty = false;

        if (cfg.markerElement) {
            this._marker = cfg.markerElement;
            this._marker.addEventListener("click", this._onMouseClickedExternalMarker = () => {
                this.plugin.fire("markerClicked", this);
            });
            this._marker.addEventListener("mouseenter", this._onMouseEnterExternalMarker = () => {
                this.plugin.fire("markerMouseEnter", this);
            });
            this._marker.addEventListener("mouseleave", this._onMouseLeaveExternalMarker = () => {
                this.plugin.fire("markerMouseLeave", this);
            });
            this._markerExternal = true; // Don't destroy marker when destroying Annotation
        } else {
            this._markerHTML = cfg.markerHTML;
            this._htmlDirty = true;
            this._markerExternal = false;
        }

        if (cfg.labelElement) {
            this._label = cfg.labelElement;
            this._labelExternal = true; // Don't destroy marker when destroying Annotation
        } else {
            this._labelHTML = cfg.labelHTML;
            this._htmlDirty = true;
            this._labelExternal = false;
        }

        this._markerShown = !!cfg.markerShown;
        this._labelShown = !!cfg.labelShown;
        this._values = cfg.values || {};
        this._layoutDirty = true;
        this._visibilityDirty = true;

        this._buildHTML();

        this._onTick = this.scene.on("tick", () => {
            if (this._htmlDirty) {
                this._buildHTML();
                this._htmlDirty = false;
                this._layoutDirty = true;
                this._visibilityDirty = true;
            }
            if (this._layoutDirty || this._visibilityDirty) {
                if (this._markerShown || this._labelShown) {
                    this._updatePosition();
                    this._layoutDirty = false;
                }
            }
            if (this._visibilityDirty) {
                this._marker.style.visibility = (this.visible && this._markerShown) ? "visible" : "hidden";
                this._label.style.visibility = (this.visible && this._markerShown && this._labelShown) ? "visible" : "hidden";
                this._visibilityDirty = false;
            }
        });

        this.on("canvasPos", () => {
            this._layoutDirty = true;
        });

        this.on("visible", () => {
            this._visibilityDirty = true;
        });

        this.setMarkerShown(cfg.markerShown !== false);
        this.setLabelShown(cfg.labelShown);

        /**
         * Optional World-space position for {@link Camera#eye}, used when this Annotation is associated with a {@link Camera} position.
         *
         * Undefined by default.
         *
         * @type {Number[]} Eye position.
         */
        this.eye = cfg.eye ? cfg.eye.slice() : null;

        /**
         * Optional World-space position for {@link Camera#look}, used when this Annotation is associated with a {@link Camera} position.
         *
         * Undefined by default.
         *
         * @type {Number[]} The "look" vector.
         */
        this.look = cfg.look ? cfg.look.slice() : null;

        /**
         * Optional World-space position for {@link Camera#up}, used when this Annotation is associated with a {@link Camera} position.
         *
         * Undefined by default.
         *
         * @type {Number[]} The "up" vector.
         */
        this.up = cfg.up ? cfg.up.slice() : null;

        /**
         * Optional projection type for {@link Camera#projection}, used when this Annotation is associated with a {@link Camera} position.
         *
         * Undefined by default.
         *
         * @type {String} The projection type - "perspective" or "ortho"..
         */
        this.projection = cfg.projection;
    }

    /**
     * @private
     */
    _buildHTML() {
        if (!this._markerExternal) {
            if (this._marker) {
                this._container.removeChild(this._marker);
                this._marker = null;
            }
            let markerHTML = this._markerHTML || "<p></p>"; // Make marker
            if (utils.isArray(markerHTML)) {
                markerHTML = markerHTML.join("");
            }
            markerHTML = this._renderTemplate(markerHTML);
            const markerFragment = document.createRange().createContextualFragment(markerHTML);
            this._marker = markerFragment.firstChild;
            this._container.appendChild(this._marker);
            this._marker.style.visibility = this._markerShown ? "visible" : "hidden";
            this._marker.addEventListener("click", () => {
                this.plugin.fire("markerClicked", this);
            });
            this._marker.addEventListener("mouseenter", () => {
                this.plugin.fire("markerMouseEnter", this);
            });
            this._marker.addEventListener("mouseleave", () => {
                this.plugin.fire("markerMouseLeave", this);
            });
        }
        if (!this._labelExternal) {
            if (this._label) {
                this._container.removeChild(this._label);
                this._label = null;
            }
            let labelHTML = this._labelHTML || "<p></p>"; // Make label
            if (utils.isArray(labelHTML)) {
                labelHTML = labelHTML.join("");
            }
            labelHTML = this._renderTemplate(labelHTML);
            const labelFragment = document.createRange().createContextualFragment(labelHTML);
            this._label = labelFragment.firstChild;
            this._container.appendChild(this._label);
            this._label.style.visibility = (this._markerShown && this._labelShown) ? "visible" : "hidden";
        }
    }

    /**
     * @private
     */
    _updatePosition() {
        const boundary = this.scene.canvas.boundary;
        const left = boundary[0];
        const top = boundary[1];
        const canvasPos = this.canvasPos;
        this._marker.style.left = (Math.floor(left + canvasPos[0]) - 12) + "px";
        this._marker.style.top = (Math.floor(top + canvasPos[1]) - 12) + "px";
        this._marker.style["z-index"] = 90005 + Math.floor(this._viewPos[2] * 10) + 1;
        const offsetX = 20;
        const offsetY = -17;
        this._label.style.left = 20 + Math.floor(left + canvasPos[0] + offsetX) + "px";
        this._label.style.top = Math.floor(top + canvasPos[1] + offsetY) + "px";
        this._label.style["z-index"] = 90005 + Math.floor(this._viewPos[2] * 10) + 1;
    }

    /**
     * @private
     */
    _renderTemplate(template) {
        for (var key in this._values) {
            if (this._values.hasOwnProperty(key)) {
                const value = this._values[key];
                template = template.replace(new RegExp('{{' + key + '}}', 'g'), value);
            }
        }
        return template;
    }

    /**
     * Sets whether or not to show this Annotation's marker.
     *
     * The marker shows the Annotation's position.
     *
     * The marker is only visible when both this property and {@link Annotation#visible} are ````true````.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @param {Boolean} shown Whether to show the marker.
     */
    setMarkerShown(shown) {
        shown = !!shown;
        if (this._markerShown === shown) {
            return;
        }
        this._markerShown = shown;
        this._visibilityDirty = true;
    }

    /**
     * Gets whether or not to show this Annotation's marker.
     *
     * The marker shows the Annotation's position.
     *
     * The marker is only visible when both this property and {@link Annotation#visible} are ````true````.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @returns {Boolean} Whether to show the marker.
     */
    getMarkerShown() {
        return this._markerShown;
    }

    /**
     * Sets whether or not to show this Annotation's label.
     *
     * The label is only visible when both this property and {@link Annotation#visible} are ````true````.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @param {Boolean} shown Whether to show the label.
     */
    setLabelShown(shown) {
        shown = !!shown;
        if (this._labelShown === shown) {
            return;
        }
        this._labelShown = shown;
        this._visibilityDirty = true;
    }

    /**
     * Gets whether or not to show this Annotation's label.
     *
     * The label is only visible when both this property and {@link Annotation#visible} are ````true````.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @returns {Boolean} Whether to show the label.
     */
    getLabelShown() {
        return this._labelShown;
    }

    /**
     * Sets the value of a field within the HTML templates for either the Annotation's marker or label.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @param {String} key Identifies the field.
     * @param {String} value The field's value.
     */
    setField(key, value) {
        this._values[key] = value || "";
        this._htmlDirty = true;
    }

    /**
     * Gets the value of a field within the HTML templates for either the Annotation's marker or label.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @param {String} key Identifies the field.
     * @returns {String} The field's value.
     */
    getField(key) {
        return this._values[key];
    }

    /**
     * Sets values for multiple placeholders within the Annotation's HTML templates for marker and label.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @param {{String:(String|Number)}} values Map of field values.
     */
    setValues(values) {
        for (var key in values) {
            if (values.hasOwnProperty(key)) {
                const value = values[key];
                this.setField(key, value);
            }
        }
    }

    /**
     * Gets the values that were set for the placeholders within this Annotation's HTML marker and label templates.
     *
     * See {@link AnnotationsPlugin} for more info.
     *
     * @RETURNS {{String:(String|Number)}} Map of field values.
     */
    getValues() {
        return this._values;
    }

    /**
     * Destroys this Annotation.
     *
     * You can also call {@link AnnotationsPlugin#destroyAnnotation}.
     */
    destroy() {
        if (this._marker) {
            if (!this._markerExternal) {
                this._marker.parentNode.removeChild(this._marker);
            } else {
                this._marker.removeEventListener("click", this._onMouseClickedExternalMarker);
                this._marker.removeEventListener("mouseenter", this._onMouseEnterExternalMarker);
                this._marker.removeEventListener("mouseleave", this._onMouseLeaveExternalMarker);
                this._marker = null;
            }
        }
        if (this._label) {
            if (!this._labelExternal) {
                this._label.parentNode.removeChild(this._label);
            }
            this._label = null;
        }
        this.scene.off(this._onTick);
        super.destroy();
    }
}

export {Annotation};