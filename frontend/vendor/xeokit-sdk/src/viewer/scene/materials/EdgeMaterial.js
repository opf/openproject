import {Material} from './Material.js';
import {RenderState} from '../webgl/RenderState.js';

const PRESETS = {
    "default": {
        edgeColor: [0.0, 0.0, 0.0],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "defaultWhiteBG": {
        edgeColor: [0.2, 0.2, 0.2],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "defaultLightBG": {
        edgeColor: [0.2, 0.2, 0.2],
        edgeAlpha: 1.0,
        edgeWidth: 1
    },
    "defaultDarkBG": {
        edgeColor: [0.5, 0.5, 0.5],
        edgeAlpha: 1.0,
        edgeWidth: 1
    }
};

/**
 * @desc Configures the appearance of {@link Entity}s when their edges are emphasised.
 *
 * * Emphasise edges of an {@link Entity} by setting {@link Entity#edges} ````true````.
 * * When {@link Entity}s are within the subtree of a root {@link Entity}, then setting {@link Entity#edges} on the root
 * will collectively set that property on all sub-{@link Entity}s.
 * * EdgeMaterial provides several presets. Select a preset by setting {@link EdgeMaterial#preset} to the ID of a preset in {@link EdgeMaterial#presets}.
 * * By default, a {@link Mesh} uses the default EdgeMaterial in {@link Scene#edgeMaterial}, but you can assign each {@link Mesh#edgeMaterial} to a custom EdgeMaterial if required.
 *
 * ## Usage
 *
 * In the example below, we'll create a {@link Mesh} with its own EdgeMaterial and set {@link Mesh#edges} ````true```` to emphasise its edges.
 *
 * Recall that {@link Mesh} is a concrete subtype of the abstract {@link Entity} base class.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#materials_EdgeMaterial)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildSphereGeometry} from "../src/scene/geometry/builders/buildSphereGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {EdgeMaterial} from "../src/scene/materials/EdgeMaterial.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas",
 *      transparent: true
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *
 *      geometry: new ReadableGeometry(viewer.scene, buildSphereGeometry({
 *          radius: 1.5,
 *          heightSegments: 24,
 *          widthSegments: 16,
 *          edgeThreshold: 2 // Default is 10
 *      })),
 *
 *      material: new PhongMaterial(viewer.scene, {
 *          diffuse: [0.4, 0.4, 1.0],
 *          ambient: [0.9, 0.3, 0.9],
 *          shininess: 30,
 *          alpha: 0.5,
 *          alphaMode: "blend"
 *      }),
 *
 *      edgeMaterial: new EdgeMaterial(viewer.scene, {
 *          edgeColor: [0.0, 0.0, 1.0]
 *          edgeAlpha: 1.0,
 *          edgeWidth: 2
 *      }),
 *
 *      edges: true
 * });
 * ````
 *
 * Note the ````edgeThreshold```` configuration for the {@link ReadableGeometry} on our {@link Mesh}.  EdgeMaterial configures
 * a wireframe representation of the {@link ReadableGeometry}, which will have inner edges (those edges between
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
 *     geometry: new ReadableGeometry(viewer.scene, buildSphereGeometry({
 *          radius: 1.5,
 *          heightSegments: 24,
 *          widthSegments: 16,
 *          edgeThreshold: 2 // Default is 10
 *      })),
 *     material: new PhongMaterial(viewer.scene, {
 *         diffuse: [0.2, 0.2, 1.0]
 *     }),
 *     edges: true
 * });
 *
 * var edgeMaterial = viewer.scene.edgeMaterial;
 *
 * edgeMaterial.edgeColor = [0.2, 1.0, 0.2];
 * edgeMaterial.edgeAlpha = 1.0;
 * edgeMaterial.edgeWidth = 2;
 * ````
 *
 *  ## Presets
 *
 * Let's switch the {@link Scene#edgeMaterial} to one of the presets in {@link EdgeMaterial#presets}:
 *
 * ````javascript
 * viewer.edgeMaterial.preset = EdgeMaterial.presets["sepia"];
 * ````
 *
 * We can also create an EdgeMaterial from a preset, while overriding properties of the preset as required:
 *
 * ````javascript
 * var myEdgeMaterial = new EdgeMaterial(viewer.scene, {
 *      preset: "sepia",
 *      edgeColor = [1.0, 0.5, 0.5]
 * });
 * ````
 */
class EdgeMaterial extends Material {

    /**
     @private
     */
    get type() {
        return "EdgeMaterial";
    }

    /**
     * Gets available EdgeMaterial presets.
     *
     * @type {Object}
     */
    get presets() {
        return PRESETS;
    };

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] The EdgeMaterial configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Number[]} [cfg.edgeColor=[0.2,0.2,0.2]] RGB edge color.
     * @param {Number} [cfg.edgeAlpha=1.0] Edge transparency. A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     * @param {Number} [cfg.edgeWidth=1] Edge width in pixels.
     * @param {String} [cfg.preset] Selects a preset EdgeMaterial configuration - see {@link EdgeMaterial#presets}.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            type: "EdgeMaterial",
            edgeColor: null,
            edgeAlpha: null,
            edgeWidth: null
        });

        this._preset = "default";

        if (cfg.preset) { // Apply preset then override with configs where provided
            this.preset = cfg.preset;
            if (cfg.edgeColor) {
                this.edgeColor = cfg.edgeColor;
            }
            if (cfg.edgeAlpha !== undefined) {
                this.edgeAlpha = cfg.edgeAlpha;
            }
            if (cfg.edgeWidth !== undefined) {
                this.edgeWidth = cfg.edgeWidth;
            }
        } else {
            this.edgeColor = cfg.edgeColor;
            this.edgeAlpha = cfg.edgeAlpha;
            this.edgeWidth = cfg.edgeWidth;
        }
    }


    /**
     * Sets RGB edge color.
     *
     * Default value is ````[0.2, 0.2, 0.2]````.
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
     * Gets RGB edge color.
     *
     * Default value is ````[0.2, 0.2, 0.2]````.
     *
     * @type {Number[]}
     */
    get edgeColor() {
        return this._state.edgeColor;
    }

    /**
     * Sets edge transparency.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set edgeAlpha(value) {
        value = (value !== undefined && value !== null) ? value : 1.0;
        if (this._state.edgeAlpha === value) {
            return;
        }
        this._state.edgeAlpha = value;
        this.glRedraw();
    }

    /**
     * Gets edge transparency.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default value is ````1.0````.
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
     * Selects a preset EdgeMaterial configuration.
     *
     * Default value is ````"default"````.
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
        this.edgeColor = preset.edgeColor;
        this.edgeAlpha = preset.edgeAlpha;
        this.edgeWidth = preset.edgeWidth;
        this._preset = value;
    }

    /**
     * The current preset EdgeMaterial configuration.
     *
     * Default value is ````"default"````.
     *
     * @type {String}
     */
    get preset() {
        return this._preset;
    }

    /**
     * Destroys this EdgeMaterial.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {EdgeMaterial};