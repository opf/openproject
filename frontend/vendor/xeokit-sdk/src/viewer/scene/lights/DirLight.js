import {Light} from './Light.js';
import {RenderState} from '../webgl/RenderState.js';
import {RenderBuffer} from '../webgl/RenderBuffer.js';
import {math} from '../math/math.js';

/**
 * @desc A directional light source that illuminates all {@link Mesh}es equally from a given direction.
 *
 * * Has an emission direction vector in {@link DirLight#dir}, but no position.
 * * Defined in either *World* or *View* coordinate space. When in World-space, {@link DirLight#dir} is relative to the
 * World coordinate system, and will appear to move as the {@link Camera} moves. When in View-space, {@link DirLight#dir} is
 * relative to the View coordinate system, and will behave as if fixed to the viewer's head.
 * * {@link AmbientLight}s, {@link DirLight}s and {@link PointLight}s are registered by their {@link Component#id} on {@link Scene#lights}.
 *
 * ## Usage
 *
 * In the example below we'll replace the {@link Scene}'s default light sources with three View-space DirLights.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#lights_DirLight_view)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildSphereGeometry} from "../src/scene/geometry/builders/buildSphereGeometry.js";
 * import {buildPlaneGeometry} from "../src/scene/geometry/builders/buildPlaneGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 * import {DirLight} from "../src/scene/lights/DirLight.js";
 *
 * // Create a Viewer and arrange the camera
 *
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * // Replace the Scene's default lights with three custom view-space DirLights
 *
 * viewer.scene.clearLights();
 *
 * new DirLight(viewer.scene, {
 *      id: "keyLight",
 *      dir: [0.8, -0.6, -0.8],
 *      color: [1.0, 0.3, 0.3],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 * new DirLight(viewer.scene, {
 *      id: "fillLight",
 *      dir: [-0.8, -0.4, -0.4],
 *      color: [0.3, 1.0, 0.3],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 * new DirLight(viewer.scene, {
 *      id: "rimLight",
 *      dir: [0.2, -0.8, 0.8],
 *      color: [0.6, 0.6, 0.6],
 *      intensity: 1.0,
 *      space: "view"
 * });
 *
 *
 * // Create a sphere and ground plane
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildSphereGeometry({
 *          radius: 2.0
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          diffuse: [0.7, 0.7, 0.7],
 *          specular: [1.0, 1.0, 1.0],
 *          emissive: [0, 0, 0],
 *          alpha: 1.0,
 *          ambient: [1, 1, 0],
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          })
 *      })
 *  });
 *
 * new Mesh(viewer.scene, {
 *      geometry: buildPlaneGeometry(ReadableGeometry, viewer.scene, {
 *          xSize: 30,
 *          zSize: 30
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          }),
 *          backfaces: true
 *      }),
 *      position: [0, -2.1, 0]
 * });
 * ````
 */
class DirLight extends Light {

    /**
     @private
     */
    get type() {
        return "DirLight";
    }

    /**
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this DirLight as well.
     * @param {*} [cfg] The DirLight configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Number[]} [cfg.dir=[1.0, 1.0, 1.0]]  A unit vector indicating the direction that the light is shining,  given in either World or View space, depending on the value of the ````space```` parameter.
     * @param {Number[]} [cfg.color=[0.7, 0.7, 0.8 ]] The color of this DirLight.
     * @param {Number} [cfg.intensity=1.0] The intensity of this DirLight, as a factor in range ````[0..1]````.
     * @param {String} [cfg.space="view"] The coordinate system the DirLight is defined in - ````"view"```` or ````"space"````.
     * @param {Boolean} [cfg.castsShadow=false] Flag which indicates if this DirLight casts a castsShadow.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        const self = this;

        this._shadowRenderBuf = null;
        this._shadowViewMatrix = null;
        this._shadowProjMatrix = null;
        this._shadowViewMatrixDirty = true;
        this._shadowProjMatrixDirty = true;

        this._state = new RenderState({
            type: "dir",
            dir: math.vec3([1.0, 1.0, 1.0]),
            color: math.vec3([0.7, 0.7, 0.8]),
            intensity: 1.0,
            space: cfg.space || "view",
            castsShadow: false,
            shadowDirty: true,

            getShadowViewMatrix: (function () {
                const look = math.vec3();
                const up = math.vec3([0, 1, 0]);
                return function () {
                    if (self._shadowViewMatrixDirty) {
                        if (!self._shadowViewMatrix) {
                            self._shadowViewMatrix = math.identityMat4();
                        }
                        const dir = self._state.dir;
                        math.lookAtMat4v([-dir[0], -dir[1], -dir[2]], [0, 0, 0], up, self._shadowViewMatrix);
                        self._shadowViewMatrixDirty = false;
                    }
                    return self._shadowViewMatrix;
                };
            })(),

            getShadowProjMatrix: function () {
                if (self._shadowProjMatrixDirty) { // TODO: Set when canvas resizes
                    if (!self._shadowProjMatrix) {
                        self._shadowProjMatrix = math.identityMat4();
                    }
                    math.orthoMat4c(-10, 10, -10, 10, 0, 500.0, self._shadowProjMatrix);
                    self._shadowProjMatrixDirty = false;
                }
                return self._shadowProjMatrix;
            },

            getShadowRenderBuf: function () {
                if (!self._shadowRenderBuf) {
                    self._shadowRenderBuf = new RenderBuffer(self.scene.canvas.canvas, self.scene.canvas.gl, {size: [1024, 1024]});
                }
                return self._shadowRenderBuf;
            }
        });

        this.dir = cfg.dir;
        this.color = cfg.color;
        this.intensity = cfg.intensity;
        this.castsShadow = cfg.castsShadow;
        this.scene._lightCreated(this);
    }

    /**
     * Sets the direction in which the DirLight is shining.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @param {Number[]} value The direction vector.
     */
    set dir(value) {
        this._state.dir.set(value || [1.0, 1.0, 1.0]);
        this._shadowViewMatrixDirty = true;
        this.glRedraw();
    }

    /**
     * Gets the direction in which the DirLight is shining.
     *
     * Default value is ````[1.0, 1.0, 1.0]````.
     *
     * @returns {Number[]} The direction vector.
     */
    get dir() {
        return this._state.dir;
    }

    /**
     * Sets the RGB color of this DirLight.
     *
     * Default value is ````[0.7, 0.7, 0.8]````.
     *
     * @param {Number[]} color The DirLight's RGB color.
     */
    set color(color) {
        this._state.color.set(color || [0.7, 0.7, 0.8]);
        this.glRedraw();
    }

    /**
     * Gets the RGB color of this DirLight.
     *
     * Default value is ````[0.7, 0.7, 0.8]````.
     *
     * @returns {Number[]} The DirLight's RGB color.
     */
    get color() {
        return this._state.color;
    }

    /**
     * Sets the intensity of this DirLight.
     *
     * Default intensity is ````1.0```` for maximum intensity.
     *
     * @param {Number} intensity The DirLight's intensity
     */
    set intensity(intensity) {
        intensity = intensity !== undefined ? intensity : 1.0;
        this._state.intensity = intensity;
        this.glRedraw();
    }

    /**
     * Gets the intensity of this DirLight.
     *
     * Default value is ````1.0```` for maximum intensity.
     *
     * @returns {Number} The DirLight's intensity.
     */
    get intensity() {
        return this._state.intensity;
    }

    /**
     * Sets if this DirLight casts a shadow.
     *
     * Default value is ````false````.
     *
     * @param {Boolean} castsShadow Set ````true```` to cast shadows.
     */
    set castsShadow(castsShadow) {
        castsShadow = !!castsShadow;
        if (this._state.castsShadow === castsShadow) {
            return;
        }
        this._state.castsShadow = castsShadow;
        this._shadowViewMatrixDirty = true;
        this.glRedraw();
    }

    /**
     * Gets if this DirLight casts a shadow.
     *
     * Default value is ````false````.
     *
     * @returns {Boolean} ````true```` if this DirLight casts shadows.
     */
    get castsShadow() {
        return this._state.castsShadow;
    }

    /**
     * Destroys this DirLight.
     */
    destroy() {
        super.destroy();
        this._state.destroy();
        if (this._shadowRenderBuf) {
            this._shadowRenderBuf.destroy();
        }
        this.scene._lightDestroyed(this);
        this.glRedraw();
    }
}

export {DirLight};
