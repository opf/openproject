import {math} from '../math/math.js';
import {Component} from '../Component.js';
import {PerformanceNode} from "../PerformanceModel/lib/PerformanceNode.js";

const tempVec4a = math.vec4();
const tempVec4b = math.vec4();


/**
 * @desc Tracks the World, View and Canvas coordinates, and visibility, of a position within a {@link Scene}.
 *
 * ## Position
 *
 * A Marker holds its position in the World, View and Canvas coordinate systems in three properties:
 *
 * * {@link Marker#worldPos} holds the Marker's 3D World-space coordinates. This property can be dynamically updated. The Marker will fire a "worldPos" event whenever this property changes.
 * * {@link Marker#viewPos} holds the Marker's 3D View-space coordinates. This property is read-only, and is automatically updated from {@link Marker#worldPos} and the current {@link Camera} position. The Marker will fire a "viewPos" event whenever this property changes.
 * * {@link Marker#canvasPos} holds the Marker's 2D Canvas-space coordinates. This property is read-only, and is automatically updated from {@link Marker#canvasPos} and the current {@link Camera} position and projection. The Marker will fire a "canvasPos" event whenever this property changes.
 *
 * ## Visibility
 *
 * {@link Marker#visible} indicates if the Marker is currently visible. The Marker will fire a "visible" event whenever {@link Marker#visible} changes.
 *
 * This property will be ````false```` when:
 *
 * * {@link Marker#entity} is set to an {@link Entity}, and {@link Entity#visible} is ````false````,
 * * {@link Marker#occludable} is ````true```` and the Marker is occluded by some {@link Entity} in the 3D view, or
 * * {@link Marker#canvasPos} is outside the boundary of the {@link Canvas}.
 *
 * ## Usage
 *
 * In the example below, we'll create a Marker that's associated with a {@link Mesh} (which a type of {@link Entity}).
 *
 * We'll configure our Marker to
 * become invisible whenever it's occluded by any Entities in the canvas.
 *
 * We'll also demonstrate how to query the Marker's visibility status and position (in the World, View and
 * Canvas coordinate systems), and how to subscribe to change events on those properties.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#Markers_SimpleExample)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 * import {Marker} from "../src/scene/markers/Marker.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * // Create the torus Mesh
 * // Recall that a Mesh is an Entity
 * new Mesh(viewer.scene, {
 *     geometry: new ReadableGeometry(viewer.scene, buildTorusGeometry({
 *         center: [0,0,0],
 *         radius: 1.0,
 *         tube: 0.5,
 *         radialSegments: 32,
 *         tubeSegments: 24,
 *         arc: Math.PI * 2.0
 *     }),
 *     material: new PhongMaterial(viewer.scene, {
 *         diffuseMap: new Texture(viewer.scene, {
 *             src: "textures/diffuse/uvGrid2.jpg"
 *         }),
 *         backfaces: true
 *     })
 * });
 *
 * // Create the Marker, associated with our Mesh Entity
 * const myMarker = new Marker({
 *      entity: entity,
 *      worldPos: [10,0,0],
 *      occludable: true
 * });
 *
 * // Get the Marker's current World, View and Canvas coordinates
 * const worldPos   = myMarker.worldPos;     // 3D World-space position
 * const viewPos    = myMarker.viewPos;      // 3D View-space position
 * const canvasPos  = myMarker.canvasPos;    // 2D Canvas-space position
 *
 * const visible = myMarker.visible;
 *
 * // Listen for change of the Marker's 3D World-space position
 * myMarker.on("worldPos", function(worldPos) {
 *    //...
 * });
 *
 * // Listen for change of the Marker's 3D View-space position, which happens
 * // when either worldPos was updated or the Camera was moved
 * myMarker.on("viewPos", function(viewPos) {
 *    //...
 * });
 *
 * // Listen for change of the Marker's 2D Canvas-space position, which happens
 * // when worldPos or viewPos was updated, or Camera's projection was updated
 * myMarker.on("canvasPos", function(canvasPos) {
 *    //...
 * });
 *
 * // Listen for change of Marker visibility. The Marker becomes invisible when it falls outside the canvas,
 * // has an Entity that is also invisible, or when an Entity occludes the Marker's position in the 3D view.
 * myMarker.on("visible", function(visible) { // Marker visibility has changed
 *    if (visible) {
 *        this.log("Marker is visible");
 *    } else {
 *        this.log("Marker is invisible");
 *    }
 * });
 *
 * // Listen for destruction of Marker
 * myMarker.on("destroyed", () => {
 *      //...
 * });
 * ````
 */
class Marker extends Component {

    /**
     * @constructor
     * @param {Component} [owner]  Owner component. When destroyed, the owner will destroy this Marker as well.
     * @param {*} [cfg]  Marker configuration
     * @param {String} [cfg.id] Optional ID, unique among all components in the parent {@link Scene}, generated automatically when omitted.
     * @param {Entity} [cfg.entity] Entity to associate this Marker with. When the Marker has an Entity, then {@link Marker#visible} will always be ````false```` if {@link Entity#visible} is false.
     * @param {Boolean} [cfg.occludable=false] Indicates whether or not this Marker is hidden (ie. {@link Marker#visible} is ````false```` whenever occluded by {@link Entity}s in the {@link Scene}.
     * @param {Number[]} [cfg.worldPos=[0,0,0]] World-space 3D Marker position.
     */
    constructor(owner, cfg) {

        super(owner, cfg);

        this._entity = null;
        this._visible = null;
        this._worldPos = new Float32Array(3);
        this._viewPos = new Float32Array(3);
        this._canvasPos = new Float32Array(2);
        this._occludable = false;

        this._onCameraViewMatrix = this.scene.camera.on("matrix", () => {
            this._viewPosDirty = true;
            this._needUpdate();
        });

        this._onCameraProjMatrix = this.scene.camera.on("projMatrix", () => {
            this._canvasPosDirty = true;
            this._needUpdate();
        });

        this._onEntityDestroyed = null;
        this._onEntityModelDestroyed = null;

        this._renderer.addMarker(this);

        this.entity = cfg.entity;
        this.worldPos = cfg.worldPos;
        this.occludable = cfg.occludable;
    }

    _update() { // this._needUpdate() schedules this for next tick
        if (this._viewPosDirty) {
            math.transformPoint3(this.scene.camera.viewMatrix, this._worldPos, this._viewPos);
            this._viewPosDirty = false;
            this._canvasPosDirty = true;
            this.fire("viewPos", this._viewPos);
        }
        if (this._canvasPosDirty) {
            tempVec4a.set(this._viewPos);
            tempVec4a[3] = 1.0;
            math.transformPoint4(this.scene.camera.projMatrix, tempVec4a, tempVec4b);
            const aabb = this.scene.canvas.boundary;
            this._canvasPos[0] = Math.floor((1 + tempVec4b[0] / tempVec4b[3]) * aabb[2] / 2);
            this._canvasPos[1] = Math.floor((1 - tempVec4b[1] / tempVec4b[3]) * aabb[3] / 2);
            this._canvasPosDirty = false;
            this.fire("canvasPos", this._canvasPos);
        }
    }

    _setVisible(visible) { // Called by VisibilityTester and this._entity.on("destroyed"..)
        if (this._visible === visible) {
            //  return;
        }
        this._visible = visible;
        this.fire("visible", this._visible);
    }

    /**
     * Sets the {@link Entity} this Marker is associated with.
     *
     * An Entity is optional. When the Marker has an Entity, then {@link Marker#visible} will always be ````false````
     * if {@link Entity#visible} is false.
     *
     * @type {Entity}
     */
    set entity(entity) {
        if (this._entity) {
            if (this._entity === entity) {
                return;
            }
            if (this._onEntityDestroyed !== null) {
                this._entity.off(this._onEntityDestroyed);
                this._onEntityDestroyed = null;
            }
            if (this._onEntityModelDestroyed !== null) {
                this._entity.model.off(this._onEntityModelDestroyed);
                this._onEntityModelDestroyed = null;
            }
        }
        this._entity = entity;
        if (this._entity) {
            if (this._entity instanceof PerformanceNode) {
                this._onEntityModelDestroyed = this._entity.model.once("destroyed", () => { // PerformanceNode does not fire events, and cannot exist beyond its PerformanceModel
                    this._entity = null; // Marker now may become visible, if it was synched to invisible Entity
                    this._onEntityModelDestroyed = null;
                });
            } else {
                this._onEntityDestroyed = this._entity.once("destroyed", () => {
                    this._entity = null;
                    this._onEntityDestroyed = null;
                });
            }
        }
        this.fire("entity", this._entity, true /* forget */);
    }

    /**
     * Gets the {@link Entity} this Marker is associated with.
     *
     * @type {Entity}
     */
    get entity() {
        return this._entity;
    }

    /**
     * Sets whether occlusion testing is performed for this Marker.
     *
     * When this is ````true````, then {@link Marker#visible} will be ````false```` whenever the Marker is occluded by an {@link Entity} in the 3D view.
     *
     * The {@link Scene} periodically occlusion-tests all Markers on every 20th "tick" (which represents a rendered frame). We
     * can adjust that frequency via property {@link Scene#ticksPerOcclusionTest}.
     *
     * @type {Boolean}
     */
    set occludable(occludable) {
        occludable = !!occludable;
        if (occludable === this._occludable) {
            return;
        }
        this._occludable = occludable;
    }

    /**
     * Gets whether occlusion testing is performed for this Marker.
     *
     * When this is ````true````, then {@link Marker#visible} will be ````false```` whenever the Marker is occluded by an {@link Entity} in the 3D view.
     *
     * @type {Boolean}
     */
    get occludable() {
        return this._occludable;
    }

    /**
     * Sets the World-space 3D position of this Marker.
     *
     * Fires a "worldPos" event with new World position.
     *
     * @type {Number[]}
     */
    set worldPos(worldPos) {
        this._worldPos.set(worldPos || [0, 0, 0]);
        if (this._occludable) {
            this._renderer.markerWorldPosUpdated(this);
        }
        this._viewPosDirty = true;
        this.fire("worldPos", this._worldPos);
    }

    /**
     * Gets the World-space 3D position of this Marker.
     *
     * @type {Number[]}
     */
    get worldPos() {
        return this._worldPos;
    }

    /**
     * View-space 3D coordinates of this Marker.
     *
     * This property is read-only and is automatically calculated from {@link Marker#worldPos} and the current {@link Camera} position.
     *
     * The Marker fires a "viewPos" event whenever this property changes.
     *
     * @type {Number[]}
     * @final
     */
    get viewPos() {
        this._update();
        return this._viewPos;
    }

    /**
     * Canvas-space 2D coordinates of this Marker.
     *
     * This property is read-only and is automatically calculated from {@link Marker#worldPos} and the current {@link Camera} position and projection.
     *
     * The Marker fires a "canvasPos" event whenever this property changes.
     *
     * @type {Number[]}
     * @final
     */
    get canvasPos() {
        this._update();
        return this._canvasPos;
    }

    /**
     * Indicates if this Marker is currently visible.
     *
     * This is read-only and is automatically calculated.
     *
     * The Marker is **invisible** whenever:
     *
     * * {@link Marker#canvasPos} is currently outside the canvas,
     * * {@link Marker#entity} is set to an {@link Entity} that has {@link Entity#visible} ````false````, or
     * * or {@link Marker#occludable} is ````true```` and the Marker is currently occluded by an Entity in the 3D view.
     *
     * The Marker fires a "visible" event whenever this property changes.
     *
     * @type {Boolean}
     * @final
     */
    get visible() {
        return !!this._visible;
    }

    /**
     * Destroys this Marker.
     */
    destroy() {
        this.fire("destroyed", true);
        this.scene.camera.off(this._onCameraViewMatrix);
        this.scene.camera.off(this._onCameraProjMatrix);
        if (this._entity) {
            if (this._onEntityDestroyed !== null) {
                this._entity.off(this._onEntityDestroyed);
            }
            if (this._onEntityModelDestroyed !== null) {
                this._entity.model.off(this._onEntityModelDestroyed);
            }
        }
        this._renderer.removeMarker(this);
        super.destroy();
    }
}

export {Marker};
