import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {Texture2D} from '../webgl/Texture2D.js';
import {math} from '../math/math.js';
import {stats} from '../stats.js';

function ensureImageSizePowerOfTwo(image) {
    if (!isPowerOfTwo(image.width) || !isPowerOfTwo(image.height)) {
        const canvas = document.createElement("canvas");
        canvas.width = nextHighestPowerOfTwo(image.width);
        canvas.height = nextHighestPowerOfTwo(image.height);
        const ctx = canvas.getContext("2d");
        ctx.drawImage(image,
            0, 0, image.width, image.height,
            0, 0, canvas.width, canvas.height);
        image = canvas;
    }
    return image;
}

function isPowerOfTwo(x) {
    return (x & (x - 1)) === 0;
}

function nextHighestPowerOfTwo(x) {
    --x;
    for (let i = 1; i < 32; i <<= 1) {
        x = x | x >> i;
    }
    return x + 1;
}

/**
 * @desc A 2D texture map.
 *
 * * Textures are attached to {@link Material}s, which are attached to {@link Mesh}es.
 * * To create a Texture from an image file, set {@link Texture#src} to the image file path.
 * * To create a Texture from an HTMLImageElement, set the Texture's {@link Texture#image} to the HTMLImageElement.
 *
 * ## Usage
 *
 * In this example we have a Mesh with a {@link PhongMaterial} which applies diffuse {@link Texture}, and a {@link buildTorusGeometry} which builds a {@link ReadableGeometry}.
 *
 * Note that xeokit will ignore {@link PhongMaterial#diffuse} and {@link PhongMaterial#specular}, since we override those
 * with {@link PhongMaterial#diffuseMap} and {@link PhongMaterial#specularMap}. The {@link Texture} pixel colors directly
 * provide the diffuse and specular components for each fragment across the {@link ReadableGeometry} surface.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#materials_Texture)]
 *
 * ```` javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildTorusGeometry} from "../src/scene/geometry/builders/buildTorusGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.camera.eye = [0, 0, 5];
 * viewer.camera.look = [0, 0, 0];
 * viewer.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildTorusGeometry({
 *          center: [0, 0, 0],
 *          radius: 1.5,
 *          tube: 0.5,
 *          radialSegments: 32,
 *          tubeSegments: 24,
 *          arc: Math.PI * 2.0
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          ambient: [0.9, 0.3, 0.9],
 *          shininess: 30,
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          })
 *      })
 * });
 *````
 */
class Texture extends Component {

    /**
     @private
     */
    get type() {
        return "Texture";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this Texture as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID for this Texture, unique among all components in the parent scene, generated automatically when omitted.
     * @param {String} [cfg.src=null] Path to image file to load into this Texture. See the {@link Texture#src} property for more info.
     * @param {HTMLImageElement} [cfg.image=null] HTML Image object to load into this Texture. See the {@link Texture#image} property for more info.
     * @param {String} [cfg.minFilter="linearMipmapLinear"] How the texture is sampled when a texel covers less than one pixel. See the {@link Texture#minFilter} property for more info.
     * @param {String} [cfg.magFilter="linear"] How the texture is sampled when a texel covers more than one pixel. See the {@link Texture#magFilter} property for more info.
     * @param {String} [cfg.wrapS="repeat"] Wrap parameter for texture coordinate *S*. See the {@link Texture#wrapS} property for more info.
     * @param {String} [cfg.wrapT="repeat"] Wrap parameter for texture coordinate *S*. See the {@link Texture#wrapT} property for more info.
     * @param {Boolean} [cfg.flipY=false] Flips this Texture's source data along its vertical axis when true.
     * @param {Number[]} [cfg.translate=[0,0]] 2D translation vector that will be added to texture's *S* and *T* coordinates.
     * @param {Number[]} [cfg.scale=[1,1]] 2D scaling vector that will be applied to texture's *S* and *T* coordinates.
     * @param {Number} [cfg.rotate=0] Rotation, in degrees, that will be applied to texture's *S* and *T* coordinates.
     * @param  {String} [cfg.encoding="linear"] Encoding format.  See the {@link Texture#encoding} property for more info.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            texture: new Texture2D(this.scene.canvas.gl),
            matrix: math.identityMat4(),   // Float32Array
            hasMatrix: (cfg.translate && (cfg.translate[0] !== 0 || cfg.translate[1] !== 0)) || (!!cfg.rotate) || (cfg.scale && (cfg.scale[0] !== 0 || cfg.scale[1] !== 0)),
            minFilter: this._checkMinFilter(cfg.minFilter),
            magFilter: this._checkMagFilter(cfg.magFilter),
            wrapS: this._checkWrapS(cfg.wrapS),
            wrapT: this._checkWrapT(cfg.wrapT),
            flipY: this._checkFlipY(cfg.flipY),
            encoding: this._checkEncoding(cfg.encoding)
        });

        // Data source

        this._src = null;
        this._image = null;

        // Transformation

        this._translate = math.vec2([0, 0]);
        this._scale = math.vec2([1, 1]);
        this._rotate = math.vec2([0, 0]);

        this._matrixDirty = false;

        // Transform

        this.translate = cfg.translate;
        this.scale = cfg.scale;
        this.rotate = cfg.rotate;

        // Data source

        if (cfg.src) {
            this.src = cfg.src; // Image file
        } else if (cfg.image) {
            this.image = cfg.image; // Image object
        }

        stats.memory.textures++;
    }

    _checkMinFilter(value) {
        value = value || "linearMipmapLinear";
        if (value !== "linear" &&
            value !== "linearMipmapNearest" &&
            value !== "linearMipmapLinear" &&
            value !== "nearestMipmapLinear" &&
            value !== "nearestMipmapNearest") {
            this.error("Unsupported value for 'minFilter': '" + value +
                "' - supported values are 'linear', 'linearMipmapNearest', 'nearestMipmapNearest', " +
                "'nearestMipmapLinear' and 'linearMipmapLinear'. Defaulting to 'linearMipmapLinear'.");
            value = "linearMipmapLinear";
        }
        return value;
    }

    _checkMagFilter(value) {
        value = value || "linear";
        if (value !== "linear" && value !== "nearest") {
            this.error("Unsupported value for 'magFilter': '" + value +
                "' - supported values are 'linear' and 'nearest'. Defaulting to 'linear'.");
            value = "linear";
        }
        return value;
    }

    _checkFilter(value) {
        value = value || "linear";
        if (value !== "linear" && value !== "nearest") {
            this.error("Unsupported value for 'magFilter': '" + value +
                "' - supported values are 'linear' and 'nearest'. Defaulting to 'linear'.");
            value = "linear";
        }
        return value;
    }

    _checkWrapS(value) {
        value = value || "repeat";
        if (value !== "clampToEdge" && value !== "mirroredRepeat" && value !== "repeat") {
            this.error("Unsupported value for 'wrapS': '" + value +
                "' - supported values are 'clampToEdge', 'mirroredRepeat' and 'repeat'. Defaulting to 'repeat'.");
            value = "repeat";
        }
        return value;
    }

    _checkWrapT(value) {
        value = value || "repeat";
        if (value !== "clampToEdge" && value !== "mirroredRepeat" && value !== "repeat") {
            this.error("Unsupported value for 'wrapT': '" + value +
                "' - supported values are 'clampToEdge', 'mirroredRepeat' and 'repeat'. Defaulting to 'repeat'.");
            value = "repeat";
        }
        return value;
    }

    _checkFlipY(value) {
        return !!value;
    }

    _checkEncoding(value) {
        value = value || "linear";
        if (value !== "linear" && value !== "sRGB" && value !== "gamma") {
            this.error("Unsupported value for 'encoding': '" + value + "' - supported values are 'linear', 'sRGB', 'gamma'. Defaulting to 'linear'.");
            value = "linear";
        }
        return value;
    }

    _webglContextRestored() {
        this._state.texture = new Texture2D(this.scene.canvas.gl);
        if (this._image) {
            this.image = this._image;
        } else if (this._src) {
            this.src = this._src;
        }
    }

    _update() {
        const state = this._state;
        if (this._matrixDirty) {
            let matrix;
            let t;
            if (this._translate[0] !== 0 || this._translate[1] !== 0) {
                matrix = math.translationMat4v([this._translate[0], this._translate[1], 0], this._state.matrix);
            }
            if (this._scale[0] !== 1 || this._scale[1] !== 1) {
                t = math.scalingMat4v([this._scale[0], this._scale[1], 1]);
                matrix = matrix ? math.mulMat4(matrix, t) : t;
            }
            if (this._rotate !== 0) {
                t = math.rotationMat4v(this._rotate * 0.0174532925, [0, 0, 1]);
                matrix = matrix ? math.mulMat4(matrix, t) : t;
            }
            if (matrix) {
                state.matrix = matrix;
            }
            this._matrixDirty = false;
        }
        this.glRedraw();
    }


    /**
     * Sets an HTML DOM Image object to source this Texture from.
     *
     * Sets {@link Texture#src} null.
     *
     * @type {HTMLImageElement}
     */
    set image(value) {
        this._image = ensureImageSizePowerOfTwo(value);
        this._image.crossOrigin = "Anonymous";
        this._state.texture.setImage(this._image, this._state);
        this._state.texture.setProps(this._state); // Generate mipmaps
        this._src = null;
        this.glRedraw();
    }

    /**
     * Gets HTML DOM Image object this Texture is sourced from, if any.
     *
     * Returns null if not set.
     *
     * @type {HTMLImageElement}
     */
    get image() {
        return this._image;
    }

    /**
     * Sets path to an image file to source this Texture from.
     *
     * Sets {@link Texture#image} null.
     *
     * @type {String}
     */
    set src(src) {
        this.scene.loading++;
        this.scene.canvas.spinner.processes++;
        const self = this;
        let image = new Image();
        image.onload = function () {
            image = ensureImageSizePowerOfTwo(image);
            //self._image = image; // For faster WebGL context restore - memory inefficient?
            self._state.texture.setImage(image, self._state);
            self._state.texture.setProps(self._state); // Generate mipmaps
            self.scene.loading--;
            self.scene.canvas.spinner.processes--;
            self.glRedraw();
        };
        image.src = src;
        this._src = src;
        this._image = null;
    }

    /**
     * Gets path to the image file this Texture from, if any.
     *
     * Returns null if not set.
     *
     * @type {String}
     */
    get src() {
        return this._src;
    }

    /**
     * Sets the 2D translation vector added to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````[0, 0]````.
     *
     * @type {Number[]}
     */
    set translate(value) {
        this._translate.set(value || [0, 0]);
        this._matrixDirty = true;
        this._needUpdate();
    }

    /**
     * Gets the 2D translation vector added to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````[0, 0]````.
     *
     * @type {Number[]}
     */
    get translate() {
        return this._translate;
    }

    /**
     * Sets the 2D scaling vector that will be applied to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````[1, 1]````.
     *
     * @type {Number[]}
     */
    set scale(value) {
        this._scale.set(value || [1, 1]);
        this._matrixDirty = true;
        this._needUpdate();
    }

    /**
     * Gets the 2D scaling vector that will be applied to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````[1, 1]````.
     *
     * @type {Number[]}
     */
    get scale() {
        return this._scale;
    }

    /**
     * Sets the rotation angles, in degrees, that will be applied to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````0````.
     *
     * @type {Number}
     */
    set rotate(value) {
        value = value || 0;
        if (this._rotate === value) {
            return;
        }
        this._rotate = value;
        this._matrixDirty = true;
        this._needUpdate();
    }

    /**
     * Gets the rotation angles, in degrees, that will be applied to this Texture's *S* and *T* UV coordinates.
     *
     * Default value is ````0````.
     *
     * @type {Number}
     */
    get rotate() {
        return this._rotate;
    }

    /**
     * Gets how this Texture is sampled when a texel covers less than one pixel.
     *
     * Options are:
     *
     * * "nearest" - Uses the value of the texture element that is nearest
     * (in Manhattan distance) to the center of the pixel being textured.
     *
     * * "linear" - Uses the weighted average of the four texture elements that are
     * closest to the center of the pixel being textured.
     *
     * * "nearestMipmapNearest" - Chooses the mipmap that most closely matches the
     * size of the pixel being textured and uses the "nearest" criterion (the texture
     * element nearest to the center of the pixel) to produce a texture value.
     *
     * * "linearMipmapNearest" - Chooses the mipmap that most closely matches the size of
     * the pixel being textured and uses the "linear" criterion (a weighted average of the
     * four texture elements that are closest to the center of the pixel) to produce a
     * texture value.
     *
     * * "nearestMipmapLinear" - Chooses the two mipmaps that most closely
     * match the size of the pixel being textured and uses the "nearest" criterion
     * (the texture element nearest to the center of the pixel) to produce a texture
     * value from each mipmap. The final texture value is a weighted average of those two
     * values.
     *
     * * "linearMipmapLinear" - (default) - Chooses the two mipmaps that most closely match the size
     * of the pixel being textured and uses the "linear" criterion (a weighted average
     * of the four texture elements that are closest to the center of the pixel) to
     * produce a texture value from each mipmap. The final texture value is a weighted
     * average of those two values.
     *
     * Default value is "linearMipmapLinear".
     *
     *  @type {String}
     */
    get minFilter() {
        return this._state.minFilter;
    }

    /**
     * Gets how this Texture is sampled when a texel covers more than one pixel.
     *
     * * "nearest" - Uses the value of the texture element that is nearest
     * (in Manhattan distance) to the center of the pixel being textured.
     * * "linear" - (default) - Uses the weighted average of the four texture elements that are
     * closest to the center of the pixel being textured.
     *
     * Default value is "linearMipmapLinear".
     *
     * @type {String}
     */
    get magFilter() {
        return this._state.magFilter;
    }

    /**
     * Gets the wrap parameter for this Texture's *S* coordinate.
     *
     * Values can be:
     *
     * * "clampToEdge" -  causes *S* coordinates to be clamped to the size of the texture.
     * * "mirroredRepeat" - causes the *S* coordinate to be set to the fractional part of the texture coordinate
     * if the integer part of *S* is even; if the integer part of *S* is odd, then the *S* texture coordinate is
     * set to *1 - frac ⁡ S* , where *frac ⁡ S* represents the fractional part of *S*.
     * * "repeat" - (default) - causes the integer part of the *S* coordinate to be ignored; xeokit uses only the
     * fractional part, thereby creating a repeating pattern.
     *
     * Default value is "repeat".
     *
     * @type {String}
     */
    get wrapS() {
        return this._state.wrapS;
    }

    /**
     * Gets the wrap parameter for this Texture's *T* coordinate.
     *
     * Values can be:
     *
     * * "clampToEdge" -  causes *S* coordinates to be clamped to the size of the texture.
     *  * "mirroredRepeat" - causes the *S* coordinate to be set to the fractional part of the texture coordinate
     * if the integer part of *S* is even; if the integer part of *S* is odd, then the *S* texture coordinate is
     * set to *1 - frac ⁡ S* , where *frac ⁡ S* represents the fractional part of *S*.
     * * "repeat" - (default) - causes the integer part of the *S* coordinate to be ignored; xeokit uses only the
     * fractional part, thereby creating a repeating pattern.
     *
     * Default value is "repeat".
     *
     * @type {String}
     */
    get wrapT() {
        return this._state.wrapT;
    }

    /**
     * Gets if this Texture's source data is flipped along its vertical axis.
     *
     * @type {Boolean}
     */
    get flipY() {
        return this._state.flipY;
    }

    /**
     * Gets the Texture's encoding format.
     *
     * @type {String}
     */
    get encoding() {
        return this._state.encoding;
    }

    /**
     * Destroys this Texture
     */
    destroy() {
        super.destroy();
        if (this._state.texture) {
            this._state.texture.destroy();
        }
        this._state.destroy();
        stats.memory.textures--;
    }
}

export {Texture};