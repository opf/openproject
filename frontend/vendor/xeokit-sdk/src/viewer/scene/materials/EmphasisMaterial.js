import {Material} from './Material.js';
import {RenderState} from '../webgl/RenderState.js';

const PRESETS = {
    "default": {
        fill: true,
        fillColor: [0.4, 0.4, 0.4],
        fillAlpha: 0.2,
        edges: true,
        edgeColor: [0.2, 0.2, 0.2],
        edgeAlpha: 0.5,
        edgeWidth: 1
    },
    "defaultWhiteBG": {
        fill: true,
        fillColor: [1, 1, 1],
        fillAlpha: 0.6,
        edgeColor: [0.2, 0.2, 0.2],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "defaultLightBG": {
        fill: true,
        fillColor: [0.4, 0.4, 0.4],
        fillAlpha: 0.2,
        edges: true,
        edgeColor: [0.2, 0.2, 0.2],
        edgeAlpha: 0.5,
        edgeWidth: 1
    },
    "defaultDarkBG": {
        fill: true,
        fillColor: [0.4, 0.4, 0.4],
        fillAlpha: 0.2,
        edges: true,
        edgeColor: [0.5, 0.5, 0.5],
        edgeAlpha: 0.5,
        edgeWidth: 1
    },
    "phosphorous": {
        fill: true,
        fillColor: [0.0, 0.0, 0.0],
        fillAlpha: 0.4,
        edges: true,
        edgeColor: [0.9, 0.9, 0.9],
        edgeAlpha: 0.5,
        edgeWidth: 2
    },
    "sunset": {
        fill: true,
        fillColor: [0.9, 0.9, 0.6],
        fillAlpha: 0.2,
        edges: true,
        edgeColor: [0.9, 0.9, 0.9],
        edgeAlpha: 0.5,
        edgeWidth: 1
    },
    "vectorscope": {
        fill: true,
        fillColor: [0.0, 0.0, 0.0],
        fillAlpha: 0.7,
        edges: true,
        edgeColor: [0.2, 1.0, 0.2],
        edgeAlpha: 1,
        edgeWidth: 2
    },
    "battlezone": {
        fill: true,
        fillColor: [0.0, 0.0, 0.0],
        fillAlpha: 1.0,
        edges: true,
        edgeColor: [0.2, 1.0, 0.2],
        edgeAlpha: 1,
        edgeWidth: 3
    },
    "sepia": {
        fill: true,
        fillColor: [0.970588207244873, 0.7965892553329468, 0.6660899519920349],
        fillAlpha: 0.4,
        edges: true,
        edgeColor: [0.529411792755127, 0.4577854573726654, 0.4100345969200134],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "yellowHighlight": {
        fill: true,
        fillColor: [1.0, 1.0, 0.0],
        fillAlpha: 0.5,
        edges: true,
        edgeColor: [0.529411792755127, 0.4577854573726654, 0.4100345969200134],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "greenSelected": {
        fill: true,
        fillColor: [0.0, 1.0, 0.0],
        fillAlpha: 0.5,
        edges: true,
        edgeColor: [0.4577854573726654, 0.529411792755127, 0.4100345969200134],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "gamegrid": {
        fill: true,
        fillColor: [0.2, 0.2, 0.7],
        fillAlpha: 0.9,
        edges: true,
        edgeColor: [0.4, 0.4, 1.6],
        edgeAlpha: 0.8,
        edgeWidth: 3
    }
};

/**
 * Configures the appearance of {@link Entity}s when they are xrayed, highlighted or selected.
 *
 * * XRay an {@link Entity} by setting {@link Entity#xrayed} ````true````.
 * * Highlight an {@link Entity} by setting {@link Entity#highlighted} ````true````.
 * * Select an {@link Entity} by setting {@link Entity#selected} ````true````.
 * * When {@link Entity}s are within the subtree of a root {@link Entity}, then setting {@link Entity#xrayed}, {@link Entity#highlighted} or {@link Entity#selected}
 * on the root will collectively set those properties on all sub-{@link Entity}s.
 * * EmphasisMaterial provides several presets. Select a preset by setting {@link EmphasisMaterial#preset} to the ID of a preset in {@link EmphasisMaterial#presets}.
 * * By default, a {@link Mesh} uses the default EmphasisMaterials in {@link Scene#xrayMaterial}, {@link Scene#highlightMaterial} and {@link Scene#selectedMaterial}
 * but you can assign each {@link Mesh#xrayMaterial}, {@link Mesh#highlightMaterial} or {@link Mesh#selectedMaterial} to a custom EmphasisMaterial, if required.
 *
 * ## Usage
 *
 * In the example below, we'll create a {@link Mesh} with its own XRayMaterial and set {@link Mesh#xrayed} ````true```` to xray it.
 *
 * Recall that {@link Mesh} is a concrete subtype of the abstract {@link Entity} base class.
 *
 * ````javascript
 * new Mesh(viewer.scene, {
 *     geometry: new BoxGeometry(viewer.scene, {
 *         edgeThreshold: 1
 *     }),
 *     material: new PhongMaterial(viewer.scene, {
 *         diffuse: [0.2, 0.2, 1.0]
 *     }),
 *     xrayMaterial: new EmphasisMaterial(viewer.scene, {
 *         fill: true,
 *         fillColor: [0, 0, 0],
 *         fillAlpha: 0.7,
 *         edges: true,
 *         edgeColor: [0.2, 1.0, 0.2],
 *         edgeAlpha: 1.0,
 *         edgeWidth: 2
 *     }),
 *     xrayed: true
 * });
 * ````
 *
 * Note the ````edgeThreshold```` configuration for the {@link ReadableGeometry} on our {@link Mesh}.  EmphasisMaterial configures
 * a wireframe representation of the {@link ReadableGeometry} for the selected emphasis mode, which will have inner edges (those edges between
 * adjacent co-planar triangles) removed for visual clarity. The ````edgeThreshold```` indicates that, for
 * this particular {@link ReadableGeometry}, an inner edge is one where the angle between the surface normals of adjacent triangles
 * is not greater than ````5```` degrees. That's set to ````2```` by default, but we can override it to tweak the effect
 * as needed for particular Geometries.
 *
 * Here's the example again, this time implicitly defaulting to the {@link Scene#edgeMaterial}. We'll also modify that EdgeMaterial
 * to customize the effect.
 *
 * ````javascript
 * new Mesh({
 *     geometry: new TeapotGeometry(viewer.scene, {
 *         edgeThreshold: 5
 *     }),
 *     material: new PhongMaterial(viewer.scene, {
 *         diffuse: [0.2, 0.2, 1.0]
 *     }),
 *     xrayed: true
 * });
 *
 * var xrayMaterial = viewer.scene.xrayMaterial;
 *
 * xrayMaterial.fillColor = [0.2, 1.0, 0.2];
 * xrayMaterial.fillAlpha = 1.0;
 * ````
 *
 * ## Presets
 *
 * Let's switch the {@link Scene#xrayMaterial} to one of the presets in {@link EmphasisMaterial#presets}:
 *
 * ````javascript
 * viewer.xrayMaterial.preset = EmphasisMaterial.presets["sepia"];
 * ````
 *
 * We can also create an EmphasisMaterial from a preset, while overriding properties of the preset as required:
 *
 * ````javascript
 * var myEmphasisMaterial = new EMphasisMaterial(viewer.scene, {
 *      preset: "sepia",
 *      fillColor = [1.0, 0.5, 0.5]
 * });
 * ````
 */
class EmphasisMaterial extends Material {

    /**
     @private
     */
    get type() {
        return "EmphasisMaterial";
    }

    /**
     * Gets available EmphasisMaterial presets.
     *
     * @type {Object}
     */
    get presets() {
        return PRESETS;
    };

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] The EmphasisMaterial configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Boolean} [cfg.fill=true] Indicates if xray surfaces are filled with color.
     * @param {Number[]} [cfg.fillColor=[0.4,0.4,0.4]] EmphasisMaterial fill color.
     * @param  {Number} [cfg.fillAlpha=0.2] Transparency of filled xray faces. A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     * @param {Boolean} [cfg.edges=true] Indicates if xray edges are visible.
     * @param {Number[]} [cfg.edgeColor=[0.2,0.2,0.2]]  RGB color of xray edges.
     * @param {Number} [cfg.edgeAlpha=0.5] Transparency of xray edges. A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     * @param {Number} [cfg.edgeWidth=1] Width of xray edges, in pixels.
     * @param {String} [cfg.preset] Selects a preset EmphasisMaterial configuration - see {@link EmphasisMaterial#presets}.
     * @param {Boolean} [cfg.backfaces=false] Whether to render geometry backfaces when emphasising.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            type: "EmphasisMaterial",
            fill: null,
            fillColor: null,
            fillAlpha: null,
            edges: null,
            edgeColor: null,
            edgeAlpha: null,
            edgeWidth: null,
            backfaces: true
        });

        this._preset = "default";

        if (cfg.preset) { // Apply preset then override with configs where provided
            this.preset = cfg.preset;
            if (cfg.fill !== undefined) {
                this.fill = cfg.fill;
            }
            if (cfg.fillColor) {
                this.fillColor = cfg.fillColor;
            }
            if (cfg.fillAlpha !== undefined) {
                this.fillAlpha = cfg.fillAlpha;
            }
            if (cfg.edges !== undefined) {
                this.edges = cfg.edges;
            }
            if (cfg.edgeColor) {
                this.edgeColor = cfg.edgeColor;
            }
            if (cfg.edgeAlpha !== undefined) {
                this.edgeAlpha = cfg.edgeAlpha;
            }
            if (cfg.edgeWidth !== undefined) {
                this.edgeWidth = cfg.edgeWidth;
            }
            if (cfg.backfaces !== undefined) {
                this.backfaces = cfg.backfaces;
            }
        } else {
            this.fill = cfg.fill;
            this.fillColor = cfg.fillColor;
            this.fillAlpha = cfg.fillAlpha;
            this.edges = cfg.edges;
            this.edgeColor = cfg.edgeColor;
            this.edgeAlpha = cfg.edgeAlpha;
            this.edgeWidth = cfg.edgeWidth;
            this.backfaces = cfg.backfaces;
        }
    }

    /**
     * Sets if surfaces are filled with color.
     *
     * Default is ````true````.
     *
     * @type {Boolean}
     */
    set fill(value) {
        value = value !== false;
        if (this._state.fill === value) {
            return;
        }
        this._state.fill = value;
        this.glRedraw();
    }

    /**
     * Gets if surfaces are filled with color.
     *
     * Default is ````true````.
     *
     * @type {Boolean}
     */
    get fill() {
        return this._state.fill;
    }

    /**
     * Sets the RGB color of filled faces.
     *
     * Default is ````[0.4, 0.4, 0.4]````.
     *
     * @type {Number[]}
     */
    set fillColor(value) {
        let fillColor = this._state.fillColor;
        if (!fillColor) {
            fillColor = this._state.fillColor = new Float32Array(3);
        } else if (value && fillColor[0] === value[0] && fillColor[1] === value[1] && fillColor[2] === value[2]) {
            return;
        }
        if (value) {
            fillColor[0] = value[0];
            fillColor[1] = value[1];
            fillColor[2] = value[2];
        } else {
            fillColor[0] = 0.4;
            fillColor[1] = 0.4;
            fillColor[2] = 0.4;
        }
        this.glRedraw();
    }

    /**
     * Gets the RGB color of filled faces.
     *
     * Default is ````[0.4, 0.4, 0.4]````.
     *
     * @type {Number[]}
     */
    get fillColor() {
        return this._state.fillColor;
    }

    /**
     * Sets the transparency of filled faces.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default is ````0.2````.
     *
     * @type {Number}
     */
    set fillAlpha(value) {
        value = (value !== undefined && value !== null) ? value : 0.2;
        if (this._state.fillAlpha === value) {
            return;
        }
        this._state.fillAlpha = value;
        this.glRedraw();
    }

    /**
     * Gets the transparency of filled faces.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default is ````0.2````.
     *
     * @type {Number}
     */
    get fillAlpha() {
        return this._state.fillAlpha;
    }

    /**
     * Sets if edges are visible.
     *
     * Default is ````true````.
     *
     * @type {Boolean}
     */
    set edges(value) {
        value = value !== false;
        if (this._state.edges === value) {
            return;
        }
        this._state.edges = value;
        this.glRedraw();
    }

    /**
     * Gets if edges are visible.
     *
     * Default is ````true````.
     *
     * @type {Boolean}
     */
    get edges() {
        return this._state.edges;
    }

    /**
     * Sets the RGB color of edges.
     *
     * Default is ```` [0.2, 0.2, 0.2]````.
     *
     * @type {Number[]}
     */
    set edgeColor(value) {
        let edgeColor = this._state.edgeColor;
        if (!edgeColor) {
            edgeColor = this._state.edgeColor = new Float32Array(3);
        } else if (value && edgeColor[0] === value[0] && edgeColor[1] === value[1] && edgeColor[2] === value[2]) {
            return;
        }
        if (value) {
            edgeColor[0] = value[0];
            edgeColor[1] = value[1];
            edgeColor[2] = value[2];
        } else {
            edgeColor[0] = 0.2;
            edgeColor[1] = 0.2;
            edgeColor[2] = 0.2;
        }
        this.glRedraw();
    }

    /**
     * Gets the RGB color of edges.
     *
     * Default is ```` [0.2, 0.2, 0.2]````.
     *
     * @type {Number[]}
     */
    get edgeColor() {
        return this._state.edgeColor;
    }

    /**
     * Sets the transparency of edges.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default is ````0.2````.
     *
     * @type {Number}
     */
    set edgeAlpha(value) {
        value = (value !== undefined && value !== null) ? value : 0.5;
        if (this._state.edgeAlpha === value) {
            return;
        }
        this._state.edgeAlpha = value;
        this.glRedraw();
    }

    /**
     * Gets the transparency of edges.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default is ````0.2````.
     *
     * @type {Number}
     */
    get edgeAlpha() {
        return this._state.edgeAlpha;
    }

    /**
     * Sets edge width.
     *
     * This is not supported by WebGL implementations based on DirectX [2019].
     *
     * Default value is ````1.0```` pixels.
     *
     * @type {Number}
     */
    set edgeWidth(value) {
        this._state.edgeWidth = value || 1.0;
        this.glRedraw();
    }

    /**
     * Gets edge width.
     *
     * This is not supported by WebGL implementations based on DirectX [2019].
     *
     * Default value is ````1.0```` pixels.
     *
     * @type {Number}
     */
    get edgeWidth() {
        return this._state.edgeWidth;
    }

    /**
     * Sets whether to render backfaces when {@link EmphasisMaterial#fill} is ````true````..
     *
     * Default is ````false````.
     *
     * @type {Boolean}
     */
    set backfaces(value) {
        value = !!value;
        if (this._state.backfaces === value) {
            return;
        }
        this._state.backfaces = value;
        this.glRedraw();
    }

    /**
     * Gets whether to render backfaces when {@link EmphasisMaterial#fill} is ````true````..
     *
     * Default is ````false````.
     *
     * @type {Boolean}
     */
    get backfaces() {
        return this._state.backfaces;
    }

    /**
     * Selects a preset EmphasisMaterial configuration.
     *
     * Default value is "default".
     *
     * @type {String}
     */
    set preset(value) {
        value = value || "default";
        if (this._preset === value) {
            return;
        }
        const preset = PRESETS[value];
        if (!preset) {
            this.error("unsupported preset: '" + value + "' - supported values are " + Object.keys(PRESETS).join(", "));
            return;
        }
        this.fill = preset.fill;
        this.fillColor = preset.fillColor;
        this.fillAlpha = preset.fillAlpha;
        this.edges = preset.edges;
        this.edgeColor = preset.edgeColor;
        this.edgeAlpha = preset.edgeAlpha;
        this.edgeWidth = preset.edgeWidth;
        this._preset = value;
    }

    /**
     * Gets the current preset EmphasisMaterial configuration.
     *
     * Default value is "default".
     *
     * @type {String}
     */
    get preset() {
        return this._preset;
    }

    /**
     * Destroys this EmphasisMaterial.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {EmphasisMaterial};