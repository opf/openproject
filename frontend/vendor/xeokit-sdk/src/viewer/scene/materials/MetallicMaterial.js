import {Material} from './Material.js';
import {RenderState} from '../webgl/RenderState.js';
import {math} from '../math/math.js';

const modes = {"opaque": 0, "mask": 1, "blend": 2};
const modeNames = ["opaque", "mask", "blend"];

/**
 * @desc Configures the normal rendered appearance of {@link Mesh}es using the physically-accurate *metallic-roughness* shading model.
 *
 * * Useful for conductive materials, such as metal, but also appropriate for insulators.
 * * {@link SpecularMaterial} is best for insulators, such as wood, ceramics and plastic.
 * * {@link PhongMaterial} is appropriate for non-realistic objects.
 * * {@link LambertMaterial} is appropriate for high-detail models that need to render as efficiently as possible.
 *
 * ## Usage
 *
 * In the example below we'll create a {@link Mesh} with {@link MetallicMaterial} and {@link ReadableGeometry} loaded from OBJ.
 *
 * Note that in this example we're providing separate {@link Texture} for the {@link MetallicMaterial#metallic} and {@link MetallicMaterial#roughness}
 * channels, which allows us a little creative flexibility. Then, in the next example further down, we'll combine those channels
 * within the same {@link Texture} for efficiency.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#materials_MetallicMaterial)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {loadOBJGeometry} from "../src/scene/geometry/loaders/loadOBJGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {MetallicMaterial} from "../src/scene/materials/MetallicMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0.57, 1.37, 1.14];
 * viewer.scene.camera.look = [0.04, 0.58, 0.00];
 * viewer.scene.camera.up = [-0.22, 0.84, -0.48];
 *
 * loadOBJGeometry(viewer.scene, {
 *      src: "models/obj/fireHydrant/FireHydrantMesh.obj"
 * })
 * .then(function (geometry) {
 *
 *      // Success
 *
 *      new Mesh(viewer.scene, {
 *
 *          geometry: new ReadableGeometry(viewer.scene, geometry),
 *
 *          material: new MetallicMaterial(viewer.scene, {
 *
 *              baseColor: [1, 1, 1],
 *              metallic: 1.0,
 *              roughness: 1.0,
 *
 *              baseColorMap: new Texture(viewer.scene, {
 *                  src: "models/obj/fireHydrant/fire_hydrant_Base_Color.png",
 *                  encoding: "sRGB"
 *              }),
 *              normalMap: new Texture(viewer.scene, {
 *                  src: "models/obj/fireHydrant/fire_hydrant_Normal_OpenGL.png"
 *              }),
 *              roughnessMap: new Texture(viewer.scene, {
 *                  src: "models/obj/fireHydrant/fire_hydrant_Roughness.png"
 *              }),
 *              metallicMap: new Texture(viewer.scene, {
 *                  src: "models/obj/fireHydrant/fire_hydrant_Metallic.png"
 *              }),
 *              occlusionMap: new Texture(viewer.scene, {
 *                  src: "models/obj/fireHydrant/fire_hydrant_Mixed_AO.png"
 *              }),
 *
 *              specularF0: 0.7
 *          })
 *      });
 * }, function () {
 *          // Error
 *      });
 * ````
 *
 * ## Background Theory
 *
 * For an introduction to physically-based rendering (PBR) concepts, try these articles:
 *
 * * Joe Wilson's [Basic Theory of Physically-Based Rendering](https://www.marmoset.co/posts/basic-theory-of-physically-based-rendering/)
 * * Jeff Russel's [Physically-based Rendering, and you can too!](https://www.marmoset.co/posts/physically-based-rendering-and-you-can-too/)
 * * Sebastien Legarde's [Adapting a physically-based shading model](http://seblagarde.wordpress.com/tag/physically-based-rendering/)
 *
 * ## MetallicMaterial Properties
 *
 * The following table summarizes MetallicMaterial properties:
 *
 * | Property | Type | Range | Default Value | Space | Description |
 * |:--------:|:----:|:-----:|:-------------:|:-----:|:-----------:|
 * | {@link MetallicMaterial#baseColor} | Array | [0, 1] for all components | [1,1,1,1] | linear | The RGB components of the base color of the material. |
 * | {@link MetallicMaterial#metallic} | Number | [0, 1] | 1 | linear | The metallic-ness the material (1 for metals, 0 for non-metals). |
 * | {@link MetallicMaterial#roughness} | Number | [0, 1] | 1 | linear | The roughness of the material surface. |
 * | {@link MetallicMaterial#specularF0} | Number | [0, 1] | 1 | linear | The specular Fresnel of the material surface. |
 * | {@link MetallicMaterial#emissive} | Array | [0, 1] for all components | [0,0,0] | linear | The RGB components of the emissive color of the material. |
 * | {@link MetallicMaterial#alpha} | Number | [0, 1] | 1 | linear | The transparency of the material surface (0 fully transparent, 1 fully opaque). |
 * | {@link MetallicMaterial#baseColorMap} | {@link Texture} |  | null | sRGB | Texture RGB components multiplying by {@link MetallicMaterial#baseColor}. If the fourth component (A) is present, it multiplies by {@link MetallicMaterial#alpha}. |
 * | {@link MetallicMaterial#metallicMap} | {@link Texture} |  | null | linear | Texture with first component multiplying by {@link MetallicMaterial#metallic}. |
 * | {@link MetallicMaterial#roughnessMap} | {@link Texture} |  | null | linear | Texture with first component multiplying by {@link MetallicMaterial#roughness}. |
 * | {@link MetallicMaterial#metallicRoughnessMap} | {@link Texture} |  | null | linear | Texture with first component multiplying by {@link MetallicMaterial#metallic} and second component multiplying by {@link MetallicMaterial#roughness}. |
 * | {@link MetallicMaterial#emissiveMap} | {@link Texture} |  | null | linear | Texture with RGB components multiplying by {@link MetallicMaterial#emissive}. |
 * | {@link MetallicMaterial#alphaMap} | {@link Texture} |  | null | linear | Texture with first component multiplying by {@link MetallicMaterial#alpha}. |
 * | {@link MetallicMaterial#occlusionMap} | {@link Texture} |  | null | linear | Ambient occlusion texture multiplying by surface's reflected diffuse and specular light. |
 * | {@link MetallicMaterial#normalMap} | {@link Texture} |  | null | linear | Tangent-space normal map. |
 * | {@link MetallicMaterial#alphaMode} | String | "opaque", "blend", "mask" | "blend" |  | Alpha blend mode. |
 * | {@link MetallicMaterial#alphaCutoff} | Number | [0..1] | 0.5 |  | Alpha cutoff value. |
 * | {@link MetallicMaterial#backfaces} | Boolean |  | false |  | Whether to render {@link ReadableGeometry} backfaces. |
 * | {@link MetallicMaterial#frontface} | String | "ccw", "cw" | "ccw" |  | The winding order for {@link ReadableGeometry} frontfaces - "cw" for clockwise, or "ccw" for counter-clockwise. |
 *
 *
 * ## Combining Channels Within the Same Textures
 *
 * In the previous example we provided separate {@link Texture} for the {@link MetallicMaterial#metallic} and
 * {@link MetallicMaterial#roughness} channels, but we can combine those channels into the same {@link Texture} to
 * reduce download time, memory footprint and rendering time (and also for glTF compatibility).
 *
 * Here's the {@link Mesh} again, with our MetallicMaterial with those channels combined in the {@link MetallicMaterial#metallicRoughnessMap}
 * {@link Texture}, where the *R* component multiplies by {@link MetallicMaterial#metallic} and *G* multiplies
 * by {@link MetallicMaterial#roughness}.
 *
 * ````javascript
 * new Mesh(viewer.scene, {
 *
 *     geometry: geometry,
 *
 *     material: new MetallicMaterial(viewer.scene, {
 *
 *         baseColor: [1, 1, 1],
 *         metallic: 1.0,
 *         roughness: 1.0,
 *
 *         baseColorMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Base_Color.png",
 *             encoding: "sRGB"
 *         }),
 *         normalMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Normal_OpenGL.png"
 *         }),
 *         metallicRoughnessMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_MetallicRoughness.png"
 *         }),
 *         metallicRoughnessMap : new Texture(viewer.scene, {                  // <<----------- Added
 *             src: "models/obj/fireHydrant/fire_hydrant_MetallicRoughness.png"  // R component multiplies by metallic
 *         }),                                                                   // G component multiplies by roughness
 *         occlusionMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Mixed_AO.png"
 *         }),
 *
 *         specularF0: 0.7
 *  })
 * ````
 *
 * Although not shown in this example, we can also texture {@link MetallicMaterial#alpha} with the *A* component of
 * {@link MetallicMaterial#baseColorMap}'s {@link Texture}, if required.
 *
 * ## Alpha Blending
 *
 * Let's make our {@link Mesh} transparent.
 *
 * We'll update the {@link MetallicMaterial#alpha} and {@link MetallicMaterial#alphaMode}, causing it to blend 50%
 * with the background:
 *
 * ````javascript
 * hydrant.material.alpha = 0.5;
 * hydrant.material.alphaMode = "blend";
 * ````
 *
 * ## Alpha Masking
 *
 * Let's apply an alpha mask to our {@link Mesh}.
 *
 * We'll configure an {@link MetallicMaterial#alphaMap} to multiply by {@link MetallicMaterial#alpha},
 * with {@link MetallicMaterial#alphaMode} and {@link MetallicMaterial#alphaCutoff} to treat it as an alpha mask:
 *
 * ````javascript
 * new Mesh(viewer.scene, {
 *
 *     geometry: geometry,
 *
 *     material: new MetallicMaterial(viewer.scene, {
 *
 *         baseColor: [1, 1, 1],
 *         metallic: 1.0,
 *         roughness: 1.0,
 *         alpha: 1.0,
 *         alphaMode : "mask",  // <<---------------- Added
 *         alphaCutoff : 0.2,   // <<---------------- Added
 *
 *         alphaMap : new Texture(viewer.scene{ // <<---------------- Added
 *              src: "textures/alphaMap.jpg"
 *         }),
 *         baseColorMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Base_Color.png",
 *             encoding: "sRGB"
 *         }),
 *         normalMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Normal_OpenGL.png"
 *         }),
 *         metallicRoughnessMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_MetallicRoughness.png"
 *         }),
 *         metallicRoughnessMap : new Texture(viewer.scene, {                  // <<----------- Added
 *             src: "models/obj/fireHydrant/fire_hydrant_MetallicRoughness.png"  // R component multiplies by metallic
 *         }),                                                                   // G component multiplies by roughness
 *         occlusionMap: new Texture(viewer.scene, {
 *             src: "models/obj/fireHydrant/fire_hydrant_Mixed_AO.png"
 *         }),
 *
 *         specularF0: 0.7
 *  })
 * ````
 */
class MetallicMaterial extends Material {

    /**
     @private
     */
    get type() {
        return "MetallicMaterial";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this MetallicMaterial as well.
     * @param {*} [cfg] The MetallicMaterial configuration.
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Number[]} [cfg.baseColor=[1,1,1]] RGB diffuse color of this MetallicMaterial. Multiplies by the RGB components of {@link MetallicMaterial#baseColorMap}.
     * @param {Number} [cfg.metallic=1.0] Factor in the range ````[0..1]```` indicating how metallic this MetallicMaterial is.  ````1```` is metal, ````0```` is non-metal. Multiplies by the *R* component of {@link MetallicMaterial#metallicMap} and the *A* component of {@link MetallicMaterial#metallicRoughnessMap}.
     * @param {Number} [cfg.roughness=1.0] Factor in the range ````[0..1]```` indicating the roughness of this MetallicMaterial.  ````0```` is fully smooth, ````1```` is fully rough. Multiplies by the *R* component of {@link MetallicMaterial#roughnessMap}.
     * @param {Number} [cfg.specularF0=0.0] Factor in the range ````[0..1]```` indicating specular Fresnel.
     * @param {Number[]} [cfg.emissive=[0,0,0]]  RGB emissive color of this MetallicMaterial. Multiplies by the RGB components of {@link MetallicMaterial#emissiveMap}.
     * @param {Number} [cfg.alpha=1.0] Factor in the range ````[0..1]```` indicating the alpha of this MetallicMaterial.  Multiplies by the *R* component of {@link MetallicMaterial#alphaMap} and the *A* component,  if present, of {@link MetallicMaterial#baseColorMap}. The value of  {@link MetallicMaterial#alphaMode} indicates how alpha is interpreted when rendering.
     * @param {Texture} [cfg.baseColorMap=undefined] RGBA {@link Texture} containing the diffuse color of this MetallicMaterial, with optional *A* component for alpha. The RGB components multiply by the {@link MetallicMaterial#baseColor} property, while the *A* component, if present, multiplies by the {@link MetallicMaterial#alpha} property.
     * @param {Texture} [cfg.alphaMap=undefined] RGB {@link Texture} containing this MetallicMaterial's alpha in its *R* component. The *R* component multiplies by the {@link MetallicMaterial#alpha} property. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.metallicMap=undefined] RGB {@link Texture} containing this MetallicMaterial's metallic factor in its *R* component. The *R* component multiplies by the {@link MetallicMaterial#metallic} property. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.roughnessMap=undefined] RGB {@link Texture} containing this MetallicMaterial's roughness factor in its *R* component. The *R* component multiplies by the  {@link MetallicMaterial#roughness} property. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.metallicRoughnessMap=undefined] RGB {@link Texture} containing this MetallicMaterial's metalness in its *R* component and roughness in its *G* component. Its *R* component multiplies by the {@link MetallicMaterial#metallic} property, while its *G* component multiplies by the {@link MetallicMaterial#roughness} property. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.emissiveMap=undefined] RGB {@link Texture} containing the emissive color of this MetallicMaterial. Multiplies by the {@link MetallicMaterial#emissive} property. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.occlusionMap=undefined] RGB ambient occlusion {@link Texture}. Within shaders, multiplies by the specular and diffuse light reflected by surfaces. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {Texture} [cfg.normalMap=undefined] RGB tangent-space normal {@link Texture}. Must be within the same {@link Scene} as this MetallicMaterial.
     * @param {String} [cfg.alphaMode="opaque"] The alpha blend mode, which specifies how alpha is to be interpreted. Accepted values are "opaque", "blend" and "mask". See the {@link MetallicMaterial#alphaMode} property for more info.
     * @param {Number} [cfg.alphaCutoff=0.5] The alpha cutoff value. See the {@link MetallicMaterial#alphaCutoff} property for more info.
     * @param {Boolean} [cfg.backfaces=false] Whether to render {@link ReadableGeometry} backfaces.
     * @param {Boolean} [cfg.frontface="ccw"] The winding order for {@link ReadableGeometry} front faces - ````"cw"```` for clockwise, or ````"ccw"```` for counter-clockwise.
     * @param {Number} [cfg.lineWidth=1] Scalar that controls the width of lines for {@link ReadableGeometry} with {@link ReadableGeometry#primitive} set to "lines".
     * @param {Number} [cfg.pointSize=1] Scalar that controls the size of points for {@link ReadableGeometry} with {@link ReadableGeometry#primitive} set to "points".
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({
            type: "MetallicMaterial",
            baseColor: math.vec4([1.0, 1.0, 1.0]),
            emissive: math.vec4([0.0, 0.0, 0.0]),
            metallic: null,
            roughness: null,
            specularF0: null,
            alpha: null,
            alphaMode: null, // "opaque"
            alphaCutoff: null,
            lineWidth: null,
            pointSize: null,
            backfaces: null,
            frontface: null, // Boolean for speed; true == "ccw", false == "cw"
            hash: null
        });

        this.baseColor = cfg.baseColor;
        this.metallic = cfg.metallic;
        this.roughness = cfg.roughness;
        this.specularF0 = cfg.specularF0;
        this.emissive = cfg.emissive;
        this.alpha = cfg.alpha;

        if (cfg.baseColorMap) {
            this._baseColorMap = this._checkComponent("Texture", cfg.baseColorMap);
        }
        if (cfg.metallicMap) {
            this._metallicMap = this._checkComponent("Texture", cfg.metallicMap);

        }
        if (cfg.roughnessMap) {
            this._roughnessMap = this._checkComponent("Texture", cfg.roughnessMap);
        }
        if (cfg.metallicRoughnessMap) {
            this._metallicRoughnessMap = this._checkComponent("Texture", cfg.metallicRoughnessMap);
        }
        if (cfg.emissiveMap) {
            this._emissiveMap = this._checkComponent("Texture", cfg.emissiveMap);
        }
        if (cfg.occlusionMap) {
            this._occlusionMap = this._checkComponent("Texture", cfg.occlusionMap);
        }
        if (cfg.alphaMap) {
            this._alphaMap = this._checkComponent("Texture", cfg.alphaMap);
        }
        if (cfg.normalMap) {
            this._normalMap = this._checkComponent("Texture", cfg.normalMap);
        }

        this.alphaMode = cfg.alphaMode;
        this.alphaCutoff = cfg.alphaCutoff;
        this.backfaces = cfg.backfaces;
        this.frontface = cfg.frontface;
        this.lineWidth = cfg.lineWidth;
        this.pointSize = cfg.pointSize;

        this._makeHash();
    }

    _makeHash() {
        const state = this._state;
        const hash = ["/met"];
        if (this._baseColorMap) {
            hash.push("/bm");
            if (this._baseColorMap._state.hasMatrix) {
                hash.push("/mat");
            }
            hash.push("/" + this._baseColorMap._state.encoding);
        }
        if (this._metallicMap) {
            hash.push("/mm");
            if (this._metallicMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._roughnessMap) {
            hash.push("/rm");
            if (this._roughnessMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._metallicRoughnessMap) {
            hash.push("/mrm");
            if (this._metallicRoughnessMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._emissiveMap) {
            hash.push("/em");
            if (this._emissiveMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._occlusionMap) {
            hash.push("/ocm");
            if (this._occlusionMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._alphaMap) {
            hash.push("/am");
            if (this._alphaMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        if (this._normalMap) {
            hash.push("/nm");
            if (this._normalMap._state.hasMatrix) {
                hash.push("/mat");
            }
        }
        hash.push(";");
        state.hash = hash.join("");
    }


    /**
     * Sets the RGB diffuse color.
     *
     * Multiplies by the RGB components of {@link MetallicMaterial#baseColorMap}.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     * @type {Number[]}
     */
    set baseColor(value) {
        let baseColor = this._state.baseColor;
        if (!baseColor) {
            baseColor = this._state.baseColor = new Float32Array(3);
        } else if (value && baseColor[0] === value[0] && baseColor[1] === value[1] && baseColor[2] === value[2]) {
            return;
        }
        if (value) {
            baseColor[0] = value[0];
            baseColor[1] = value[1];
            baseColor[2] = value[2];
        } else {
            baseColor[0] = 1;
            baseColor[1] = 1;
            baseColor[2] = 1;
        }
        this.glRedraw();
    }

    /**
     * Gets the RGB diffuse color.
     *
     * Multiplies by the RGB components of {@link MetallicMaterial#baseColorMap}.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     * @type {Number[]}
     */
    get baseColor() {
        return this._state.baseColor;
    }


    /**
     * Gets the RGB {@link Texture} containing the diffuse color of this MetallicMaterial, with optional *A* component for alpha.
     *
     * The RGB components multiply by {@link MetallicMaterial#baseColor}, while the *A* component, if present, multiplies by {@link MetallicMaterial#alpha}.
     *
     * @type {Texture}
     */
    get baseColorMap() {
        return this._baseColorMap;
    }

    /**
     * Sets the metallic factor.
     *
     * This is in the range ````[0..1]```` and indicates how metallic this MetallicMaterial is.
     *
     * ````1```` is metal, ````0```` is non-metal.
     *
     * Multiplies by the *R* component of {@link MetallicMaterial#metallicMap} and the *A* component of {@link MetallicMaterial#metallicRoughnessMap}.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set metallic(value) {
        value = (value !== undefined && value !== null) ? value : 1.0;
        if (this._state.metallic === value) {
            return;
        }
        this._state.metallic = value;
        this.glRedraw();
    }

    /**
     * Gets the metallic factor.
     *
     * @type {Number}
     */
    get metallic() {
        return this._state.metallic;
    }

    /**
     * Gets the RGB {@link Texture} containing this MetallicMaterial's metallic factor in its *R* component.
     *
     * The *R* component multiplies by {@link MetallicMaterial#metallic}.
     *
     * @type {Texture}
     */
    get metallicMap() {
        return this._attached.metallicMap;
    }

    /**
     *  Sets the roughness factor.
     *
     *  This factor is in the range ````[0..1]````, where ````0```` is fully smooth,````1```` is fully rough.
     *
     * Multiplies by the *R* component of {@link MetallicMaterial#roughnessMap}.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set roughness(value) {
        value = (value !== undefined && value !== null) ? value : 1.0;
        if (this._state.roughness === value) {
            return;
        }
        this._state.roughness = value;
        this.glRedraw();
    }

    /**
     * Gets the roughness factor.
     *
     * @type {Number}
     */
    get roughness() {
        return this._state.roughness;
    }

    /**
     * Gets the RGB {@link Texture} containing this MetallicMaterial's roughness factor in its *R* component.
     *
     * The *R* component multiplies by {@link MetallicMaterial#roughness}.
     *
     * @type {Texture}
     */
    get roughnessMap() {
        return this._attached.roughnessMap;
    }

    /**
     * Gets the RGB {@link Texture} containing this MetallicMaterial's metalness in its *R* component and roughness in its *G* component.
     *
     * Its *B* component multiplies by the {@link MetallicMaterial#metallic} property, while its *G* component multiplies by the {@link MetallicMaterial#roughness} property.
     *
     * @type {Texture}
     */
    get metallicRoughnessMap() {
        return this._attached.metallicRoughnessMap;
    }

    /**
     * Sets the factor in the range [0..1] indicating specular Fresnel value.
     *
     * Default value is ````0.0````.
     *
     * @type {Number}
     */
    set specularF0(value) {
        value = (value !== undefined && value !== null) ? value : 0.0;
        if (this._state.specularF0 === value) {
            return;
        }
        this._state.specularF0 = value;
        this.glRedraw();
    }

    /**
     * Gets the factor in the range [0..1] indicating specular Fresnel value.
     *
     * @type {Number}
     */
    get specularF0() {
        return this._state.specularF0;
    }

    /**
     * Sets the RGB emissive color.
     *
     * Multiplies by {@link MetallicMaterial#emissiveMap}.
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
     * Gets the RGB emissive color.
     *
     * @type {Number[]}
     */
    get emissive() {
        return this._state.emissive;
    }

    /**
     * Gets the RGB emissive map.
     *
     * Multiplies by {@link MetallicMaterial#emissive}.
     *
     * @type {Texture}
     */
    get emissiveMap() {
        return this._attached.emissiveMap;
    }

    /**
     * Gets the RGB ambient occlusion map.
     *
     * Multiplies by the specular and diffuse light reflected by surfaces.
     *
     * @type {Texture}
     */
    get occlusionMap() {
        return this._attached.occlusionMap;
    }

    /**
     * Sets factor in the range ````[0..1]```` that indicates the alpha value.
     *
     * Multiplies by the *R* component of {@link MetallicMaterial#alphaMap} and the *A* component, if present, of {@link MetallicMaterial#baseColorMap}.
     *
     * The value of {@link MetallicMaterial#alphaMode} indicates how alpha is interpreted when rendering.
     *
     * Default value is ````1.0````.
     *
     * @type {Number}
     */
    set alpha(value) {
        value = (value !== undefined && value !== null) ? value : 1.0;
        if (this._state.alpha === value) {
            return;
        }
        this._state.alpha = value;
        this.glRedraw();
    }

    /**
     * Gets factor in the range ````[0..1]```` that indicates the alpha value.
     *
     * @type {Number}
     */
    get alpha() {
        return this._state.alpha;
    }

    /**
     * Gets the RGB {@link Texture} containing this MetallicMaterial's alpha in its *R* component.
     *
     * The *R* component multiplies by the {@link MetallicMaterial#alpha} property.
     *
     * @type {Texture}
     */
    get alphaMap() {
        return this._attached.alphaMap;
    }

    /**
     * Gets the RGB tangent-space normal map {@link Texture}.
     *
     * @type {Texture}
     */
    get normalMap() {
        return this._attached.normalMap;
    }

    /**
     * Sets the alpha rendering mode.
     *
     * This specifies how alpha is interpreted. Alpha is the combined result of the {@link MetallicMaterial#alpha} and {@link MetallicMaterial#alphaMap} properties.
     *
     * Accepted values are:
     *
     * * "opaque" - The alpha value is ignored and the rendered output is fully opaque (default).
     * * "mask" - The rendered output is either fully opaque or fully transparent depending on the alpha and {@link MetallicMaterial#alphaCutoff}.
     * * "blend" - The alpha value is used to composite the source and destination areas. The rendered output is combined with the background using the normal painting operation (i.e. the Porter and Duff over operator).
     *
     * @type {String}
     */
    set alphaMode(alphaMode) {
        alphaMode = alphaMode || "opaque";
        let value = modes[alphaMode];
        if (value === undefined) {
            this.error("Unsupported value for 'alphaMode': " + alphaMode + " defaulting to 'opaque'");
            value = "opaque";
        }
        if (this._state.alphaMode === value) {
            return;
        }
        this._state.alphaMode = value;
        this.glRedraw();
    }

    /**
     * Gets the alpha rendering mode.
     *
     * @type {String}
     */
    get alphaMode() {
        return modeNames[this._state.alphaMode];
    }

    /**
     * Sets the alpha cutoff value.
     *
     * Specifies the cutoff threshold when {@link MetallicMaterial#alphaMode} equals "mask". If the alpha is greater than or equal to this value then it is rendered as fully opaque, otherwise, it is rendered as fully transparent. A value greater than 1.0 will render the entire
     * material as fully transparent. This value is ignored for other modes.
     *
     * Alpha is the combined result of the {@link MetallicMaterial#alpha} and {@link MetallicMaterial#alphaMap} properties.
     *
     * Default value is ````0.5````.
     *
     * @type {Number}
     */
    set alphaCutoff(alphaCutoff) {
        if (alphaCutoff === null || alphaCutoff === undefined) {
            alphaCutoff = 0.5;
        }
        if (this._state.alphaCutoff === alphaCutoff) {
            return;
        }
        this._state.alphaCutoff = alphaCutoff;
    }

    /**
     * Gets the alpha cutoff value.
     *
     * @type {Number}
     */
    get alphaCutoff() {
        return this._state.alphaCutoff;
    }

    /**
     * Sets whether backfaces are visible on attached {@link Mesh}es.
     *
     * The backfaces will belong to {@link ReadableGeometry} compoents that are also attached to the {@link Mesh}es.
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
     * @type {String}
     */
    get frontface() {
        return this._state.frontface ? "ccw" : "cw";
    }

    /**
     * Sets the MetallicMaterial's line width.
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
     * Gets the MetallicMaterial's line width.
     *
     * @type {Number}
     */
    get lineWidth() {
        return this._state.lineWidth;
    }

    /**
     * Sets the MetallicMaterial's point size.
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
     * Gets the MetallicMaterial's point size.
     *
     * @type {Number}
     */
    get pointSize() {
        return this._state.pointSize;
    }

    /**
     * Destroys this MetallicMaterial.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
    }
}

export {MetallicMaterial};