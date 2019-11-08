import {Plugin} from "../../viewer/Plugin.js";
import {Storey} from "./Storey.js";
import {IFCStoreyPlanObjectStates} from "./IFCStoreyPlanObjectStates.js";
import {math} from "../../viewer/scene/math/math.js";
import {ObjectsMemento} from "../../viewer/scene/mementos/ObjectsMemento.js";
import {CameraMemento} from "../../viewer/scene/mementos/CameraMemento.js";
import {StoreyMap} from "./StoreyMap.js";
import {utils} from "../../viewer/scene/utils.js";

const tempVec3a = math.vec3();
const tempMat4 = math.mat4();

const EMPTY_IMAGE = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";



/**
 * @desc A {@link Viewer} plugin that provides methods for visualizing IfcBuildingStoreys.
 *
 *  <a href="https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_recipe2"><img src="http://xeokit.io/img/docs/StoreyViewsPlugin/minimap.gif"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_recipe2)]
 *
 * ## Overview
 *
 * StoreyViewsPlugin provides a flexible set of methods for visualizing building storeys in 3D and 2D.
 *
 * Use the first two methods to set up 3D views of storeys:
 *
 * * [showStoreyObjects](#instance-method-showStoreyObjects) - shows the {@link Entity}s within a storey, and
 * * [gotoStoreyCamera](#instance-method-gotoStoreyCamera) - positions the {@link Camera} for a plan view of the Entitys within a storey.
 * <br> <br>
 *
 * Use the second two methods to create 2D plan view mini-map images:
 *
 * * [createStoreyMap](#instance-method-createStoreyMap) - creates a 2D plan view image of a storey, and
 * * [pickStoreyMap](#instance-method-pickStoreyMap) - picks the {@link Entity} at the given 2D pixel coordinates within a plan view image.
 *
 * ## Usage
 *
 * Let's start by creating a {@link Viewer} with a StoreyViewsPlugin and an {@link XKTLoaderPlugin}.
 *
 * Then we'll load a BIM building model from an  ```.xkt``` file.
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/viewer/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 * import {StoreyViewsPlugin} from "../src/viewer/plugins/StoreyViewsPlugin/StoreyViewsPlugin.js";
 *
 * // Create a Viewer, arrange the camera
 *
 * const viewer = new Viewer({
 *        canvasId: "myCanvas",
 *        transparent: true
 *    });
 *
 * viewer.camera.eye = [-2.56, 8.38, 8.27];
 * viewer.camera.look = [13.44, 3.31, -14.83];
 * viewer.camera.up = [0.10, 0.98, -0.14];
 *
 * // Add an XKTLoaderPlugin
 *
 * const xktLoader = new XKTLoaderPlugin(viewer);
 *
 * // Add a StoreyViewsPlugin
 *
 * const storeyViewsPlugin = new StoreyViewsPlugin(viewer);
 *
 * // Load a BIM model from .xkt format
 *
 * const model = xktLoader.load({
 *      id: "myModel",
 *      src: "./models/xkt/schependomlaan/schependomlaan.xkt",
 *      metaModelSrc: "./metaModels/schependomlaan/metaModel.json",
 *      edges: true
 * });
 * ````
 *
 * ## Finding Storeys
 *
 * Getting information on a storey in our model:
 *
 * ````javascript
 * const storey = storeyViewsPlugin.storeys["2SWZMQPyD9pfT9q87pgXa1"]; // ID of the IfcBuildingStorey
 *
 * const modelId  = storey.modelId;  // "myModel"
 * const storeyId = storey.storeyId; // "2SWZMQPyD9pfT9q87pgXa1"
 * const aabb     = storey.aabb;     // Axis-aligned 3D World-space boundary of the IfcBuildingStorey
 * ````
 *
 * We can also get a "storeys" event every time the set of storeys changes, ie. every time a storey is created or destroyed:
 *
 * ````javascript
 * storeyViewsPlugin.on("storeys", ()=> {
 *      const storey = storeyViewsPlugin.storeys["2SWZMQPyD9pfT9q87pgXa1"];
 *      //...
 * });
 * ````
 *
 * ## Showing Entitys within Storeys
 *
 * Showing the {@link Entity}s within a storey:
 *
 * ````javascript
 * storeyViewsPlugin.showStoreyObjects("2SWZMQPyD9pfT9q87pgXa1");
 * ````
 *
 * Showing **only** the Entitys in a storey, hiding all others:
 *
 * ````javascript
 * storeyViewsPlugin.showStoreyObjects("2SWZMQPyD9pfT9q87pgXa1", {
 *     hideOthers: true
 * });
 * ````
 * Showing only the storey Entitys, applying custom appearances configured on {@link StoreyViewsPlugin#objectStates}:
 *
 * ````javascript
 * storeyViewsPlugin.showStoreyObjects("2SWZMQPyD9pfT9q87pgXa1", {
 *     hideOthers: true,
 *     useObjectStates: true
 * });
 * ````
 *
 * <a href="https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_showStoreyObjects"><img src="http://xeokit.io/img/docs/StoreyViewsPlugin/showStoreyObjects.gif"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_showStoreyObjects)]
 *
 * When using this option, at some point later you'll probably want to restore all Entitys to their original visibilities and
 * appearances.
 *
 * To do that, save their visibility and appearance states in an {@link ObjectsMemento} beforehand, from
 * which you can restore them later:
 *
 * ````javascript
 * const objectsMemento = new ObjectsMemento();
 *
 * // Save all Entity visibility and appearance states
 *
 * objectsMemento.saveObjects(viewer.scene);
 *
 * // Show storey view Entitys, with custom appearances as configured for IFC types
 *
 * storeyViewsPlugin.showStoreyObjects("2SWZMQPyD9pfT9q87pgXa1", {
 *     useObjectStates: true // <<--------- Apply custom appearances
 * });
 *
 * //...
 *
 * // Later, restore all Entitys to their saved visibility and appearance states
 * objectsMemento.restoreObjects(viewer.scene);
 * ````
 *
 * ## Arranging the Camera for Storey Plan Views
 *
 * The {@link StoreyViewsPlugin#gotoStoreyCamera} method positions the {@link Camera} for a plan view of
 * the {@link Entity}s within the given storey.
 *
 * <a href="https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_gotoStoreyCamera"><img src="http://xeokit.io/img/docs/StoreyViewsPlugin/gotoStoreyCamera.gif"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_gotoStoreyCamera)]
 *
 * Let's fly the {@link Camera} to a downward-looking orthographic view of the Entitys within our storey.
 *
 * ````javascript
 * storeyViewsPlugin.gotoStoreyCamera("2SWZMQPyD9pfT9q87pgXa1", {
 *     projection: "ortho", // Orthographic projection
 *     duration: 2.5,       // 2.5 second transition
 *     done: () => {
 *         viewer.cameraControl.planView = true; // Disable rotation
 *     }
 * });
 * ````
 *
 * Note that we also set {@link CameraControl#planView} ````true````, which prevents the CameraControl from rotating
 * or orbiting. In orthographic mode, this effectively makes the {@link Viewer} behave as if it were a 2D viewer, with
 * picking, panning and zooming still enabled.
 *
 * If you need to be able to restore the Camera to its previous state, you can save it to a {@link CameraMemento}
 * beforehand, from which you can restore it later:
 *
 * ````javascript
 * const cameraMemento = new CameraMemento();
 *
 * // Save camera state
 *
 * cameraMemento.saveCamera(viewer.scene);
 *
 * // Position camera for a downward-looking orthographic view of our storey
 *
 * storeyViewsPlugin.gotoStoreyCamera("2SWZMQPyD9pfT9q87pgXa1", {
 *     projection: "ortho",
 *     duration: 2.5,
 *     done: () => {
 *         viewer.cameraControl.planView = true; // Disable rotation
 *     }
 * });
 *
 * //...
 *
 * // Later, restore the Camera to its saved state
 * cameraMemento.restoreCamera(viewer.scene);
 * ````
 *
 * ## Creating StoreyMaps
 *
 * The {@link StoreyViewsPlugin#createStoreyMap} method creates a 2D orthographic plan image of the given storey.
 *
 * <a href="https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_createStoreyMap"><img src="http://xeokit.io/img/docs/StoreyViewsPlugin/createStoreyMap.png"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_createStoreyMap)]
 *
 * This method creates a {@link StoreyMap}, which provides the plan image as a Base64-encoded string.
 *
 * Let's create a 2D plan image of our building storey:
 *
 * ````javascript
 * const storeyMap = storeyViewsPlugin.createStoreyMap("2SWZMQPyD9pfT9q87pgXa1", {
 *     width: 300,
 *     format: "png"
 * });
 *
 * const imageData = storeyMap.imageData; // Base64-encoded image data string
 * const width     = storeyMap.width; // 300
 * const height    = storeyMap.height; // Automatically derived from width
 * const format    = storeyMap.format; // "png"
 * ````
 *
 * As with ````showStoreyEntitys````,  We also have the option to customize the appearance of the Entitys in our plan
 * images according to their IFC types, using the lookup table configured on {@link StoreyViewsPlugin#objectStates}.
 *
 * For example, we usually want to show only element types like ````IfcWall````,  ````IfcDoor```` and
 * ````IfcFloor```` in our plan images.
 *
 * Let's create another StoreyMap, this time applying the custom appearances:
 *
 * ````javascript
 * const storeyMap = storeyViewsPlugin.createStoreyMap("2SWZMQPyD9pfT9q87pgXa1", {
 *     width: 300,
 *     format: "png",
 *     useObjectStates: true // <<--------- Apply custom appearances
 * });
 *````
 *
 * ## Picking Entities in StoreyMaps
 *
 * We can use {@link StoreyViewsPlugin#pickStoreyMap} to pick Entities in our building storey, using 2D coordinates from mouse or touch events on our {@link StoreyMap}'s 2D plan image.
 *
 * <a href="https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_recipe2"><img src="http://xeokit.io/img/docs/StoreyViewsPlugin/recipe2.gif"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#storeyViews_StoreyViewsPlugin_recipe2)]
 *
 * Let's programmatically pick the Entity at the given 2D pixel coordinates within our image:
 *
 * ````javascript
 * const mouseCoords = [65, 120]; // Mouse coords within the image extents
 *
 * const pickResult = storeyViewsPlugin.pickStoreyMap(storeyMap, mouseCoords);
 *
 * if (pickResult && pickResult.entity) {
 *     pickResult.entity.highlighted = true;
 * }
 * ````
 */
class StoreyViewsPlugin extends Plugin {

    /**
     * @constructor
     *
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="StoreyViews"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Object} [cfg.objectStates] Map of visual states for the {@link Entity}s as rendered within each {@link Storey}.  Default value is {@link IFCStoreyPlanObjectStates}.
     */
    constructor(viewer, cfg = {}) {

        super("StoreyViews", viewer);

        this._objectsMemento = new ObjectsMemento();
        this._cameraMemento = new CameraMemento();

        /**
         * A {@link Storey} for each ````IfcBuildingStorey```.
         *
         * There will be a {@link Storey} for every existing {@link MetaObject} whose {@link MetaObject#type} equals "IfcBuildingStorey".
         *
         * These are created and destroyed automatically as models are loaded and destroyed.
         *
         * @type {{String:Storey}}
         */
        this.storeys = {};

        /**
         * A set of {@link Storey}s for each {@link MetaModel}.
         *
         * These are created and destroyed automatically as models are loaded and destroyed.
         *
         * @type {{String: {String:Storey}}}
         */
        this.modelStoreys = {};

        this.objectStates = cfg.objectStates;

        this._onModelLoaded = this.viewer.scene.on("modelLoaded", (modelId) => {
            this._registerModelStoreys(modelId);
            this.fire("storeys", this.storeys);
        });
    }

    _registerModelStoreys(modelId) {
        const viewer = this.viewer;
        const scene = viewer.scene;
        const metaScene = viewer.metaScene;
        const metaModel = metaScene.metaModels[modelId];
        const model = scene.models[modelId];
        if (!metaModel || !metaModel.rootMetaObject) {
            return;
        }
        const storeyIds = metaModel.rootMetaObject.getObjectIDsInSubtreeByType(["IfcBuildingStorey"]);
        for (let i = 0, len = storeyIds.length; i < len; i++) {
            const storeyId = storeyIds[i];
            const metaObject = metaScene.metaObjects[storeyId];
            const childObjectIds = metaObject.getObjectIDsInSubtree();
            const aabb = scene.getAABB(childObjectIds);
            const storey = new Storey(this, aabb, modelId, storeyId);
            storey._onModelDestroyed = model.once("destroyed", () => {
                this._deregisterModelStoreys(modelId);
                this.fire("storeys", this.storeys);
            });
            this.storeys[storeyId] = storey;
            if (!this.modelStoreys[modelId]) {
                this.modelStoreys[modelId] = {};
            }
            this.modelStoreys[modelId][storeyId] = storey;
        }
    }

    _deregisterModelStoreys(modelId) {
        const storeys = this.modelStoreys[modelId];
        if (storeys) {
            const scene = this.viewer.scene;
            for (let storyObjectId in storeys) {
                if (storeys.hasOwnProperty(storyObjectId)) {
                    const storey = storeys[storyObjectId];
                    const model = scene.models[storey.modelId];
                    if (model) {
                        model.off("destroyed", storey._onModelDestroyed);
                    }
                    delete this.storeys[storyObjectId];
                }
            }
            delete this.modelStoreys[modelId];
        }
    }

    /**
     * Sets map of visual states for the {@link Entity}s as rendered within each {@link Storey}.
     *
     * Default value is {@link IFCStoreyPlanObjectStates}.
     *
     * @type {{String: Object}}
     */
    set objectStates(value) {
        this._objectStates = value || IFCStoreyPlanObjectStates;
    }

    /**
     * Gets map of visual states for the {@link Entity}s as rendered within each {@link Storey}.
     *
     * Default value is {@link IFCStoreyPlanObjectStates}.
     *
     * @type {{String: Object}}
     */
    get objectStates() {
        return this._objectStates;
    }

    /**
     * Arranges the {@link Camera} for a 3D orthographic view of the {@link Entity}s within the given storey.
     *
     * See also: {@link CameraMemento}, which saves and restores the state of the {@link Scene}'s {@link Camera}
     *
     * @param {String} storeyId ID of the ````IfcBuildingStorey```` object.
     * @param {*} [options] Options for arranging the Camera.
     * @param {String} [options.projection] Projection type to transition the Camera to. Accepted values are "perspective" and "ortho".
     * @param {Function} [options.done] Callback to fire when the Camera has arrived. When provided, causes an animated flight to the saved state. Otherwise jumps to the saved state.
     */
    gotoStoreyCamera(storeyId, options = {}) {

        const storey = this.storeys[storeyId];

        if (!storey) {
            this.error("IfcBuildingStorey not found with this ID: " + storeyId);
            if (options.done) {
                options.done();
            }
            return;
        }

        const viewer = this.viewer;
        const scene = viewer.scene;
        const camera = scene.camera;
        const aabb = storey.aabb;

        if (aabb[3] < aabb[0] || aabb[4] < aabb[1] || aabb[5] < aabb[2]) { // Don't fly to an inverted boundary
            if (options.done) {
                options.done();
            }
            return;
        }
        if (aabb[3] === aabb[0] && aabb[4] === aabb[1] && aabb[5] === aabb[2]) { // Don't fly to an empty boundary
            if (options.done) {
                options.done();
            }
            return;
        }
        const look2 = math.getAABB3Center(aabb);
        const diag = math.getAABB3Diag(aabb);
        const fitFOV = 45; // fitFOV;
        const sca = Math.abs(diag / Math.tan(fitFOV * math.DEGTORAD));

        const orthoScale2 = diag * 1.3;

        const eye2 = tempVec3a;

        eye2[0] = look2[0] + (camera.worldUp[0] * sca);
        eye2[1] = look2[1] + (camera.worldUp[1] * sca);
        eye2[2] = look2[2] + (camera.worldUp[2] * sca);

        const up2 = camera.worldForward;

        if (options.done) {

            viewer.cameraFlight.flyTo(utils.apply(options, {
                eye: eye2,
                look: look2,
                up: up2,
                orthoScale: orthoScale2
            }), () => {
                options.done();
            });

        } else {

            viewer.cameraFlight.jumpTo(utils.apply(options, {
                eye: eye2,
                look: look2,
                up: up2,
                orthoScale: orthoScale2
            }));

            viewer.camera.ortho.scale = orthoScale2;
        }
    }

    /**
     * Shows the {@link Entity}s within the given storey.
     *
     * Optionally hides all other Entitys.
     *
     * Optionally sets the visual appearance of each of the Entitys according to its IFC type. The appearance of
     * IFC types in plan views is configured by {@link StoreyViewsPlugin#objectStates}.
     *
     * See also: {@link ObjectsMemento}, which saves and restores a memento of the visual state
     * of the {@link Entity}'s that represent objects within a {@link Scene}.
     *
     * @param {String} storeyId ID of the ````IfcBuildingStorey```` object.
     * @param {*} [options] Options for showing the Entitys within the storey.
     * @param {Boolean} [options.hideOthers=false] When ````true````, hide all other {@link Entity}s.
     * @param {Boolean} [options.useObjectStates=false] When ````true````, apply the custom visibilities and appearances configured for IFC types in {@link StoreyViewsPlugin#objectStates}.
     */
    showStoreyObjects(storeyId, options = {}) {

        const storey = this.storeys[storeyId];

        if (!storey) {
            this.error("IfcBuildingStorey not found with this ID: " + storeyId);
            return;
        }

        const viewer = this.viewer;
        const scene = viewer.scene;
        const metaScene = viewer.metaScene;
        const storeyMetaObject = metaScene.metaObjects[storeyId];

        if (!storeyMetaObject) {
            return;
        }

        if (options.hideOthers) {
            scene.setObjectsVisible(viewer.scene.visibleObjectIds, false);
        }

        this.withStoreyObjects(storeyId, (entity, metaObject) => {
            if (entity) {
                if (options.useObjectStates) {
                    const props = this._objectStates[metaObject.type] || this._objectStates["DEFAULT"];
                    if (props) {
                        entity.visible = props.visible;
                        entity.edges = props.edges;
                        // entity.xrayed = props.xrayed; // FIXME: Buggy
                        // entity.highlighted = props.highlighted;
                        // entity.selected = props.selected;
                        if (props.colorize) {
                            entity.colorize = props.colorize;
                        }
                        if (props.opacity !== null && props.opacity !== undefined) {
                            entity.opacity = props.opacity;
                        }
                    }
                } else {
                    entity.visible = true;
                }
            }
        });
    }

    /**
     * Executes a callback on each of the objects within the given storey.
     *
     * ## Usage
     *
     * In the example below, we'll show all the {@link Entity}s, within the given ````IfcBuildingStorey````,
     * that have {@link MetaObject}s with type ````IfcSpace````. Note that the callback will only be given
     * an {@link Entity} when one exists for the given {@link MetaObject}.
     *
     * ````JavaScript
     * myStoreyViewsPlugin.withStoreyObjects(storeyId, (entity, metaObject) => {
     *      if (entity && metaObject && metaObject.type === "IfcSpace") {
     *          entity.visible = true;
     *      }
     * });
     * ````
     *
     * @param {String} storeyId ID of the ````IfcBuildingStorey```` object.
     * @param {Function} callback The callback.
     */
    withStoreyObjects(storeyId, callback) {
        const viewer = this.viewer;
        const scene = viewer.scene;
        const metaScene = viewer.metaScene;
        const rootMetaObject = metaScene.metaObjects[storeyId];
        if (!rootMetaObject) {
            return;
        }
        const storeySubObjects = rootMetaObject.getObjectIDsInSubtree();
        for (var i = 0, len = storeySubObjects.length; i < len; i++) {
            const objectId = storeySubObjects[i];
            const metaObject = metaScene.metaObjects[objectId];
            const entity = scene.objects[objectId];
            if (entity) {
                callback(entity, metaObject);
            }
        }
    }

    /**
     * Creates a 2D map of the given storey.
     *
     * @param {String} storeyId ID of the ````IfcBuildingStorey```` object.
     * @param {*} [options] Options for creating the image.
     * @param {Number} [options.width=300] Image width in pixels. Height will be automatically determined.
     * @param {String} [options.format="png"] Image format. Accepted values are "png" and "jpeg".
     * @returns {StoreyMap} The StoreyMap.
     */
    createStoreyMap(storeyId, options = {}) {

        const storey = this.storeys[storeyId];
        if (!storey) {
            this.error("IfcBuildingStorey not found with this ID: " + storeyId);
            return EMPTY_IMAGE;
        }

        const viewer = this.viewer;
        const scene = viewer.scene;
        const format = options.format || "png";
        const width = options.width || 300;
        const aabb = storey.aabb;
        const aspect = (aabb[5] - aabb[2]) / (aabb[3] - aabb[0]);
        const height = width * aspect;
        const padding = options.padding || 0;

        this._objectsMemento.saveObjects(scene);
        this._cameraMemento.saveCamera(scene);

        this.showStoreyObjects(storeyId, utils.apply(options, {
            useObjectStates: true,
            hideOthers: true
        }));

        this._arrangeStoreyMapCamera(storey);

        //scene.render(true); // Force-render a frame

        const src = viewer.getSnapshot({
            width: width,
            height: height,
            format: format,
        });

        this._objectsMemento.restoreObjects(scene);
        this._cameraMemento.restoreCamera(scene);

        return new StoreyMap(storeyId, src, format, width, height, padding);
    }

    _arrangeStoreyMapCamera(storey) {
        const viewer = this.viewer;
        const scene = viewer.scene;
        const camera = scene.camera;
        const aabb = storey.aabb;
        const look = math.getAABB3Center(aabb);
        const sca = 0.5;
        const eye = tempVec3a;
        eye[0] = look[0] + (camera.worldUp[0] * sca);
        eye[1] = look[1] + (camera.worldUp[1] * sca);
        eye[2] = look[2] + (camera.worldUp[2] * sca);
        const up = camera.worldForward;
        viewer.cameraFlight.jumpTo({eye: eye, look: look, up: up});
        const xHalfSize = (aabb[3] - aabb[0]) / 2;
        const yHalfSize = (aabb[4] - aabb[1]) / 2;
        const zHalfSize = (aabb[5] - aabb[2]) / 2;
        const xmin = -xHalfSize;
        const xmax = +xHalfSize;
        const ymin = -yHalfSize;
        const ymax = +yHalfSize;
        const zmin = -zHalfSize;
        const zmax = +zHalfSize;
        viewer.camera.customProjection.matrix = math.orthoMat4c(xmin, xmax, zmin, zmax, ymin, ymax, tempMat4);
        viewer.camera.projection = "customProjection";
    }

    /**
     * Attempts to pick an {@link Entity} at the given pixel coordinates within a StoreyMap image.
     *
     * @param {StoreyMap} storeyMap The StoreyMap.
     * @param {Number[]} imagePos 2D pixel coordinates within the bounds of {@link StoreyMap#imageData}.
     * @param {*} [options] Picking options.
     * @param {Boolean} [options.pickSurface=false] Whether to return the picked position on the surface of the Entity.
     * @returns {PickResult} The pick result, if an Entity was successfully picked, else null.
     */
    pickStoreyMap(storeyMap, imagePos, options={}) {

        const storeyId = storeyMap.storeyId;
        const storey = this.storeys[storeyId];

        if (!storey) {
            this.error("IfcBuildingStorey not found with this ID: " + storeyId);
            return null
        }

        const normX = 1.0 - (imagePos[0] / storeyMap.width);
        const normZ = 1.0 - (imagePos[1] / storeyMap.height);

        const aabb = storey.aabb;

        const xmin = aabb[0];
        const ymin = aabb[1];
        const zmin = aabb[2];
        const xmax = aabb[3];
        const ymax = aabb[4];
        const zmax = aabb[5];

        const xWorldSize = xmax - xmin;
        const yWorldSize = ymax - ymin;
        const zWorldSize = zmax - zmin;

        const origin = math.vec3([xmin + (xWorldSize * normX), ymin + (yWorldSize * 0.5), zmin + (zWorldSize * normZ)]);
        const direction = math.vec3([0, -1, 0]);
        const look = math.addVec3(origin, direction, tempVec3a);
        const worldForward = this.viewer.camera.worldForward;
        const matrix = math.lookAtMat4v(origin, look, worldForward, tempMat4);

        const pickResult = this.viewer.scene.pick({  // Picking with arbitrarily-positioned ray
            pickSurface: options.pickSurface,
            pickInvisible: true,
            matrix: matrix
        });

        if (pickResult) {
            const metaObject = this.viewer.metaScene.metaObjects[pickResult.entity.id];
            const objectState = this.objectStates[metaObject.type];
            if (!objectState || !objectState.visible) {
                return null;
            }
        }

        return pickResult;
    }

    /**
     * Gets the ID of the storey that contains the given 3D World-space position.
     *.
     * @param {Number[]} worldPos 3D World-space position.
     * @returns {String} ID of the storey containing the position, or null if the position falls outside all the storeys.
     */
    getStoreyContainingWorldPos(worldPos) {
        for (var storeyId in this.storeys) {
            const storey = this.storeys[storeyId];
            if (math.point3AABB3Intersect(storey.aabb, worldPos)) {
                return storeyId;
            }
        }
        return null;
    }

    /**
     * Converts a 3D World-space position to a 2D position within a StoreyMap image.
     *
     * Use {@link StoreyViewsPlugin#pickStoreyMap} to convert 2D image positions to 3D world-space.
     *
     * @param {StoreyMap} storeyMap The StoreyMap.
     * @param {Number[]} worldPos 3D World-space position within the storey.
     * @param {Number[]} imagePos 2D pixel position within the {@link StoreyMap#imageData}.
     * @returns {Boolean} True if ````imagePos```` is within the bounds of the {@link StoreyMap#imageData}, else ````false```` if it falls outside.
     */
    worldPosToStoreyMap(storeyMap, worldPos, imagePos) {

        const storeyId = storeyMap.storeyId;
        const storey = this.storeys[storeyId];

        if (!storey) {
            this.error("IfcBuildingStorey not found with this ID: " + storeyId);
            return false
        }

        const aabb = storey.aabb;

        const xmin = aabb[0];
        const ymin = aabb[1];
        const zmin = aabb[2];

        const xmax = aabb[3];
        const ymax = aabb[4];
        const zmax = aabb[5];

        const xWorldSize = xmax - xmin;
        const yWorldSize = ymax - ymin;
        const zWorldSize = zmax - zmin;

        const camera = this.viewer.camera;
        const worldUp = camera.worldUp;

        const xUp = worldUp[0] > worldUp[1] && worldUp[0] > worldUp[2];
        const yUp = !xUp && worldUp[1] > worldUp[0] && worldUp[1] > worldUp[2];
        const zUp = !xUp && !yUp && worldUp[2] > worldUp[0] && worldUp[2] > worldUp[1];

        const ratioX = (storeyMap.width / xWorldSize);
        const ratioY = yUp ? (storeyMap.height / zWorldSize) : (storeyMap.height / yWorldSize); // Assuming either Y or Z is "up", but never X

        imagePos[0] = Math.floor(storeyMap.width - ((worldPos[0] - xmin) * ratioX));
        imagePos[1] = Math.floor(storeyMap.height - ((worldPos[2] - zmin) * ratioY));

        return (imagePos[0] >= 0 && imagePos[0] < storeyMap.width && imagePos[1] >= 0 && imagePos[1] <= storeyMap.height);
    }

    // /**
    //  * Converts 2D position within a StoreyMap image to a 3D World-space position.
    //  *
    //  * @param {StoreyMap} storeyMap The StoreyMap.
    //  * @param {Number[]} imagePos 2D pixel position within the bounds of {@link StoreyMap#imageData}.
    //  * @param {Number[]} worldPos 3D World-space position within the storey.
    //  */
    // storeyMapToWorldPos(storeyMap, imagePos, worldPos) {
    //
    // }

    /**
     * Converts a 3D World-space direction vector to a 2D vector within a StoreyMap image.
     *
     * @param {StoreyMap} storeyMap The StoreyMap.
     * @param {Number[]} worldDir 3D World-space direction vector.
     * @param {Number[]} imageDir Normalized 2D direction vector.
     */
    worldDirToStoreyMap(storeyMap, worldDir, imageDir) {
        const camera = this.viewer.camera;
        const eye = camera.eye;
        const look = camera.look;
        const eyeLookDir = math.subVec3(look, eye, tempVec3a);
        const worldUp = camera.worldUp;
        const xUp = worldUp[0] > worldUp[1] && worldUp[0] > worldUp[2];
        const yUp = !xUp && worldUp[1] > worldUp[0] && worldUp[1] > worldUp[2];
        const zUp = !xUp && !yUp && worldUp[2] > worldUp[0] && worldUp[2] > worldUp[1];
        if (xUp) {
            imageDir[0] = eyeLookDir[1];
            imageDir[1] = eyeLookDir[2];
        } else if (yUp) {
            imageDir[0] = eyeLookDir[0];
            imageDir[1] = eyeLookDir[2];
        } else {
            imageDir[0] = eyeLookDir[0];
            imageDir[1] = eyeLookDir[1];
        }
        math.normalizeVec2(imageDir);
    }

    /**
     * Destroys this StoreyViewsPlugin.
     */
    destroy() {
        this.viewer.scene.off(this._onModelLoaded);
        super.destroy();
    }
}

export {StoreyViewsPlugin}
