/**
 Fired when this Mesh is picked via a call to {@link Scene/pick:method"}}Scene#pick(){{/crossLink}}.

 The event parameters will be the hit result returned by the {@link Scene/pick:method"}}Scene#pick(){{/crossLink}} method.
 @event picked
 */
import {math} from '../math/math.js';
import {Component} from '../Component.js';
import {RenderState} from '../webgl/RenderState.js';
import {DrawRenderer} from "./draw/DrawRenderer.js";
import {EmphasisFillRenderer} from "./emphasis/EmphasisFillRenderer.js";
import {EmphasisEdgesRenderer} from "./emphasis/EmphasisEdgesRenderer.js";
import {PickMeshRenderer} from "./pick/PickMeshRenderer.js";
import {PickTriangleRenderer} from "./pick/PickTriangleRenderer.js";
import {OcclusionRenderer} from "./occlusion/OcclusionRenderer.js";

import {geometryCompressionUtils} from '../math/geometryCompressionUtils.js';

const obb = math.OBB3();
const angleAxis = new Float32Array(4);
const q1 = new Float32Array(4);
const q2 = new Float32Array(4);
const xAxis = new Float32Array([1, 0, 0]);
const yAxis = new Float32Array([0, 1, 0]);
const zAxis = new Float32Array([0, 0, 1]);

const veca = new Float32Array(3);
const vecb = new Float32Array(3);

const identityMat = math.identityMat4();

/**
 * @desc An {@link Entity} that is a drawable element, with a {@link Geometry} and a {@link Material}, that can be
 * connected into a scene graph using {@link Node}s.
 *
 * ## Usage
 *
 * The example below is the same as the one given for {@link Node}, since the two classes work together.  In this example,
 * we'll create a scene graph in which a root {@link Node} represents a group and the Meshes are leaves.
 *
 * Since {@link Node} implements {@link Entity}, we can designate the root {@link Node} as a model, causing it to be registered by its
 * ID in {@link Scene#models}.
 *
 * Since Mesh also implements {@link Entity}, we can designate the leaf Meshes as objects, causing them to
 * be registered by their IDs in {@link Scene#objects}.
 *
 * We can then find those {@link Entity} types in {@link Scene#models} and {@link Scene#objects}.
 *
 * We can also update properties of our object-Meshes via calls to {@link Scene#setObjectsHighlighted} etc.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#sceneRepresentation_SceneGraph)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {Node} from "../src/scene/nodes/Node.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * viewer.scene.camera.eye = [-21.80, 4.01, 6.56];
 * viewer.scene.camera.look = [0, -5.75, 0];
 * viewer.scene.camera.up = [0.37, 0.91, -0.11];
 *
 * new Node(viewer.scene, {
 *      id: "table",
 *      isModel: true, // <---------- Node represents a model, so is registered by ID in viewer.scene.models
 *      rotation: [0, 50, 0],
 *      position: [0, 0, 0],
 *      scale: [1, 1, 1],
 *
 *      children: [
 *
 *          new Mesh(viewer.scene, { // Red table leg
 *              id: "redLeg",
 *              isObject: true, // <------ Node represents an object, so is registered by ID in viewer.scene.objects
 *              position: [-4, -6, -4],
 *              scale: [1, 3, 1],
 *              rotation: [0, 0, 0],
 *              material: new PhongMaterial(viewer.scene, {
 *                  diffuse: [1, 0.3, 0.3]
 *              })
 *          }),
 *
 *          new Mesh(viewer.scene, { // Green table leg
 *              id: "greenLeg",
 *              isObject: true, // <------ Node represents an object, so is registered by ID in viewer.scene.objects
 *              position: [4, -6, -4],
 *              scale: [1, 3, 1],
 *              rotation: [0, 0, 0],
 *              material: new PhongMaterial(viewer.scene, {
 *                  diffuse: [0.3, 1.0, 0.3]
 *              })
 *          }),
 *
 *          new Mesh(viewer.scene, {// Blue table leg
 *              id: "blueLeg",
 *              isObject: true, // <------ Node represents an object, so is registered by ID in viewer.scene.objects
 *              position: [4, -6, 4],
 *              scale: [1, 3, 1],
 *              rotation: [0, 0, 0],
 *              material: new PhongMaterial(viewer.scene, {
 *                  diffuse: [0.3, 0.3, 1.0]
 *              })
 *          }),
 *
 *          new Mesh(viewer.scene, {  // Yellow table leg
 *              id: "yellowLeg",
 *              isObject: true, // <------ Node represents an object, so is registered by ID in viewer.scene.objects
 *              position: [-4, -6, 4],
 *              scale: [1, 3, 1],
 *              rotation: [0, 0, 0],
 *              material: new PhongMaterial(viewer.scene, {
 *                   diffuse: [1.0, 1.0, 0.0]
 *              })
 *          }),
 *
 *          new Mesh(viewer.scene, { // Purple table top
 *              id: "tableTop",
 *              isObject: true, // <------ Node represents an object, so is registered by ID in viewer.scene.objects
 *              position: [0, -3, 0],
 *              scale: [6, 0.5, 6],
 *              rotation: [0, 0, 0],
 *              material: new PhongMaterial(viewer.scene, {
 *                  diffuse: [1.0, 0.3, 1.0]
 *              })
 *          })
 *      ]
 *  });
 *
 * // Find Nodes and Meshes by their IDs
 *
 * var table = viewer.scene.models["table"];                // Since table Node has isModel == true
 *
 * var redLeg = viewer.scene.objects["redLeg"];             // Since the Meshes have isObject == true
 * var greenLeg = viewer.scene.objects["greenLeg"];
 * var blueLeg = viewer.scene.objects["blueLeg"];
 *
 * // Highlight one of the table leg Meshes
 *
 * viewer.scene.setObjectsHighlighted(["redLeg"], true);    // Since the Meshes have isObject == true
 *
 * // Periodically update transforms on our Nodes and Meshes
 *
 * viewer.scene.on("tick", function () {
 *
 *       // Rotate legs
 *       redLeg.rotateY(0.5);
 *       greenLeg.rotateY(0.5);
 *       blueLeg.rotateY(0.5);
 *
 *       // Rotate table
 *       table.rotateY(0.5);
 *       table.rotateX(0.3);
 *   });
 * ````
 *
 * ## Metadata
 *
 * As mentioned, we can also associate {@link MetaModel}s and {@link MetaObject}s with our {@link Node}s and Meshes,
 * within a {@link MetaScene}. See {@link MetaScene} for an example.
 *
 * @implements {Entity}
 * @implements {Drawable}
 */
class Mesh extends Component {

    /**
     @private
     */
    get type() {
        return "Mesh";
    }

    /**
     * @constructor
     * @param {Component} owner Owner component. When destroyed, the owner will destroy this component as well.
     * @param {*} [cfg] Configs
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent scene, generated automatically when omitted.
     * @param {Boolean} [cfg.isModel] Specify ````true```` if this Mesh represents a model, in which case the Mesh will be registered by {@link Mesh#id} in {@link Scene#models} and may also have a corresponding {@link MetaModel} with matching {@link MetaModel#id}, registered by that ID in {@link MetaScene#metaModels}.
     * @param {Boolean} [cfg.isObject] Specify ````true```` if this Mesh represents an object, in which case the Mesh will be registered by {@link Mesh#id} in {@link Scene#objects} and may also have a corresponding {@link MetaObject} with matching {@link MetaObject#id}, registered by that ID in {@link MetaScene#metaObjects}.
     * @param {Node} [cfg.parent] The parent Node.
     * @param {Number[]} [cfg.position=[0,0,0]] Local 3D position.
     * @param {Number[]} [cfg.scale=[1,1,1]] Local scale.
     * @param {Number[]} [cfg.rotation=[0,0,0]] Local rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [cfg.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1] Local modelling transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Boolean} [cfg.visible=true] Indicates if the Mesh is initially visible.
     * @param {Boolean} [cfg.culled=false] Indicates if the Mesh is initially culled from view.
     * @param {Boolean} [cfg.pickable=true] Indicates if the Mesh is initially pickable.
     * @param {Boolean} [cfg.clippable=true] Indicates if the Mesh is initially clippable.
     * @param {Boolean} [cfg.collidable=true] Indicates if the Mesh is initially included in boundary calculations.
     * @param {Boolean} [cfg.castsShadow=true] Indicates if the Mesh initially casts shadows.
     * @param {Boolean} [cfg.receivesShadow=true]  Indicates if the Mesh initially receives shadows.
     * @param {Boolean} [cfg.xrayed=false] Indicates if the Mesh is initially xrayed.
     * @param {Boolean} [cfg.highlighted=false] Indicates if the Mesh is initially highlighted.
     * @param {Boolean} [cfg.selected=false] Indicates if the Mesh is initially selected.
     * @param {Boolean} [cfg.edges=false] Indicates if the Mesh's edges are initially emphasized.
     * @param {Number[]} [cfg.colorize=[1.0,1.0,1.0]] Mesh's initial RGB colorize color, multiplies by the rendered fragment colors.
     * @param {Number} [cfg.opacity=1.0] Mesh's initial opacity factor, multiplies by the rendered fragment alpha.
     * @param {String} [cfg.billboard="none"] Mesh's billboarding behaviour. Options are "none" for no billboarding, "spherical" to always directly face {@link Camera.eye}, rotating both vertically and horizontally, or "cylindrical" to face the {@link Camera#eye} while rotating only about its vertically axis (use that mode for things like trees on a landscape).
     * @param {Geometry} [cfg.geometry] {@link Geometry} to define the shape of this Mesh. Inherits {@link Scene#geometry} by default.
     * @param {Material} [cfg.material] {@link Material} to define the normal rendered appearance for this Mesh. Inherits {@link Scene#material} by default.
     * @param {EmphasisMaterial} [cfg.xrayMaterial] {@link EmphasisMaterial} to define the xrayed appearance for this Mesh. Inherits {@link Scene#xrayMaterial} by default.
     * @param {EmphasisMaterial} [cfg.highlightMaterial] {@link EmphasisMaterial} to define the xrayed appearance for this Mesh. Inherits {@link Scene#highlightMaterial} by default.
     * @param {EmphasisMaterial} [cfg.selectedMaterial] {@link EmphasisMaterial} to define the selected appearance for this Mesh. Inherits {@link Scene#selectedMaterial} by default.
     * @param {EmphasisMaterial} [cfg.edgeMaterial] {@link EdgeMaterial} to define the appearance of enhanced edges for this Mesh. Inherits {@link Scene#edgeMaterial} by default.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._state = new RenderState({ // NOTE: Renderer gets modeling and normal matrices from Mesh#matrix and Mesh.#normalWorldMatrix
            visible: true,
            culled: false,
            pickable: null,
            clippable: null,
            collidable: null,
            castsShadow: null,
            receivesShadow: null,
            xrayed: false,
            highlighted: false,
            selected: false,
            edges: false,
            stationary: !!cfg.stationary,
            billboard: this._checkBillboard(cfg.billboard),
            layer: null,
            colorize: null,
            pickID: this.scene._renderer.getPickID(this),
            drawHash: "",
            pickHash: ""
        });

        this._drawRenderer = null;
        this._shadowRenderer = null;
        this._emphasisFillRenderer = null;
        this._emphasisEdgesRenderer = null;
        this._pickMeshRenderer = null;
        this._pickTriangleRenderer = null;
        this._occlusionRenderer = null;

        this._geometry = cfg.geometry ? this._checkComponent2(["ReadableGeometry", "VBOGeometry"], cfg.geometry) : this.scene.geometry;
        this._material = cfg.material ? this._checkComponent2(["PhongMaterial", "MetallicMaterial", "SpecularMaterial", "LambertMaterial"], cfg.material) : this.scene.material;
        this._xrayMaterial = cfg.xrayMaterial ? this._checkComponent("EmphasisMaterial", cfg.xrayMaterial) : this.scene.xrayMaterial;
        this._highlightMaterial = cfg.highlightMaterial ? this._checkComponent("EmphasisMaterial", cfg.highlightMaterial) : this.scene.highlightMaterial;
        this._selectedMaterial = cfg.selectedMaterial ? this._checkComponent("EmphasisMaterial", cfg.selectedMaterial) : this.scene.selectedMaterial;
        this._edgeMaterial = cfg.edgeMaterial ? this._checkComponent("EdgeMaterial", cfg.edgeMaterial) : this.scene.edgeMaterial;

        this._parentNode = null;

        this._aabb = null;
        this._aabbDirty = true;

        this.scene._aabbDirty = true;

        this._scale = math.vec3();
        this._quaternion = math.identityQuaternion();
        this._rotation = math.vec3();
        this._position = math.vec3();

        this._worldMatrix = math.identityMat4();
        this._worldNormalMatrix = math.identityMat4();

        this._localMatrixDirty = true;
        this._worldMatrixDirty = true;
        this._worldNormalMatrixDirty = true;

        if (cfg.matrix) {
            this.matrix = cfg.matrix;
        } else {
            this.scale = cfg.scale;
            this.position = cfg.position;
            if (cfg.quaternion) {
            } else {
                this.rotation = cfg.rotation;
            }
        }

        this._isObject = cfg.isObject;
        if (this._isObject) {
            this.scene._registerObject(this);
        }

        this._isModel = cfg.isModel;
        if (this._isModel) {
            this.scene._registerModel(this);
        }

        this.visible = cfg.visible;
        this.culled = cfg.culled;
        this.pickable = cfg.pickable;
        this.clippable = cfg.clippable;
        this.collidable = cfg.collidable;
        this.castsShadow = cfg.castsShadow;
        this.receivesShadow = cfg.receivesShadow;
        this.xrayed = cfg.xrayed;
        this.highlighted = cfg.highlighted;
        this.selected = cfg.selected;
        this.edges = cfg.edges;
        this.layer = cfg.layer;
        this.colorize = cfg.colorize;
        this.opacity = cfg.opacity;

        if (cfg.parentId) {
            const parentNode = this.scene.components[cfg.parentId];
            if (!parentNode) {
                this.error("Parent not found: '" + cfg.parentId + "'");
            } else if (!parentNode.isNode) {
                this.error("Parent is not a Node: '" + cfg.parentId + "'");
            } else {
                parentNode.addChild(this);
            }
            this._parentNode = parentNode;
        } else if (cfg.parent) {
            if (!cfg.parent.isNode) {
                this.error("Parent is not a Node");
            }
            cfg.parent.addChild(this);
            this._parentNode = cfg.parent;
        }

        this.compile();
    }

    //------------------------------------------------------------------------------------------------------------------
    // Mesh members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that this Component is a Mesh.
     * @final
     * @type {Boolean}
     */
    get isMesh() {
        return true;
    }

    /**
     * The parent Node.
     *
     * The parent Node may also be set by passing the Mesh to the parent's {@link Node#addChild} method.
     *
     * @type {Node}
     */
    get parent() {
        return this._parentNode;
    }

    _checkBillboard(value) {
        value = value || "none";
        if (value !== "spherical" && value !== "cylindrical" && value !== "none") {
            this.error("Unsupported value for 'billboard': " + value + " - accepted values are " +
                "'spherical', 'cylindrical' and 'none' - defaulting to 'none'.");
            value = "none";
        }
        return value;
    }

    /**
     * Called by xeokit to compile shaders for this Mesh.
     * @private
     */
    compile() {
        const drawHash = this._makeDrawHash();
        if (this._state.drawHash !== drawHash) {
            this._state.drawHash = drawHash;
            this._putDrawRenderers();
            this._drawRenderer = DrawRenderer.get(this);
            // this._shadowRenderer = ShadowRenderer.get(this);
            this._emphasisFillRenderer = EmphasisFillRenderer.get(this);
            this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this);
        }
        const pickHash = this._makePickHash();
        if (this._state.pickHash !== pickHash) {
            this._state.pickHash = pickHash;
            this._putPickRenderers();
            this._pickMeshRenderer = PickMeshRenderer.get(this);
        }
        const occlusionHash = this._makeOcclusionHash();
        if (this._state.occlusionHash !== occlusionHash) {
            this._state.occlusionHash = occlusionHash;
            this._putOcclusionRenderer();
            this._occlusionRenderer = OcclusionRenderer.get(this);
        }
    }

    _setLocalMatrixDirty() {
        this._localMatrixDirty = true;
        this._setWorldMatrixDirty();
    }

    _setWorldMatrixDirty() {
        this._worldMatrixDirty = true;
        this._worldNormalMatrixDirty = true;
    }

    _buildWorldMatrix() {
        const localMatrix = this.matrix;
        if (!this._parentNode) {
            for (let i = 0, len = localMatrix.length; i < len; i++) {
                this._worldMatrix[i] = localMatrix[i];
            }
        } else {
            math.mulMat4(this._parentNode.worldMatrix, localMatrix, this._worldMatrix);
        }
        this._worldMatrixDirty = false;
    }

    _buildWorldNormalMatrix() {
        if (this._worldMatrixDirty) {
            this._buildWorldMatrix();
        }
        if (!this._worldNormalMatrix) {
            this._worldNormalMatrix = math.mat4();
        }
        // Note: order of inverse and transpose doesn't matter
        math.transposeMat4(this._worldMatrix, this._worldNormalMatrix);
        math.inverseMat4(this._worldNormalMatrix);
        this._worldNormalMatrixDirty = false;
    }

    _setAABBDirty() {
        if (this.collidable) {
            for (let node = this; node; node = node._parentNode) {
                node._aabbDirty = true;
            }
        }
    }

    _updateAABB() {
        this.scene._aabbDirty = true;
        if (!this._aabb) {
            this._aabb = math.AABB3();
        }
        this._buildAABB(this.worldMatrix, this._aabb); // Mesh or PerformanceModel
        this._aabbDirty = false;
    }

    _webglContextRestored() {
        if (this._drawRenderer) {
            this._drawRenderer.webglContextRestored();
        }
        if (this._shadowRenderer) {
            this._shadowRenderer.webglContextRestored();
        }
        if (this._emphasisFillRenderer) {
            this._emphasisFillRenderer.webglContextRestored();
        }
        if (this._emphasisEdgesRenderer) {
            this._emphasisEdgesRenderer.webglContextRestored();
        }
        if (this._pickMeshRenderer) {
            this._pickMeshRenderer.webglContextRestored();
        }
        if (this._pickTriangleRenderer) {
            this._pickMeshRenderer.webglContextRestored();
        }
        if (this._occlusionRenderer) {
            this._occlusionRenderer.webglContextRestored();
        }
    }

    _makeDrawHash() {
        const scene = this.scene;
        const hash = [
            scene.canvas.canvas.id,
            (scene.gammaInput ? "gi;" : ";") + (scene.gammaOutput ? "go" : ""),
            scene._lightsState.getHash(),
            scene._sectionPlanesState.getHash()
        ];
        const state = this._state;
        if (state.stationary) {
            hash.push("/s");
        }
        if (state.billboard === "none") {
            hash.push("/n");
        } else if (state.billboard === "spherical") {
            hash.push("/s");
        } else if (state.billboard === "cylindrical") {
            hash.push("/c");
        }
        if (state.receivesShadow) {
            hash.push("/rs");
        }
        hash.push(";");
        return hash.join("");
    }

    _makePickHash() {
        const scene = this.scene;
        const hash = [
            scene.canvas.canvas.id,
            scene._sectionPlanesState.getHash()
        ];
        const state = this._state;
        if (state.stationary) {
            hash.push("/s");
        }
        if (state.billboard === "none") {
            hash.push("/n");
        } else if (state.billboard === "spherical") {
            hash.push("/s");
        } else if (state.billboard === "cylindrical") {
            hash.push("/c");
        }
        hash.push(";");
        return hash.join("");
    }

    _makeOcclusionHash() {
        const scene = this.scene;
        const hash = [
            scene.canvas.canvas.id,
            scene._sectionPlanesState.getHash()
        ];
        const state = this._state;
        if (state.stationary) {
            hash.push("/s");
        }
        if (state.billboard === "none") {
            hash.push("/n");
        } else if (state.billboard === "spherical") {
            hash.push("/s");
        } else if (state.billboard === "cylindrical") {
            hash.push("/c");
        }
        hash.push(";");
        return hash.join("");
    }

    _buildAABB(worldMatrix, boundary) {
        math.transformOBB3(worldMatrix, this._geometry.obb, obb);
        math.OBB3ToAABB3(obb, boundary);
    }

    /**
     * Defines the shape of this Mesh.
     *
     * Set to {@link Scene#geometry} by default.
     *
     * @type {Geometry}
     */
    get geometry() {
        return this._geometry;
    }

    /**
     * Defines the appearance of this Mesh when rendering normally, ie. when not xrayed, highlighted or selected.
     *
     * Set to {@link Scene#material} by default.
     *
     * @type {Material}
     */
    get material() {
        return this._material;
    }

    /**
     * Sets the Mesh's local translation.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    set position(value) {
        this._position.set(value || [0, 0, 0]);
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Mesh's local translation.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    get position() {
        return this._position;
    }

    /**
     * Sets the Mesh's local rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    set rotation(value) {
        this._rotation.set(value || [0, 0, 0]);
        math.eulerToQuaternion(this._rotation, "XYZ", this._quaternion);
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Mesh's local rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    get rotation() {
        return this._rotation;
    }

    /**
     * Sets the Mesh's local rotation quaternion.
     *
     * Default value is ````[0,0,0,1]````.
     *
     * @type {Number[]}
     */
    set quaternion(value) {
        this._quaternion.set(value || [0, 0, 0, 1]);
        math.quaternionToEuler(this._quaternion, "XYZ", this._rotation);
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Mesh's local rotation quaternion.
     *
     * Default value is ````[0,0,0,1]````.
     *
     * @type {Number[]}
     */
    get quaternion() {
        return this._quaternion;
    }

    /**
     * Sets the Mesh's local scale.
     *
     * Default value is ````[1,1,1]````.
     *
     * @type {Number[]}
     */
    set scale(value) {
        this._scale.set(value || [1, 1, 1]);
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Mesh's local scale.
     *
     * Default value is ````[1,1,1]````.
     *
     * @type {Number[]}
     */
    get scale() {
        return this._scale;
    }

    /**
     * Sets the Mesh's local modeling transform matrix.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @type {Number[]}
     */
    set matrix(value) {
        if (!this.__localMatrix) {
            this.__localMatrix = math.identityMat4();
        }
        this.__localMatrix.set(value || identityMat);
        math.decomposeMat4(this.__localMatrix, this._position, this._quaternion, this._scale);
        this._localMatrixDirty = false;
        this._setWorldMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Mesh's local modeling transform matrix.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @type {Number[]}
     */
    get matrix() {
        if (this._localMatrixDirty) {
            if (!this.__localMatrix) {
                this.__localMatrix = math.identityMat4();
            }
            math.composeMat4(this._position, this._quaternion, this._scale, this.__localMatrix);
            this._localMatrixDirty = false;
        }
        return this.__localMatrix;
    }

    /**
     * Gets the Mesh's World matrix.
     *
     * @property worldMatrix
     * @type {Number[]}
     */
    get worldMatrix() {
        if (this._worldMatrixDirty) {
            this._buildWorldMatrix();
        }
        return this._worldMatrix;
    }

    /**
     * Gets the Mesh's World normal matrix.
     *
     * @type {Number[]}
     */
    get worldNormalMatrix() {
        if (this._worldNormalMatrixDirty) {
            this._buildWorldNormalMatrix();
        }
        return this._worldNormalMatrix;
    }

    /**
     * Rotates the Mesh about the given local axis by the given increment.
     *
     * @param {Number[]} axis Local axis about which to rotate.
     * @param {Number} angle Angle increment in degrees.
     */
    rotate(axis, angle) {
        angleAxis[0] = axis[0];
        angleAxis[1] = axis[1];
        angleAxis[2] = axis[2];
        angleAxis[3] = angle * math.DEGTORAD;
        math.angleAxisToQuaternion(angleAxis, q1);
        math.mulQuaternions(this.quaternion, q1, q2);
        this.quaternion = q2;
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
        return this;
    }

    /**
     * Rotates the Mesh about the given World-space axis by the given increment.
     *
     * @param {Number[]} axis Local axis about which to rotate.
     * @param {Number} angle Angle increment in degrees.
     */
    rotateOnWorldAxis(axis, angle) {
        angleAxis[0] = axis[0];
        angleAxis[1] = axis[1];
        angleAxis[2] = axis[2];
        angleAxis[3] = angle * math.DEGTORAD;
        math.angleAxisToQuaternion(angleAxis, q1);
        math.mulQuaternions(q1, this.quaternion, q1);
        //this.quaternion.premultiply(q1);
        return this;
    }

    /**
     * Rotates the Mesh about the local X-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateX(angle) {
        return this.rotate(xAxis, angle);
    }

    /**
     * Rotates the Mesh about the local Y-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateY(angle) {
        return this.rotate(yAxis, angle);
    }

    /**
     * Rotates the Mesh about the local Z-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateZ(angle) {
        return this.rotate(zAxis, angle);
    }

    /**
     * Translates the Mesh along local space vector by the given increment.
     *
     * @param {Number[]} axis Normalized local space 3D vector along which to translate.
     * @param {Number} distance Distance to translate along  the vector.
     */
    translate(axis, distance) {
        math.vec3ApplyQuaternion(this.quaternion, axis, veca);
        math.mulVec3Scalar(veca, distance, vecb);
        math.addVec3(this.position, vecb, this.position);
        this._setLocalMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
        return this;
    }

    /**
     * Translates the Mesh along the local X-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the X-axis.
     */
    translateX(distance) {
        return this.translate(xAxis, distance);
    }

    /**
     * Translates the Mesh along the local Y-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the Y-axis.
     */
    translateY(distance) {
        return this.translate(yAxis, distance);
    }

    /**
     * Translates the Mesh along the local Z-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the Z-axis.
     */
    translateZ(distance) {
        return this.translate(zAxis, distance);
    }

    _putDrawRenderers() {
        if (this._drawRenderer) {
            this._drawRenderer.put();
            this._drawRenderer = null;
        }
        if (this._shadowRenderer) {
            this._shadowRenderer.put();
            this._shadowRenderer = null;
        }
        if (this._emphasisFillRenderer) {
            this._emphasisFillRenderer.put();
            this._emphasisFillRenderer = null;
        }
        if (this._emphasisEdgesRenderer) {
            this._emphasisEdgesRenderer.put();
            this._emphasisEdgesRenderer = null;
        }
    }

    _putPickRenderers() {
        if (this._pickMeshRenderer) {
            this._pickMeshRenderer.put();
            this._pickMeshRenderer = null;
        }
        if (this._pickTriangleRenderer) {
            this._pickTriangleRenderer.put();
            this._pickTriangleRenderer = null;
        }
    }

    _putOcclusionRenderer() {
        if (this._occlusionRenderer) {
            this._occlusionRenderer.put();
            this._occlusionRenderer = null;
        }
    }


    //------------------------------------------------------------------------------------------------------------------
    // Entity members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that Mesh implements {@link Entity}.
     *
     * @returns {Boolean}
     */
    get isEntity() {
        return true;
    }

    /**
     * Returns ````true```` if this Mesh represents a model.
     *
     * When this returns ````true````, the Mesh will be registered by {@link Mesh#id} in {@link Scene#models} and
     * may also have a corresponding {@link MetaModel}.
     *
     * @type {Boolean}
     */
    get isModel() {
        return this._isModel;
    }

    /**
     * Returns ````true```` if this Mesh represents an object.
     *
     * When this returns ````true````, the Mesh will be registered by {@link Mesh#id} in {@link Scene#objects} and
     * may also have a corresponding {@link MetaObject}.
     *
     * @type {Boolean}
     */
    get isObject() {
        return this._isObject;
    }

    /**
     * Gets the Mesh's World-space 3D axis-aligned bounding box.
     *
     * Represented by a six-element Float32Array containing the min/max extents of the
     * axis-aligned volume, ie. ````[xmin, ymin,zmin,xmax,ymax, zmax]````.
     *
     * @type {Number[]}
     */
    get aabb() {
        if (this._aabbDirty) {
            this._updateAABB();
        }
        return this._aabb;
    }

    /**
     * Sets if this Mesh is visible.
     *
     * Only rendered when {@link Mesh#visible} is ````true```` and {@link Mesh#culled} is ````false````.
     *
     * When {@link Mesh#isObject} and {@link Mesh#visible} are both ````true```` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    set visible(visible) {
        visible = visible !== false;
        this._state.visible = visible;
        if (this._isObject) {
            this.scene._objectVisibilityUpdated(this);
        }
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is visible.
     *
     * Only rendered when {@link Mesh#visible} is ````true```` and {@link Mesh#culled} is ````false````.
     *
     * When {@link Mesh#isObject} and {@link Mesh#visible} are both ````true```` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    get visible() {
        return this._state.visible;
    }

    /**
     * Sets if this Mesh is xrayed.
     *
     * XRayed appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#xrayMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#xrayed} are both ````true``` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#xrayedObjects}.
     *
     * @type {Boolean}
     */
    set xrayed(xrayed) {
        xrayed = !!xrayed;
        if (this._state.xrayed === xrayed) {
            return;
        }
        this._state.xrayed = xrayed;
        if (this._isObject) {
            this.scene._objectXRayedUpdated(this);
        }
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is xrayed.
     *
     * XRayed appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#xrayMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#xrayed} are both ````true``` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#xrayedObjects}.
     *
     * @type {Boolean}
     */
    get xrayed() {
        return this._state.xrayed;
    }

    /**
     * Sets if this Mesh is highlighted.
     *
     * Highlighted appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#highlightMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#highlighted} are both ````true```` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    set highlighted(highlighted) {
        highlighted = !!highlighted;
        if (highlighted === this._state.highlighted) {
            return;
        }
        this._state.highlighted = highlighted;
        if (this._isObject) {
            this.scene._objectHighlightedUpdated(this);
        }
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is highlighted.
     *
     * Highlighted appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#highlightMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#highlighted} are both ````true```` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    get highlighted() {
        return this._state.highlighted;
    }

    /**
     * Sets if this Mesh is selected.
     *
     * Selected appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#selectedMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#selected} are both ````true``` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#selectedObjects}.
     *
     * @type {Boolean}
     */
    set selected(selected) {
        selected = !!selected;
        if (selected === this._state.selected) {
            return;
        }
        this._state.selected = selected;
        if (this._isObject) {
            this.scene._objectSelectedUpdated(this);
        }
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is selected.
     *
     * Selected appearance is configured by the {@link EmphasisMaterial} referenced by {@link Mesh#selectedMaterial}.
     *
     * When {@link Mesh#isObject} and {@link Mesh#selected} are both ````true``` the Mesh will be
     * registered by {@link Mesh#id} in {@link Scene#selectedObjects}.
     *
     * @type {Boolean}
     */
    get selected() {
        return this._state.selected;
    }

    /**
     * Sets if this Mesh is edge-enhanced.
     *
     * Edge appearance is configured by the {@link EdgeMaterial} referenced by {@link Mesh#edgeMaterial}.
     *
     * @type {Boolean}
     */
    set edges(edges) {
        edges = !!edges;
        if (edges === this._state.edges) {
            return;
        }
        this._state.edges = edges;
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is edge-enhanced.
     *
     * Edge appearance is configured by the {@link EdgeMaterial} referenced by {@link Mesh#edgeMaterial}.
     *
     * @type {Boolean}
     */
    get edges() {
        return this._state.edges;
    }

    /**
     * Sets if this Mesh is culled.
     *
     * Only rendered when {@link Mesh#visible} is ````true```` and {@link Mesh#culled} is ````false````.
     *
     * @type {Boolean}
     */
    set culled(value) {
        this._state.culled = !!value;
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is culled.
     *
     * Only rendered when {@link Mesh#visible} is ````true```` and {@link Mesh#culled} is ````false````.
     *
     * @type {Boolean}
     */
    get culled() {
        return this._state.culled;
    }

    /**
     * Sets if this Mesh is clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#sectionPlanes}.
     *
     * @type {Boolean}
     */
    set clippable(value) {
        value = value !== false;
        if (this._state.clippable === value) {
            return;
        }
        this._state.clippable = value;
        this.glRedraw();
    }

    /**
     * Gets if this Mesh is clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#sectionPlanes}.
     *
     * @type {Boolean}
     */
    get clippable() {
        return this._state.clippable;
    }

    /**
     * Sets if this Mesh included in boundary calculations.
     *
     * @type {Boolean}
     */
    set collidable(value) {
        value = value !== false;
        if (value === this._state.collidable) {
            return;
        }
        this._state.collidable = value;
        this._setAABBDirty();
        this.scene._aabbDirty = true;

    }

    /**
     * Gets if this Mesh included in boundary calculations.
     *
     * @type {Boolean}
     */
    get collidable() {
        return this._state.collidable;
    }

    /**
     * Sets if this Mesh is pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * @type {Boolean}
     */
    set pickable(value) {
        value = value !== false;
        if (this._state.pickable === value) {
            return;
        }
        this._state.pickable = value;
        // No need to trigger a render;
        // state is only used when picking
    }

    /**
     * Gets if this Mesh is pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * @type {Boolean}
     */
    get pickable() {
        return this._state.pickable;
    }

    /**
     * Sets if this Mesh casts shadows.
     *
     * @type {Boolean}
     */
    set castsShadow(value) {
        value = value !== false;
        if (value === this._state.castsShadow) {
            return;
        }
        this._state.castsShadow = value;
        this.glRedraw();
    }

    /**
     * Gets if this Mesh casts shadows.
     *
     * @type {Boolean}
     */
    get castsShadow() {
        return this._state.castsShadow;
    }

    /**
     * Sets if this Mesh can have shadows cast upon it.
     *
     * @type {Boolean}
     */
    set receivesShadow(value) {
        this._state.receivesShadow = false; // Disables shadows for now
        // value = value !== false;
        // if (value === this._state.receivesShadow) {
        //     return;
        // }
        // this._state.receivesShadow = value;
        // this._state.hash = value ? "/mod/rs;" : "/mod;";
        // this.fire("dirty", this); // Now need to (re)compile objectRenderers to include/exclude shadow mapping
    }

    /**
     * Gets if this Mesh can have shadows cast upon it.
     *
     * @type {Boolean}
     */
    get receivesShadow() {
        return this._state.receivesShadow;
    }

    /**
     * Sets the RGB colorize color for this Mesh.
     *
     * Multiplies by rendered fragment colors.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * @type {Number[]}
     */
    set colorize(value) {
        let colorize = this._state.colorize;
        if (!colorize) {
            colorize = this._state.colorize = new Float32Array(4);
            colorize[3] = 1;
        }
        if (value) {
            colorize[0] = value[0];
            colorize[1] = value[1];
            colorize[2] = value[2];
        } else {
            colorize[0] = 1;
            colorize[1] = 1;
            colorize[2] = 1;
        }
        this.glRedraw();
    }

    /**
     * Gets the RGB colorize color for this Mesh.
     *
     * Multiplies by rendered fragment colors.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * @type {Number[]}
     */
    get colorize() {
        return this._state.colorize;
    }

    /**
     * Sets the opacity factor for this Mesh.
     *
     * This is a factor in range ````[0..1]```` which multiplies by the rendered fragment alphas.
     *
     * @type {Number}
     */
    set opacity(opacity) {
        let colorize = this._state.colorize;
        if (!colorize) {
            colorize = this._state.colorize = new Float32Array(4);
            colorize[0] = 1;
            colorize[1] = 1;
            colorize[2] = 1;
        }
        colorize[3] = opacity !== null && opacity !== undefined ? opacity : 1.0;
        this.glRedraw();
    }

    /**
     * Gets the opacity factor for this Mesh.
     *
     * This is a factor in range ````[0..1]```` which multiplies by the rendered fragment alphas.
     *
     * @type {Number}
     */
    get opacity() {
        return this._state.colorize[3];
    }

    /**
     * Gets if this Mesh is transparent.
     * @returns {Boolean}
     */
    get transparent() {
        return this._material.alphaMode === 2 /* blend */ || this._state.colorize[3] < 1
    }

    /**
     * Sets the Mesh's rendering order relative to other Meshes.
     *
     * Default value is ````0````.
     *
     * This can be set on multiple transparent Meshes, to make them render in a specific order for correct alpha blending.
     *
     * @type {Number}
     */
    set layer(value) {
        // TODO: Only accept rendering layer in range [0...MAX_layer]
        value = value || 0;
        value = Math.round(value);
        if (value === this._state.layer) {
            return;
        }
        this._state.layer = value;
        this._renderer.needStateSort();
    }

    /**
     * Gets the Mesh's rendering order relative to other Meshes.
     *
     * Default value is ````0````.
     *
     * This can be set on multiple transparent Meshes, to make them render in a specific order for correct alpha blending.
     *
     * @type {Number}
     */
    get layer() {
        return this._state.layer;
    }

    /**
     * Gets if the Node's position is stationary.
     *
     * When true, will disable the effect of {@link Camera} translations for this Mesh, while still allowing it to rotate. This is useful for skyboxes.
     *
     * @type {Boolean}
     */
    get stationary() {
        return this._state.stationary;
    }

    /**
     * Gets the Node's billboarding behaviour.
     *
     * Options are:
     * * ````"none"```` -  (default) - No billboarding.
     * * ````"spherical"```` - Mesh is billboarded to face the viewpoint, rotating both vertically and horizontally.
     * * ````"cylindrical"```` - Mesh is billboarded to face the viewpoint, rotating only about its vertically axis. Use this mode for things like trees on a landscape.
     * @type {String}
     */
    get billboard() {
        return this._state.billboard;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Drawable members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that Mesh implements {@link Drawable}.
     * @final
     * @type {Boolean}
     */
    get isDrawable() {
        return true;
    }

    /**
     * Property with final value ````true```` to indicate that xeokit should render this Mesh in sorted order, relative to other Meshes.
     *
     * The sort order is determined by {@link Mesh#stateSortCompare}.
     *
     * Sorting is essential for rendering performance, so that xeokit is able to avoid applying runs of the same state changes to the GPU, ie. can collapse them.
     *
     * @type {Boolean}
     */
    get isStateSortable() {
        return true;
    }

    /**
     * Comparison function used by the renderer to determine the order in which xeokit should render the Mesh, relative to to other Meshes.
     *
     * xeokit requires this method because Mesh implements {@link Drawable}.
     *
     * Sorting is essential for rendering performance, so that xeokit is able to avoid needlessly applying runs of the same rendering state changes to the GPU, ie. can collapse them.
     *
     * @param {Mesh} mesh1
     * @param {Mesh} mesh2
     * @returns {number}
     */
    stateSortCompare(mesh1, mesh2) {
        return (mesh1._state.layer - mesh2._state.layer)
            || (mesh1._drawRenderer.id - mesh2._drawRenderer.id) // Program state
            || (mesh1._material._state.id - mesh2._material._state.id) // Material state
            || (mesh1._geometry._state.id - mesh2._geometry._state.id); // Geometry state
    }

    /**
     * Called by xeokit when about to render this Mesh, to get flags indicating what rendering effects to apply for it.
     *
     * @param {RenderFlags} renderFlags Returns the rendering flags.
     */
    getRenderFlags(renderFlags) {

        renderFlags.reset();

        const state = this._state;

        if (state.xrayed) {
            const xrayMaterial = this._xrayMaterial._state;
            if (xrayMaterial.fill) {
                if (xrayMaterial.fillAlpha < 1.0) {
                    renderFlags.xrayedFillTransparent = true;
                } else {
                    renderFlags.xrayedFillOpaque = true;
                }
            }
            if (xrayMaterial.edges) {
                if (xrayMaterial.edgeAlpha < 1.0) {
                    renderFlags.xrayedEdgesTransparent = true;
                } else {
                    renderFlags.xrayedEdgesOpaque = true;
                }
            }
        } else {
            const normalMaterial = this._material._state;
            if (normalMaterial.alpha < 1.0 || state.colorize[3] < 1.0) {
                renderFlags.normalFillTransparent = true;
            } else {
                renderFlags.normalFillOpaque = true;
            }
            if (state.edges) {
                const edgeMaterial = this._edgeMaterial._state;
                if (edgeMaterial.alpha < 1.0) {
                    renderFlags.normalEdgesTransparent = true;
                } else {
                    renderFlags.normalEdgesOpaque = true;
                }
            }
            if (state.selected) {
                const selectedMaterial = this._selectedMaterial._state;
                if (selectedMaterial.fill) {
                    if (selectedMaterial.fillAlpha < 1.0) {
                        renderFlags.selectedFillTransparent = true;
                    } else {
                        renderFlags.selectedFillOpaque = true;
                    }
                }
                if (selectedMaterial.edges) {
                    if (selectedMaterial.edgeAlpha < 1.0) {
                        renderFlags.selectedEdgesTransparent = true;
                    } else {
                        renderFlags.selectedEdgesOpaque = true;
                    }
                }
            } else if (state.highlighted) {
                const highlightMaterial = this._highlightMaterial._state;
                if (highlightMaterial.fill) {
                    if (highlightMaterial.fillAlpha < 1.0) {
                        renderFlags.highlightedFillTransparent = true;
                    } else {
                        renderFlags.highlightedFillOpaque = true;
                    }
                }
                if (highlightMaterial.edges) {
                    if (highlightMaterial.edgeAlpha < 1.0) {
                        renderFlags.highlightedEdgesTransparent = true;
                    } else {
                        renderFlags.highlightedEdgesOpaque = true;
                    }
                }
            }
        }
    }

    /**
     * Defines the appearance of this Mesh when xrayed.
     *
     * Mesh is xrayed when {@link Mesh#xrayed} is ````true````.
     *
     * Set to {@link Scene#xrayMaterial} by default.
     *
     * @type {EmphasisMaterial}
     */
    get xrayMaterial() {
        return this._xrayMaterial;
    }

    /**
     * Defines the appearance of this Mesh when highlighted.
     *
     * Mesh is xrayed when {@link Mesh#highlighted} is ````true````.
     *
     * Set to {@link Scene#highlightMaterial} by default.
     *
     * @type {EmphasisMaterial}
     */
    get highlightMaterial() {
        return this._highlightMaterial;
    }

    /**
     * Defines the appearance of this Mesh when selected.
     *
     * Mesh is xrayed when {@link Mesh#selected} is ````true````.
     *
     * Set to {@link Scene#selectedMaterial} by default.
     *
     * @type {EmphasisMaterial}
     */
    get selectedMaterial() {
        return this._selectedMaterial;
    }

    /**
     * Defines the appearance of this Mesh when edges are enhanced.
     *
     * Mesh is xrayed when {@link Mesh#edges} is ````true````.
     *
     * Set to {@link Scene#edgeMaterial} by default.
     *
     * @type {EdgeMaterial}
     */
    get edgeMaterial() {
        return this._edgeMaterial;
    }

    /** @private  */
    drawNormalFillOpaque(frameCtx) {
        if (this._drawRenderer || (this._drawRenderer = DrawRenderer.get(this))) {
            this._drawRenderer.drawMesh(frameCtx, this);
        }
    }

    /** @private  */
    drawNormalEdgesOpaque(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 3); // 3 == edges
        }
    }

    /** @private  */
    drawNormalFillTransparent(frameCtx) {
        if (this._drawRenderer || (this._drawRenderer = DrawRenderer.get(this))) {
            this._drawRenderer.drawMesh(frameCtx, this);
        }
    }

    /** @private  */
    drawNormalEdgesTransparent(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 3); // 3 == edges
        }
    }

    /** @private  */
    drawXRayedFillOpaque(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 0); // 0 == xray
        }
    }

    /** @private  */
    drawXRayedEdgesOpaque(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 0); // 0 == xray
        }
    }

    /** @private  */
    drawXRayedFillTransparent(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 0); // 0 == xray
        }
    }

    /** @private  */
    drawXRayedEdgesTransparent(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 0); // 0 == xray
        }
    }

    /** @private  */
    drawHighlightedFillOpaque(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 1); // 1 == highlight
        }
    }

    /** @private  */
    drawHighlightedEdgesOpaque(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 1); // 1 == highlight
        }
    }

    /** @private  */
    drawHighlightedFillTransparent(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 1); // 1 == highlight
        }
    }

    /** @private  */
    drawHighlightedEdgesTransparent(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 1); // 1 == highlight
        }
    }

    /** @private  */
    drawSelectedFillOpaque(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 2); // 2 == selected
        }
    }

    /** @private  */
    drawSelectedEdgesOpaque(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 2); // 2 == selected
        }
    }

    /** @private  */
    drawSelectedFillTransparent(frameCtx) {
        if (this._emphasisFillRenderer || (this._emphasisFillRenderer = EmphasisFillRenderer.get(this))) {
            this._emphasisFillRenderer.drawMesh(frameCtx, this, 2); // 2 == selected
        }
    }

    /** @private  */
    drawSelectedEdgesTransparent(frameCtx) {
        if (this._emphasisEdgesRenderer || (this._emphasisEdgesRenderer = EmphasisEdgesRenderer.get(this))) {
            this._emphasisEdgesRenderer.drawMesh(frameCtx, this, 2); // 2 == selected
        }
    }

    /** @private  */
    drawPickMesh(frameCtx) {
        if (this._pickMeshRenderer || (this._pickMeshRenderer = PickMeshRenderer.get(this))) {
            this._pickMeshRenderer.drawMesh(frameCtx, this);
        }
    }

    /** @private  */
    drawOcclusion(frameCtx) {
        if (this._occlusionRenderer || (this._occlusionRenderer = OcclusionRenderer.get(this))) {
            this._occlusionRenderer.drawMesh(frameCtx, this);
        }
    }

    /** @private
     */
    canPickTriangle() {
        return this._geometry.isReadableGeometry; // VBOGeometry does not support surface picking because it has no geometry data in browser memory
    }

    /** @private  */
    drawPickTriangles(frameCtx) {
        if (this._pickTriangleRenderer || (this._pickTriangleRenderer = PickTriangleRenderer.get(this))) {
            this._pickTriangleRenderer.drawMesh(frameCtx, this);
        }
    }

    /** @private */
    pickTriangleSurface(pickViewMatrix, pickProjMatrix, pickResult) {
        pickTriangleSurface(this, pickViewMatrix, pickProjMatrix, pickResult);
    }

    /** @private  */
    drawPickVertices(frameCtx) {

    }

    /**
     * @private
     * @returns {PerformanceNode}
     */
    delegatePickedEntity() {
        return this;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Component members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Destroys this Mesh.
     */
    destroy() {
        super.destroy(); // xeokit.Object
        this._putDrawRenderers();
        this._putPickRenderers();
        this._putOcclusionRenderer();
        this.scene._renderer.putPickID(this._state.pickID); // TODO: somehow puch this down into xeokit framework?
        if (this._isObject) {
            this.scene._deregisterObject(this);
            if (this._visible) {
                this.scene._objectVisibilityUpdated(this, false);
            }
            if (this._xrayed) {
                this.scene._objectXRayedUpdated(this, false);
            }
            if (this._selected) {
                this.scene._objectSelectedUpdated(this, false);
            }
            if (this._highlighted) {
                this.scene._objectHighlightedUpdated(this, false);
            }
        }
        if (this._isModel) {
            this.scene._deregisterModel(this);
        }
        this.glRedraw();
    }

}


const pickTriangleSurface = (function () {

    // Cached vars to avoid garbage collection

    const localRayOrigin = math.vec3();
    const localRayDir = math.vec3();
    const positionA = math.vec3();
    const positionB = math.vec3();
    const positionC = math.vec3();
    const triangleVertices = math.vec3();
    const position = math.vec4();
    const worldPos = math.vec3();
    const viewPos = math.vec3();
    const bary = math.vec3();
    const normalA = math.vec3();
    const normalB = math.vec3();
    const normalC = math.vec3();
    const uva = math.vec3();
    const uvb = math.vec3();
    const uvc = math.vec3();
    const tempVec4a = math.vec4();
    const tempVec4b = math.vec4();
    const tempVec4c = math.vec4();
    const tempVec3 = math.vec3();
    const tempVec3b = math.vec3();
    const tempVec3c = math.vec3();
    const tempVec3d = math.vec3();
    const tempVec3e = math.vec3();
    const tempVec3f = math.vec3();
    const tempVec3g = math.vec3();
    const tempVec3h = math.vec3();
    const tempVec3i = math.vec3();
    const tempVec3j = math.vec3();
    const tempVec3k = math.vec3();

    return function (mesh, pickViewMatrix, pickProjMatrix, pickResult) {

        var primIndex = pickResult.primIndex;

        if (primIndex !== undefined && primIndex !== null && primIndex > -1) {

            const geometry = mesh.geometry._state;
            const scene = mesh.scene;
            const camera = scene.camera;
            const canvas = scene.canvas;

            if (geometry.primitiveName === "triangles") {

                // Triangle picked; this only happens when the
                // Mesh has a Geometry that has primitives of type "triangle"

                pickResult.primitive = "triangle";

                // Get the World-space positions of the triangle's vertices

                const i = primIndex; // Indicates the first triangle index in the indices array

                const indices = geometry.indices; // Indices into geometry arrays, not into shared VertexBufs
                const positions = geometry.positions;

                let ia3;
                let ib3;
                let ic3;

                if (indices) {

                    var ia = indices[i + 0];
                    var ib = indices[i + 1];
                    var ic = indices[i + 2];

                    triangleVertices[0] = ia;
                    triangleVertices[1] = ib;
                    triangleVertices[2] = ic;

                    pickResult.indices = triangleVertices;

                    ia3 = ia * 3;
                    ib3 = ib * 3;
                    ic3 = ic * 3;

                } else {

                    ia3 = i * 3;
                    ib3 = ia3 + 3;
                    ic3 = ib3 + 3;
                }

                positionA[0] = positions[ia3 + 0];
                positionA[1] = positions[ia3 + 1];
                positionA[2] = positions[ia3 + 2];

                positionB[0] = positions[ib3 + 0];
                positionB[1] = positions[ib3 + 1];
                positionB[2] = positions[ib3 + 2];

                positionC[0] = positions[ic3 + 0];
                positionC[1] = positions[ic3 + 1];
                positionC[2] = positions[ic3 + 2];

                if (geometry.compressGeometry) {

                    // Decompress vertex positions

                    const positionsDecodeMatrix = geometry.positionsDecodeMatrix;
                    if (positionsDecodeMatrix) {
                        geometryCompressionUtils.decompressPosition(positionA, positionsDecodeMatrix, positionA);
                        geometryCompressionUtils.decompressPosition(positionB, positionsDecodeMatrix, positionB);
                        geometryCompressionUtils.decompressPosition(positionC, positionsDecodeMatrix, positionC);
                    }
                }

                // Attempt to ray-pick the triangle in local space

                let canvasPos;

                if (pickResult.canvasPos) {
                    canvasPos = pickResult.canvasPos;
                    math.canvasPosToLocalRay(canvas.canvas, pickViewMatrix, pickProjMatrix, mesh.worldMatrix, canvasPos, localRayOrigin, localRayDir);

                } else if (pickResult.origin && pickResult.direction) {
                    math.worldRayToLocalRay(mesh.worldMatrix, pickResult.origin, pickResult.direction, localRayOrigin, localRayDir);
                }

                math.normalizeVec3(localRayDir);
                math.rayPlaneIntersect(localRayOrigin, localRayDir, positionA, positionB, positionC, position);

                // Get Local-space cartesian coordinates of the ray-triangle intersection

                pickResult.localPos = position;
                pickResult.position = position;

                // Get interpolated World-space coordinates

                // Need to transform homogeneous coords

                tempVec4a[0] = position[0];
                tempVec4a[1] = position[1];
                tempVec4a[2] = position[2];
                tempVec4a[3] = 1;

                // Get World-space cartesian coordinates of the ray-triangle intersection

                math.transformVec4(mesh.worldMatrix, tempVec4a, tempVec4b);

                worldPos[0] = tempVec4b[0];
                worldPos[1] = tempVec4b[1];
                worldPos[2] = tempVec4b[2];

                pickResult.worldPos = worldPos;

                // Get View-space cartesian coordinates of the ray-triangle intersection

                math.transformVec4(camera.matrix, tempVec4b, tempVec4c);

                viewPos[0] = tempVec4c[0];
                viewPos[1] = tempVec4c[1];
                viewPos[2] = tempVec4c[2];

                pickResult.viewPos = viewPos;

                // Get barycentric coordinates of the ray-triangle intersection

                math.cartesianToBarycentric(position, positionA, positionB, positionC, bary);

                pickResult.bary = bary;

                // Get interpolated normal vector

                const normals = geometry.normals;

                if (normals) {

                    if (geometry.compressGeometry) {

                        // Decompress vertex normals

                        const ia2 = ia * 3;
                        const ib2 = ib * 3;
                        const ic2 = ic * 3;

                        geometryCompressionUtils.decompressNormal(normals.subarray(ia2, ia2 + 2), normalA);
                        geometryCompressionUtils.decompressNormal(normals.subarray(ib2, ib2 + 2), normalB);
                        geometryCompressionUtils.decompressNormal(normals.subarray(ic2, ic2 + 2), normalC);

                    } else {

                        normalA[0] = normals[ia3];
                        normalA[1] = normals[ia3 + 1];
                        normalA[2] = normals[ia3 + 2];

                        normalB[0] = normals[ib3];
                        normalB[1] = normals[ib3 + 1];
                        normalB[2] = normals[ib3 + 2];

                        normalC[0] = normals[ic3];
                        normalC[1] = normals[ic3 + 1];
                        normalC[2] = normals[ic3 + 2];
                    }

                    const normal = math.addVec3(math.addVec3(
                        math.mulVec3Scalar(normalA, bary[0], tempVec3),
                        math.mulVec3Scalar(normalB, bary[1], tempVec3b), tempVec3c),
                        math.mulVec3Scalar(normalC, bary[2], tempVec3d), tempVec3e);

                    pickResult.worldNormal = math.normalizeVec3(math.transformVec3(mesh.worldNormalMatrix, normal, tempVec3f));
                }

                // Get interpolated UV coordinates

                const uvs = geometry.uv;

                if (uvs) {

                    uva[0] = uvs[(ia * 2)];
                    uva[1] = uvs[(ia * 2) + 1];

                    uvb[0] = uvs[(ib * 2)];
                    uvb[1] = uvs[(ib * 2) + 1];

                    uvc[0] = uvs[(ic * 2)];
                    uvc[1] = uvs[(ic * 2) + 1];

                    if (geometry.compressGeometry) {

                        // Decompress vertex UVs

                        const uvDecodeMatrix = geometry.uvDecodeMatrix;
                        if (uvDecodeMatrix) {
                            geometryCompressionUtils.decompressUV(uva, uvDecodeMatrix, uva);
                            geometryCompressionUtils.decompressUV(uvb, uvDecodeMatrix, uvb);
                            geometryCompressionUtils.decompressUV(uvc, uvDecodeMatrix, uvc);
                        }
                    }

                    pickResult.uv = math.addVec3(
                        math.addVec3(
                            math.mulVec2Scalar(uva, bary[0], tempVec3g),
                            math.mulVec2Scalar(uvb, bary[1], tempVec3h), tempVec3i),
                        math.mulVec2Scalar(uvc, bary[2], tempVec3j), tempVec3k);
                }
            }
        }
    }
})();

export {Mesh};