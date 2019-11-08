import {Material} from './Material.js';
import {RenderState} from '../webgl/RenderState.js';
import {math} from '../math/math.js';

/**
 * @desc Configures the normal rendered appearance of {@link Mesh}es using the non-realistic but GPU-efficient <a href="https://en.wikipedia.org/wiki/Lambertian_reflectance">Lambertian</a> flat shading model for calculating reflectance.
 *
 * * Useful for efficiently rendering non-realistic objects for high-detail CAD.
 * * Use  {@link PhongMaterial} when you need specular highlights.
 * * Use the physically-based {@link MetallicMaterial} or {@link SpecularMaterial} when you need more realism.
 * * For LambertMaterial, the illumination calculation is performed at each triangle vertex, and the resulting color is interpolated across the face of the triangle. For {@link PhongMaterial}, {@link MetallicMaterial} and
 * {@link SpecularMaterial}, vertex normals are interpolated across the surface of the triangle, and the illumination calculation is performed at each texel.
 *
 * ## Usage
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#materials_LambertMaterial)]
 *
 * In the example below we'll create a {@link Mesh} with a shape defined by a {@link buildTorusGeometry} and normal rendering appearance configured with a LambertMaterial.
 *
 * ```` javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildTorusGeometry} from "../src/scene/geometry/builders/buildTorusGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {LambertMaterial} from "../src/scene/materials/LambertMaterial.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildTorusGeometry({
 *          center: [0, 0, 0],
 *          radius: 1.5,
 *          tube: 0.5,
 *          radialSegments: 12,
 *          tubeSegments: 8,
 *          arc: Math.PI * 2.0
 *      }),
 *      material: new LambertMaterial(viewer.scene, {
 *          ambient: [0.3, 0.3, 0.3],
 *          color: [0.5, 0.5, 0.0],
 *          alpha: 1.0, // Default
 *          lineWidth: 1,
 *          pointSize: 1,
 *          backfaces: false,
 *          frontFace: "ccw"
 *      })
 *  });
 * ````
 *
 * ## LambertMaterial Properties
 *
 * The following table summarizes LambertMaterial properties:
 *
 *  | Property | Type | Range | Default Value | Space | Description |
 *  |:--------:|:----:|:-----:|:-------------:|:-----:|:-----------:|
 *  | {@link LambertMaterial#ambient} | Array | [0, 1] for all components | [1,1,1,1] | linear | The RGB components of the ambient light reflected by the material. |
 *  | {@link LambertMaterial#color} | Array | [0, 1] for all components | [1,1,1,1] | linear | The RGB components of the diffuse light reflected by the material. |
 *  | {@link LambertMaterial#emissive} | Array | [0, 1] for all components | [0,0,0] | linear | The RGB components of the light emitted by the material. |
 *  | {@link LambertMaterial#alpha} | Number | [0, 1] | 1 | linear | The transparency of the material surface (0 fully transparent, 1 fully opaque). |
 *  | {@link LambertMaterial#lineWidth} | Number | [0..100] | 1 |  | Line width in pixels. |
 *  | {@link LambertMaterial#pointSize} | Number | [0..100] | 1 |  | Point size in pixels. |
 *  | {@link LambertMaterial#backfaces} | Boolean |  | false |  | Whether to render {@link Geometry} backfaces. |
 *  | {@link LambertMaterial#frontface} | String | "ccw", "cw" | "ccw" |  | The winding order for {@link Geometry} frontfaces - "cw" for clockwise, or "ccw" for counter-clockwise. |
 *
 */
class LambertMaterial extends Material {

    /**
     @private
     */
    get type() {
        return "LambertMaterial";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] The LambertMaterial configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {String:Object} [cfg.meta=null]  Metadata to attach to this LambertMaterial.
     * @param {Number[]} [cfg.ambient=[1.0, 1.0, 1.0 ]] LambertMaterial ambient color.
     * @param {Number[]} [cfg.color=[ 1.0, 1.0, 1.0 ]] LambertMaterial diffuse color.
     * @param {Number[]} [cfg.emissive=[ 0.0, 0.0, 0.0 ]] LambertMaterial emissive color.
     * @param {Number} [cfg.alpha=1]Scalar in range 0-1 that controls alpha, where 0 is completely transparent and 1 is completely opaque.
     * @param {Number} [cfg.reflectivity=1]Scalar in range 0-1 that controls how much {@link ReflectionMap} is reflected.
     * @param {Number} [cfg.lineWidth=1] Scalar that controls the width of {@link Geometry} lines.
     * @param {Number} [cfg.pointSize=1] Scalar that controls the size of points for {@link Geometry} with {@link Geometry#primitive} set to "points".
     * @param {Boolean} [cfg.backfaces=false] Whether to render {@link Geometry} backfaces.
     * @param {Boolean} [cfg.frontface="ccw"] The winding order for {@link Geometry} front faces - "cw" for clockwise, or "ccw" for counter-clockwise.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            type: "LambertMaterial",
            ambient: math.vec3([1.0, 1.0, 1.0]),
            color: math.vec3([1.0, 1.0, 1.0]),
            emissive: math.vec3([0.0, 0.0, 0.0]),
            alpha: null,
            alphaMode: 0, // 2 ("blend") when transparent, so renderer knows when to add to transparency bin
            lineWidth: null,
            pointSize: null,
            backfaces: null,
            frontface: null, // Boolean for speed; true == "ccw", false == "cw"
            hash: "/lam;"
        });

        this.ambient = cfg.ambient;
        this.color = cfg.color;
        this.emissive = cfg.emissive;
        this.alpha = cfg.alpha;
        this.lineWidth = cfg.lineWidth;
        this.pointSize = cfg.pointSize;
        this.backfaces = cfg.backfaces;
        this.frontface = cfg.frontface;
    }

    /**
     * Sets the LambertMaterial's ambient color.
     *
     * Default value is ````[0.3, 0.3, 0.3]````.
     *
     * @type {Number[]}
     */
    set ambient(value) {
        let ambient = this._state.ambient;
        if (!ambient) {
            ambient = this._state.ambient = new Float32Array(3);
        } else if (value && ambient[0] === value[0] && ambient[1] === value[1] && ambient[2] === value[2]) {
            return;
        }
        if (value) {
            ambient[0] = value[0];
            ambient[1] = value[1];
            ambient[2] = value[2];
        } else {
            ambient[0] = .2;
            ambient[1] = .2;
            ambient[2] = .2;
        }
        this.glRedraw();
    }

    /**
     * Gets the LambertMaterial's ambient color.
     *
     * Default value is ````[0.3, 0.3, 0.3]````.
     *
     * @type {Number[]}
     */
    get ambient() {
        return this._state.ambient;
    }

    /**
     * Sets the LambertMaterial's diffuse color.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @type {Number[]}
     */
    set color(value) {
        let color = this._state.color;
        if (!color) {
            color = this._state.color = new Float32Array(3);
        } else if (value && color[0] === value[0] && color[1] === value[1] && color[2] === value[2]) {
            return;
        }
        if (value) {
            color[0] = value[0];
            color[1] = value[1];
            color[2] = value[2];
        } else {
            color[0] = 1;
            color[1] = 1;
            color[2] = 1;
        }
        this.glRedraw();
    }

    /**
     * Gets the LambertMaterial's diffuse color.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @type {Number[]}
     */
    get color() {
        return this._state.color;
    }

    /**
     * Sets the LambertMaterial's emissive color.
     *
     * Default value is ````[0.0, 0.0, 0.0]````.
     *
     * @type {Number[]}
     */
    set emissive(value) {
        let emissive = this._state.emissive;
        if (!emissive) {
            emissive = this._state.emissive = new Float32Array(3);
        } else if (value && emissive[0] === value[0] && emissive[1] === value[1] && emissive[2] === value[2]) {
            return;
        }
        if (value) {
            emissive[0] = value[0];
            emissive[1] = value[1];
            emissive[2] = value[2];
        } else {
            emissive[0] = 0;
            emissive[1] = 0;
            emissive[2] = 0;
        }
        this.glRedraw();
    }

    /**
     * Gets the LambertMaterial's emissive color.
     *
     * Default value is ````[0.0, 0.0, 0.0]````.
     *
     * @type {Number[]}
     */
    get emissive() {
        return this._state.emissive;
    }

    /**
     * Sets factor in the range ````[0..1]```` indicating how transparent the LambertMaterial is.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default value is ````1.0````
     *
     * @type {Number}
     */
    set alpha(value) {
        value = (value !== undefined && value !== null) ? value : 1.0;
        if (this._state.alpha === value) {
            return;
        }
        this._state.alpha = value;
        this._state.alphaMode = value < 1.0 ? 2 /* blend */ : 0
        /* opaque */
        this.glRedraw();
    }

    /**
     * Gets factor in the range ````[0..1]```` indicating how transparent the LambertMaterial is.
     *
     * A value of ````0.0```` indicates fully transparent, ````1.0```` is fully opaque.
     *
     * Default value is ````1.0````
     *
     * @type {Number}
     */
    get alpha() {
        return this._state.alpha;
    }

    /**
     * Sets the LambertMaterial's line width.
     *
     * This is not supported by WebGL implementations based on DirectX [2019].
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set lineWidth(value) {
        this._state.lineWidth = value || 1.0;
        this.glRedraw();
    }

    /**
     * Gets the LambertMaterial's line width.
     *
     * This is not supported by WebGL implementations based on DirectX [2019].
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    get lineWidth() {
        return this._state.lineWidth;
    }

    /**
     * Sets the LambertMaterial's point size.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set pointSize(value) {
        this._state.pointSize = value || 1.0;
        this.glRedraw();
    }

    /**
     * Gets the LambertMaterial's point size.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    get pointSize() {
        return this._state.pointSize;
    }

    /**
     * Sets whether backfaces are visible on attached {@link Mesh}es.
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
     * Gets whether backfaces are visible on attached {@link Mesh}es.
     *
     * @type {Boolean}
     */
    get backfaces() {
        return this._state.backfaces;
    }

    /**
     * Sets the winding direction of front faces of {@link Geometry} of attached {@link Mesh}es.
     *
     * Default value is ````"ccw"````.
     *
     * @type {String}
     */
    set frontface(value) {
        value = value !== "cw";
        if (this._state.frontface === value) {
            return;
        }
        this._state.frontface = value;
        this.glRedraw();
    }

    /**
     * Gets the winding direction of front faces of {@link Geometry} of attached {@link Mesh}es.
     *
     * Default value is ````"ccw"````.
     *
     * @type {String}
     */
    get frontface() {
        return this._state.frontface ? "ccw" : "cw";
    }

    _getState() {
        return this._state;
    }

    /**
     * Destroys this LambertMaterial.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {LambertMaterial};