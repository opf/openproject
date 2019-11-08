import {utils} from '../utils.js';
import {Component} from '../Component.js';
import {math} from '../math/math.js';

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
 * @desc An {@link Entity} that is a scene graph node that can have child Nodes and {@link Mesh}es.
 *
 * ## Usage
 *
 * The example below is the same as the one given for {@link Mesh}, since the two classes work together. In this example,
 * we'll create a scene graph in which a root Node represents a group and the {@link Mesh}s are leaves. Since Node
 * implements {@link Entity}, we can designate the root Node as a model, causing it to be registered by its ID in {@link Scene#models}.
 *
 * Since {@link Mesh} also implements {@link Entity}, we can designate the leaf {@link Mesh}es as objects, causing them to
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
 * As mentioned, we can also associate {@link MetaModel}s and {@link MetaObject}s with our Nodes and {@link Mesh}es,
 * within a {@link MetaScene}. See {@link MetaScene} for an example.
 *
 * @implements {Entity}
 */
class Node extends Component {

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
     * @param {Boolean} [cfg.visible=true] Indicates if the Node is initially visible.
     * @param {Boolean} [cfg.culled=false] Indicates if the Node is initially culled from view.
     * @param {Boolean} [cfg.pickable=true] Indicates if the Node is initially pickable.
     * @param {Boolean} [cfg.clippable=true] Indicates if the Node is initially clippable.
     * @param {Boolean} [cfg.collidable=true] Indicates if the Node is initially included in boundary calculations.
     * @param {Boolean} [cfg.castsShadow=true] Indicates if the Node initially casts shadows.
     * @param {Boolean} [cfg.receivesShadow=true]  Indicates if the Node initially receives shadows.
     * @param {Boolean} [cfg.xrayed=false] Indicates if the Node is initially xrayed.
     * @param {Boolean} [cfg.highlighted=false] Indicates if the Node is initially highlighted.
     * @param {Boolean} [cfg.selected=false] Indicates if the Mesh is initially selected.
     * @param {Boolean} [cfg.edges=false] Indicates if the Node's edges are initially emphasized.
     * @param {Number[]} [cfg.colorize=[1.0,1.0,1.0]] Node's initial RGB colorize color, multiplies by the rendered fragment colors.
     * @param {Number} [cfg.opacity=1.0] Node's initial opacity factor, multiplies by the rendered fragment alpha.
     * @param {Array} [cfg.children] Child Nodes or {@link Mesh}es to add initially. Children must be in the same {@link Scene} and will be removed first from whatever parents they may already have.
     * @param {Boolean} [cfg.inheritStates=true] Indicates if children given to this constructor should inherit rendering state from this parent as they are added. Rendering state includes {@link Node#visible}, {@link Node#culled}, {@link Node#pickable}, {@link Node#clippable}, {@link Node#castsShadow}, {@link Node#receivesShadow}, {@link Node#selected}, {@link Node#highlighted}, {@link Node#colorize} and {@link Node#opacity}.
     */
    constructor(owner, cfg = {}) {

        super(owner, cfg);

        this._parentNode = null;
        this._children = [];

        this._aabb = null;
        this._aabbDirty = true;

        this.scene._aabbDirty = true;

        this._scale = math.vec3();
        this._quaternion = math.identityQuaternion();
        this._rotation = math.vec3();
        this._position = math.vec3();

        this._localMatrix = math.identityMat4();
        this._worldMatrix = math.identityMat4();

        this._localMatrixDirty = true;
        this._worldMatrixDirty = true;

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

        this._isModel = cfg.isModel;
        if (this._isModel) {
            this.scene._registerModel(this);
        }

        this._isObject = cfg.isObject;
        if (this._isObject) {
            this.scene._registerObject(this);
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
        this.colorize = cfg.colorize;
        this.opacity = cfg.opacity;

        // Add children, which inherit state from this Node

        if (cfg.children) {
            const children = cfg.children;
            for (let i = 0, len = children.length; i < len; i++) {
                this.addChild(children[i], cfg.inheritStates);
            }
        }

        if (cfg.parentId) {
            const parentNode = this.scene.components[cfg.parentId];
            if (!parentNode) {
                this.error("Parent not found: '" + cfg.parentId + "'");
            } else if (!parentNode.isNode) {
                this.error("Parent is not a Node: '" + cfg.parentId + "'");
            } else {
                parentNode.addChild(this);
            }
        } else if (cfg.parent) {
            if (!cfg.parent.isNode) {
                this.error("Parent is not a Node");
            }
            cfg.parent.addChild(this);
        }
    }

    //------------------------------------------------------------------------------------------------------------------
    // Entity members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that this Component is an Entity.
     * @type {Boolean}
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
     * Returns ````true```` if this Node represents an object.
     *
     * When ````true```` the Node will be registered by {@link Node#id} in
     * {@link Scene#objects} and may also have a {@link MetaObject} with matching {@link MetaObject#id}.
     *
     * @type {Boolean}
     * @abstract
     */
    get isObject() {
        return this._isObject;
    }

    /**
     * Gets the Node's World-space 3D axis-aligned bounding box.
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
     * Sets if this Node and all child Nodes and {@link Mesh}es are visible.
     *
     * Only rendered both {@link Node#visible} is ````true```` and {@link Node#culled} is ````false````.
     *
     * When {@link Node#isObject} and {@link Node#visible} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    set visible(visible) {
        visible = visible !== false;
        this._visible = visible;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].visible = visible;
        }
        if (this._isObject) {
            this.scene._objectVisibilityUpdated(this, visible);
        }
    }

    /**
     * Gets if this Node is visible.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * When {@link Node#isObject} and {@link Node#visible} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#visibleObjects}.
     *
     * @type {Boolean}
     */
    get visible() {
        return this._visible;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are xrayed.
     *
     * When {@link Node#isObject} and {@link Node#xrayed} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#xrayedObjects}.
     *
     * @type {Boolean}
     */
    set xrayed(xrayed) {
        xrayed = !!xrayed;
        this._xrayed = xrayed;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].xrayed = xrayed;
        }
        if (this._isObject) {
            this.scene._objectXRayedUpdated(this, xrayed);
        }
    }

    /**
     * Gets if this Node is xrayed.
     *
     * When {@link Node#isObject} and {@link Node#xrayed} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#xrayedObjects}.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get xrayed() {
        return this._xrayed;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are highlighted.
     *
     * When {@link Node#isObject} and {@link Node#highlighted} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#highlightedObjects}.
     *
     * @type {Boolean}
     */
    set highlighted(highlighted) {
        highlighted = !!highlighted;
        this._highlighted = highlighted;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].highlighted = highlighted;
        }
        if (this._isObject) {
            this.scene._objectHighlightedUpdated(this, highlighted);
        }
    }

    /**
     * Gets if this Node is highlighted.
     *
     * When {@link Node#isObject} and {@link Node#highlighted} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#highlightedObjects}.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get highlighted() {
        return this._highlighted;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are selected.
     *
     * When {@link Node#isObject} and {@link Node#selected} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#selectedObjects}.
     *
     * @type {Boolean}
     */
    set selected(selected) {
        selected = !!selected;
        this._selected = selected;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].selected = selected;
        }
        if (this._isObject) {
            this.scene._objectSelectedUpdated(this, selected);
        }
    }

    /**
     * Gets if this Node is selected.
     *
     * When {@link Node#isObject} and {@link Node#selected} are both ````true```` the Node will be
     * registered by {@link Node#id} in {@link Scene#selectedObjects}.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get selected() {
        return this._selected;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are edge-enhanced.
     *
     * @type {Boolean}
     */
    set edges(edges) {
        edges = !!edges;
        this._edges = edges;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].edges = edges;
        }
    }

    /**
     * Gets if this Node's edges are enhanced.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get edges() {
        return this._edges;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are culled.
     *
     * @type {Boolean}
     */
    set culled(culled) {
        culled = !!culled;
        this._culled = culled;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].culled = culled;
        }
    }

    /**
     * Gets if this Node is culled.
     *
     * @type {Boolean}
     */
    get culled() {
        return this._culled;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#clips}.
     *
     * @type {Boolean}
     */
    set clippable(clippable) {
        clippable = clippable !== false;
        this._clippable = clippable;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].clippable = clippable;
        }
    }

    /**
     * Gets if this Node is clippable.
     *
     * Clipping is done by the {@link SectionPlane}s in {@link Scene#clips}.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get clippable() {
        return this._clippable;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are included in boundary calculations.
     *
     * @type {Boolean}
     */
    set collidable(collidable) {
        collidable = collidable !== false;
        this._collidable = collidable;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].collidable = collidable;
        }
    }

    /**
     * Gets if this Node is included in boundary calculations.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get collidable() {
        return this._collidable;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es are pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * @type {Boolean}
     */
    set pickable(pickable) {
        pickable = pickable !== false;
        this._pickable = pickable;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].pickable = pickable;
        }
    }

    /**
     * Gets if to this Node is pickable.
     *
     * Picking is done via calls to {@link Scene#pick}.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get pickable() {
        return this._pickable;
    }

    /**
     * Sets the RGB colorize color for this Node and all child Nodes and {@link Mesh}es}.
     *
     * Multiplies by rendered fragment colors.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * @type {Number[]}
     */
    set colorize(rgb) {
        let colorize = this._colorize;
        if (!colorize) {
            colorize = this._colorize = new Float32Array(4);
            colorize[3] = 1.0;
        }
        if (rgb) {
            colorize[0] = rgb[0];
            colorize[1] = rgb[1];
            colorize[2] = rgb[2];
        } else {
            colorize[0] = 1;
            colorize[1] = 1;
            colorize[2] = 1;
        }
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].colorize = colorize;
        }
    }

    /**
     * Gets the RGB colorize color for this Node.
     *
     * Each element of the color is in range ````[0..1]````.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Number[]}
     */
    get colorize() {
        return this._colorize.slice(0, 3);
    }

    /**
     * Sets the opacity factor for this Node and all child Nodes and {@link Mesh}es.
     *
     * This is a factor in range ````[0..1]```` which multiplies by the rendered fragment alphas.
     *
     * @type {Number}
     */
    set opacity(opacity) {
        let colorize = this._colorize;
        if (!colorize) {
            colorize = this._colorize = new Float32Array(4);
            colorize[0] = 1;
            colorize[1] = 1;
            colorize[2] = 1;
        }
        colorize[3] = opacity !== null && opacity !== undefined ? opacity : 1.0;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].opacity = opacity;
        }
    }

    /**
     * Gets this Node's opacity factor.
     *
     * This is a factor in range ````[0..1]```` which multiplies by the rendered fragment alphas.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Number}
     */
    get opacity() {
        return this._colorize[3];
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es cast shadows.
     *
     * @type {Boolean}
     */
    set castsShadow(castsShadow) {
        castsShadow = !!castsShadow;
        this._castsShadow = castsShadow;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].castsShadow = castsShadow;
        }
    }

    /**
     * Gets if this Node casts shadows.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get castsShadow() {
        return this._castsShadow;
    }

    /**
     * Sets if this Node and all child Nodes and {@link Mesh}es can have shadows cast upon them.
     *
     * @type {Boolean}
     */
    set receivesShadow(receivesShadow) {
        receivesShadow = !!receivesShadow;
        this._receivesShadow = receivesShadow;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i].receivesShadow = receivesShadow;
        }
    }

    /**
     * Whether or not to this Node can have shadows cast upon it.
     *
     * Child Nodes and {@link Mesh}es may have different values for this property.
     *
     * @type {Boolean}
     */
    get receivesShadow() {
        return this._receivesShadow;
    }

    //------------------------------------------------------------------------------------------------------------------
    // Node members
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns true to indicate that this Component is a Node.
     * @type {Boolean}
     */
    get isNode() {
        return true;
    }

    _setLocalMatrixDirty() {
        this._localMatrixDirty = true;
        this._setWorldMatrixDirty();
    }

    _setWorldMatrixDirty() {
        this._worldMatrixDirty = true;
        for (let i = 0, len = this._children.length; i < len; i++) {
            this._children[i]._setWorldMatrixDirty();
        }
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

    _setSubtreeAABBsDirty(node) {
        node._aabbDirty = true;
        if (node._children) {
            for (let i = 0, len = node._children.length; i < len; i++) {
                this._setSubtreeAABBsDirty(node._children[i]);
            }
        }
    }

    _setAABBDirty() {
        this._setSubtreeAABBsDirty(this);
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
        if (this._buildAABB) {
            this._buildAABB(this.worldMatrix, this._aabb); // Mesh or PerformanceModel
        } else { // Node | Node | Model
            math.collapseAABB3(this._aabb);
            let node;
            for (let i = 0, len = this._children.length; i < len; i++) {
                node = this._children[i];
                if (!node.collidable) {
                    continue;
                }
                math.expandAABB3(this._aabb, node.aabb);
            }
        }
        this._aabbDirty = false;
    }

    /**
     * Adds a child Node or {@link Mesh}.
     *
     * The child must be a Node or {@link Mesh} in the same {@link Scene}.
     *
     * If the child already has a parent, will be removed from that parent first.
     *
     * Does nothing if already a child.
     *
     * @param {Node|Mesh|String} child Instance or ID of the child to add.
     * @param [inheritStates=false] Indicates if the child should inherit rendering states from this parent as it is added. Rendering state includes {@link Node#visible}, {@link Node#culled}, {@link Node#pickable}, {@link Node#clippable}, {@link Node#castsShadow}, {@link Node#receivesShadow}, {@link Node#selected}, {@link Node#highlighted}, {@link Node#colorize} and {@link Node#opacity}.
     * @returns {Node|Mesh} The child.
     */
    addChild(child, inheritStates) {
        if (utils.isNumeric(child) || utils.isString(child)) {
            const nodeId = child;
            child = this.scene.component[nodeId];
            if (!child) {
                this.warn("Component not found: " + utils.inQuotes(nodeId));
                return;
            }
            if (!child.isNode && !child.isMesh) {
                this.error("Not a Node or Mesh: " + nodeId);
                return;
            }
        } else {
            if (!child.isNode && !child.isMesh) {
                this.error("Not a Node or Mesh: " + child.id);
                return;
            }
            if (child._parentNode) {
                if (child._parentNode.id === this.id) {
                    this.warn("Already a child: " + child.id);
                    return;
                }
                child._parentNode.removeChild(child);
            }
        }
        const id = child.id;
        if (child.scene.id !== this.scene.id) {
            this.error("Child not in same Scene: " + child.id);
            return;
        }
        this._children.push(child);
        child._parentNode = this;
        if (!!inheritStates) {
            child.visible = this.visible;
            child.culled = this.culled;
            child.xrayed = this.xrayed;
            child.highlited = this.highlighted;
            child.selected = this.selected;
            child.edges = this.edges;
            child.clippable = this.clippable;
            child.pickable = this.pickable;
            child.collidable = this.collidable;
            child.castsShadow = this.castsShadow;
            child.receivesShadow = this.receivesShadow;
            child.colorize = this.colorize;
            child.opacity = this.opacity;
        }
        child._setWorldMatrixDirty();
        child._setAABBDirty();
        return child;
    }

    /**
     * Removes the given child Node or {@link Mesh}.
     *
     * @param {Node|Mesh} child Child to remove.
     */
    removeChild(child) {
        for (let i = 0, len = this._children.length; i < len; i++) {
            if (this._children[i].id === child.id) {
                child._parentNode = null;
                this._children = this._children.splice(i, 1);
                child._setWorldMatrixDirty();
                child._setAABBDirty();
                this._setAABBDirty();
                return;
            }
        }
    }

    /**
     * Removes all child Nodes and {@link Mesh}es.
     */
    removeChildren() {
        let child;
        for (let i = 0, len = this._children.length; i < len; i++) {
            child = this._children[i];
            child._parentNode = null;
            child._setWorldMatrixDirty();
            child._setAABBDirty();
        }
        this._children = [];
        this._setAABBDirty();
    }

    /**
     * Number of child Nodes or {@link Mesh}es.
     *
     * @type {Number}
     */
    get numChildren() {
        return this._children.length;
    }

    /**
     * Array of child Nodes or {@link Mesh}es.
     *
     * @type {Array}
     */
    get children() {
        return this._children;
    }

    /**
     * The parent Node.
     *
     * The parent Node may also be set by passing the Node to the parent's {@link Node#addChild} method.
     *
     * @type {Node}
     */
    set parent(node) {
        if (utils.isNumeric(node) || utils.isString(node)) {
            const nodeId = node;
            node = this.scene.components[nodeId];
            if (!node) {
                this.warn("Node not found: " + utils.inQuotes(nodeId));
                return;
            }
            if (!node.isNode) {
                this.error("Not a Node: " + node.id);
                return;
            }
        }
        if (node.scene.id !== this.scene.id) {
            this.error("Node not in same Scene: " + node.id);
            return;
        }
        if (this._parentNode && this._parentNode.id === node.id) {
            this.warn("Already a child of Node: " + node.id);
            return;
        }
        node.addChild(this);
    }

    /**
     * The parent Node.
     *
     * @type {Node}
     */
    get parent() {
        return this._parentNode;
    }

    /**
     * Sets the Node's local translation.
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
     * Gets the Node's local translation.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    get position() {
        return this._position;
    }

    /**
     * Sets the Node's local rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
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
     * Gets the Node's local rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     *
     * Default value is ````[0,0,0]````.
     *
     * @type {Number[]}
     */
    get rotation() {
        return this._rotation;
    }

    /**
     * Sets the Node's local rotation quaternion.
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
     * Gets the Node's local rotation quaternion.
     *
     * Default value is ````[0,0,0,1]````.
     *
     * @type {Number[]}
     */
    get quaternion() {
        return this._quaternion;
    }

    /**
     * Sets the Node's local scale.
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
     * Gets the Node's local scale.
     *
     * Default value is ````[1,1,1]````.
     *
     * @type {Number[]}
     */
    get scale() {
        return this._scale;
    }

    /**
     * Sets the Node's local modeling transform matrix.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @type {Number[]}
     */
    set matrix(value) {
        if (!this._localMatrix) {
            this._localMatrix = math.identityMat4();
        }
        this._localMatrix.set(value || identityMat);
        math.decomposeMat4(this._localMatrix, this._position, this._quaternion, this._scale);
        this._localMatrixDirty = false;
        this._setWorldMatrixDirty();
        this._setAABBDirty();
        this.glRedraw();
    }

    /**
     * Gets the Node's local modeling transform matrix.
     *
     * Default value is ````[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]````.
     *
     * @type {Number[]}
     */
    get matrix() {
        if (this._localMatrixDirty) {
            if (!this._localMatrix) {
                this._localMatrix = math.identityMat4();
            }
            math.composeMat4(this._position, this._quaternion, this._scale, this._localMatrix);
            this._localMatrixDirty = false;
        }
        return this._localMatrix;
    }

    /**
     * Gets the Node's World matrix.
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
     * Rotates the Node about the given local axis by the given increment.
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
     * Rotates the Node about the given World-space axis by the given increment.
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
     * Rotates the Node about the local X-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateX(angle) {
        return this.rotate(xAxis, angle);
    }

    /**
     * Rotates the Node about the local Y-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateY(angle) {
        return this.rotate(yAxis, angle);
    }

    /**
     * Rotates the Node about the local Z-axis by the given increment.
     *
     * @param {Number} angle Angle increment in degrees.
     */
    rotateZ(angle) {
        return this.rotate(zAxis, angle);
    }

    /**
     * Translates the Node along local space vector by the given increment.
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
     * Translates the Node along the local X-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the X-axis.
     */
    translateX(distance) {
        return this.translate(xAxis, distance);
    }

    /**
     * Translates the Node along the local Y-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the Y-axis.
     */
    translateY(distance) {
        return this.translate(yAxis, distance);
    }

    /**
     * Translates the Node along the local Z-axis by the given increment.
     *
     * @param {Number} distance Distance to translate along  the Z-axis.
     */
    translateZ(distance) {
        return this.translate(zAxis, distance);
    }

    //------------------------------------------------------------------------------------------------------------------
    // Component members
    //------------------------------------------------------------------------------------------------------------------

    /**
     @private
     */
    get type() {
        return "Node";
    }

    /**
     * Destroys this Node.
     */
    destroy() {
        super.destroy();
        if (this._parentNode) {
            this._parentNode.removeChild(this);
        }
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
        if (this._children.length) {
            // Clone the _children before iterating, so our children don't mess us up when calling removeChild().
            const tempChildList = this._children.splice();
            let child;
            for (let i = 0, len = tempChildList.length; i < len; i++) {
                child = tempChildList[i];
                child.destroy();
            }
        }
        this._children = [];
        this._setAABBDirty();
        this.scene._aabbDirty = true;
    }

}

export {Node};
