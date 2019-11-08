import {utils} from "../../viewer/scene/utils.js"
import {PerformanceModel} from "../../viewer/scene/PerformanceModel/PerformanceModel.js";
import {Node} from "../../viewer/scene/nodes/Node.js";
import {Plugin} from "../../viewer/Plugin.js";
import {GLTFQualityLoader} from "./GLTFQualityLoader.js";
import {GLTFPerformanceLoader} from "./GLTFPerformanceLoader.js";
import {IFCObjectDefaults} from "../../viewer/metadata/IFCObjectDefaults.js";
import {GLTFDefaultDataSource} from "./GLTFDefaultDataSource.js";

/**
 * {@link Viewer} plugin that loads models from [glTF](https://www.khronos.org/gltf/).
 *
 * * Creates an {@link Entity} representing each model it loads, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}.
 * * Creates an {@link Entity} for each object within the model, which is indicated by each glTF ````node```` that has a ````name```` attribute. Those Entities will have {@link Entity#isObject} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#objects}.
 * * When loading, can set the World-space position, scale and rotation of each model within World space, along with initial properties for all the model's {@link Entity}s.
 *
 * ## Metadata
 *
 * GLTFLoaderPlugin can also load an accompanying JSON metadata file with each model, which creates a {@link MetaModel} corresponding
 * to the model {@link Entity} and a {@link MetaObject} corresponding to each object {@link Entity}.
 *
 * Each {@link MetaObject} has a {@link MetaObject#type}, which indicates the classification of its corresponding {@link Entity}. When loading
 * metadata, we can also provide GLTFLoaderPlugin with a custom lookup table of initial values to set on the properties of each type of {@link Entity}. By default, GLTFLoaderPlugin
 * uses its own map of default colors and visibilities for IFC element types.
 *
 * ## Quality Setting
 *
 * By default, GLTFLoaderPlugin will load a high-performance scene representation that's optimized for low memory usage and
 * optimal rendering. The high-performance representation renders large numbers of objects efficiently, using geometry
 * batching and instancing, with simple Lambertian shading that ignores any textures and realistic materials in the glTF.
 *
 * Specifying ````performance:false```` to {@link GLTFLoaderPlugin#load} will internally load a heavier scene
 * representation comprised of {@link Node}, {@link Mesh}, {@link Geometry}, {@link Material} and {@link Texture} components,
 * that will exactly preserve the materials specified in the glTF. Use this when you want to load a model for a realistic preview,
 * maybe using PBR etc.
 *
 * We tend to use the default ````performance:true```` setting for CAD and BIM models, where structure is more important that
 * surface appearance.
 *
 * Publically, GLTFLoaderPlugin creates the same {@link Entity}s for both levels of performance. Privately, however, it implements
 * {@link Entity}s using two different sets of concrete subtypes, for its two different internally-managed scene representations.
 *
 * ## Usage
 *
 * In the example below we'll load the Schependomlaan model from a [glTF file](http://xeokit.github.io/xeokit-sdk/examples/models/gltf/schependomlaan/), along
 * with an accompanying JSON [IFC metadata file](http://xeokit.github.io/xeokit-sdk/examples/metaModels/schependomlaan/).
 *
 * This will create a bunch of {@link Entity}s that represents the model and its objects, along with a {@link MetaModel} and {@link MetaObject}s
 * that hold their metadata.
 *
 * Since this model contains IFC types, the GLTFLoaderPlugin will set the initial colors of object {@link Entity}s according
 * to the standard IFC element colors in the GLTFModel's current map. Override that with your own map via property {@link GLTFLoaderPlugin#objectDefaults}.
 *
 * Read more about this example in the user guide on [Viewing BIM Models Offline](https://github.com/xeokit/xeokit-sdk/wiki/Viewing-BIM-Models-Offline).
 *
 * We're leaving ````performance: true```` since our model has many objects and we're not interested in realistic rendering.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_glTF_OTCConferenceCenter)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 *
 * //------------------------------------------------------------------------------------------------------------------
 * // 1. Create a Viewer,
 * // 2. Arrange the camera,
 * // 3. Tweak the selection material (tone it down a bit)
 * //------------------------------------------------------------------------------------------------------------------
 *
 * // 1
 * const viewer = new Viewer({
 *      canvasId: "myCanvas",
 *      transparent: true
 * });
 *
 * // 2
 * viewer.camera.orbitPitch(20);
 * viewer.camera.orbitYaw(-45);
 *
 * // 3
 * viewer.scene.selectedMaterial.fillAlpha = 0.1;
 *
 * //------------------------------------------------------------------------------------------------------------------
 * // 1. Create a glTF loader plugin,
 * // 2. Load a glTF building model and JSON IFC metadata
 * // 3. Emphasis the edges to make it look nice
 * //------------------------------------------------------------------------------------------------------------------
 *
 * // 1
 * const gltfLoader = new GLTFLoaderPlugin(viewer);
 *
 * // 2
 * var model = gltfLoader.load({                                    // Returns an Entity that represents the model
 *      id: "myModel",
 *      src: "./models/gltf/OTCConferenceCenter/scene.gltf",
 *      metaModelSrc: "./metaModels/OTCConferenceCenter/metaModel.json",     // Creates a MetaModel (see below)
 *      edges: true,
 *      performance: true  // Load high-performance scene representation (default is false)
 * });
 *
 * model.on("loaded", () => {
 *
 *      //--------------------------------------------------------------------------------------------------------------
 *      // 1. Find metadata on the third storey
 *      // 2. Select all the objects in the building's third storey
 *      // 3. Fit the camera to all the objects on the third storey
 *      //--------------------------------------------------------------------------------------------------------------
 *
 *      // 1
 *      const metaModel = viewer.metaScene.metaModels["myModel"];       // MetaModel with ID "myModel"
 *      const metaObject
 *          = viewer.metaScene.metaObjects["0u4wgLe6n0ABVaiXyikbkA"];   // MetaObject with ID "0u4wgLe6n0ABVaiXyikbkA"
 *
 *      const name = metaObject.name;                                   // "01 eerste verdieping"
 *      const type = metaObject.type;                                   // "IfcBuildingStorey"
 *      const parent = metaObject.parent;                               // MetaObject with type "IfcBuilding"
 *      const children = metaObject.children;                           // Array of child MetaObjects
 *      const objectId = metaObject.id;                                 // "0u4wgLe6n0ABVaiXyikbkA"
 *      const objectIds = viewer.metaScene.getObjectIDsInSubtree(objectId);   // IDs of leaf sub-objects
 *      const aabb = viewer.scene.getAABB(objectIds);                   // Axis-aligned boundary of the leaf sub-objects
 *
 *      // 2
 *      viewer.scene.setObjectsSelected(objectIds, true);
 *
 *      // 3
 *      viewer.cameraFlight.flyTo(aabb);
 * });
 *
 * // Find the model Entity by ID
 * model = viewer.scene.models["myModel"];
 *
 * // Destroy the model
 * model.destroy();
 * ````
 *
 * ## Transforming
 *
 * We have the option to rotate, scale and translate each  *````.glTF````* model as we load it.
 *
 * This lets us load multiple models, or even multiple copies of the same model, and position them apart from each other.
 *
 * In the example below, we'll scale our model to half its size, rotate it 90 degrees about its local X-axis, then
 * translate it 100 units along its X axis.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#loading_glTF_Duplex_transform)]
 *
 * ````javascript
 * const model = gltfLoader.load({
 *      src: "./models/gltf/duplex/scene.gltf",
 *      metaModelSrc: "./metaModels/duplex/metaModel.json",
 *      rotation: [90,0,0],
 *      scale: [0.5, 0.5, 0.5],
 *      position: [100, 0, 0]
 * });
 * ````
 *
 * ## Including and excluding IFC types
 *
 * We can also load only those objects that have the specified IFC types. In the example below, we'll load only the
 * objects that represent walls.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_glTF_includeTypes_PlanView)]
 *
 * ````javascript
 * const model = gltfLoader.load({
 *     id: "myModel",
 *      src: "./models/gltf/OTCConferenceCenter/scene.gltf",
 *      metaModelSrc: "./metaModels/OTCConferenceCenter/metaModel.json",
 *      includeTypes: ["IfcWallStandardCase"]
 * });
 * ````
 *
 * We can also load only those objects that **don't** have the specified IFC types. In the example below, we'll load only the
 * objects that do not represent empty space.
 *
 * ````javascript
 * const model = gltfLoader.load({
 *     id: "myModel",
 *      src: "./models/gltf/OTCConferenceCenter/scene.gltf",
 *      metaModelSrc: "./metaModels/OTCConferenceCenter/metaModel.json",
 *      excludeTypes: ["IfcSpace"]
 * });
 * ````
 * @class GLTFLoaderPlugin
 */
class GLTFLoaderPlugin extends Plugin {

    /**
     * @constructor
     *
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="GLTFLoader"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Object} [cfg.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object.  Default value is {@link IFCObjectDefaults}.
     * @param {Object} [cfg.dataSource] A custom data source through which the GLTFLoaderPlugin can load metadata, glTF and binary attachments. Defaults to an instance of {@link GLTFDefaultDataSource}, which loads uover HTTP.
     */
    constructor(viewer, cfg = {}) {

        super("GLTFLoader", viewer, cfg);

        /**
         * @private
         */
        this._glTFQualityLoader = new GLTFQualityLoader(this, cfg);

        /**
         * @private
         */
        this._glTFPerformanceLoader = new GLTFPerformanceLoader(this, cfg);

        this.dataSource = cfg.dataSource;
        this.objectDefaults = cfg.objectDefaults;
    }

    /**
     * Sets a custom data source through which the GLTFLoaderPlugin can load metadata, glTF and binary attachments.
     *
     * Default value is {@link GLTFDefaultDataSource}, which loads via an XMLHttpRequest.
     *
     * @type {Object}
     */
    set dataSource(value) {
        this._dataSource = value || new GLTFDefaultDataSource();
    }

    /**
     * Gets the custom data source through which the GLTFLoaderPlugin can load metadata, glTF and binary attachments.
     *
     * Default value is {@link GLTFDefaultDataSource}, which loads via an XMLHttpRequest.
     *
     * @type {Object}
     */
    get dataSource() {
        return this._dataSource;
    }

    /**
     * Sets map of initial default states for each loaded {@link Entity} that represents an object.
     *
     * Default value is {@link IFCObjectDefaults}.
     *
     * @type {{String: Object}}
     */
    set objectDefaults(value) {
        this._objectDefaults = value || IFCObjectDefaults;
    }

    /**
     * Gets map of initial default states for each loaded {@link Entity} that represents an object.
     *
     * Default value is {@link IFCObjectDefaults}.
     *
     * @type {{String: Object}}
     */
    get objectDefaults() {
        return this._objectDefaults;
    }

    /**
     * Loads a glTF model from a file into this GLTFLoaderPlugin's {@link Viewer}.
     *
     * @param {*} params Loading parameters.
     * @param {String} [params.id] ID to assign to the root {@link Entity#id}, unique among all components in the Viewer's {@link Scene}, generated automatically by default.
     * @param {String} [params.src] Path to a glTF file, as an alternative to the ````gltf```` parameter.
     * @param {*} [params.gltf] glTF JSON, as an alternative to the ````src```` parameter.
     * @param {String} [params.metaModelSrc] Path to an optional metadata file, as an alternative to the ````metaModelData```` parameter (see user guide: [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {*} [params.metaModelData] JSON model metadata, as an alternative to the ````metaModelSrc```` parameter (see user guide: [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {{String:Object}} [params.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object. Default value is {@link IFCObjectDefaults}.
     * @params {String[]} [params.includeTypes] When loading metadata, only loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     * @params {String[]} [params.excludeTypes] When loading metadata, never loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     * @param {Boolean} [params.edges=false] Whether or not xeokit renders the model with edges emphasized.
     * @param {Number[]} [params.position=[0,0,0]] The model World-space 3D position.
     * @param {Number[]} [params.scale=[1,1,1]] The model's World-space scale.
     * @param {Number[]} [params.rotation=[0,0,0]] The model's World-space rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [params.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]] The model's world transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Boolean} [params.backfaces=false] When true, allows visible backfaces, wherever specified in the glTF. When false, ignores backfaces.
     * @param {Number} [params.edgeThreshold=20] When xraying, highlighting, selecting or edging, this is the threshold angle between normals of adjacent triangles, below which their shared wireframe edge is not drawn.
     * @params {Boolean} [params.performance=true] Set ````false```` to load all the materials and textures provided by the glTF file, otherwise leave ````true```` to load the default high-performance representation optimized for low memory usage and efficient rendering.
     * @returns {Entity} Entity representing the model, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}
     */
    load(params = {}) {

        if (params.id && this.viewer.scene.components[params.id]) {
            this.error("Component with this ID already exists in viewer: " + params.id + " - will autogenerate this ID");
            delete params.id;
        }

        const performance = params.performance !== false;

        const model = performance

            // PerformanceModel provides performance-oriented scene representation
            // converting glTF materials to simple flat-shading without textures

            ? new PerformanceModel(this.viewer.scene, utils.apply(params, {
                isModel: true
            }))

            // Scene Node graph supports original glTF materials

            : new Node(this.viewer.scene, utils.apply(params, {
                isModel: true
            }));

        const modelId = model.id;  // In case ID was auto-generated

        if (!params.src && !params.gltf) {
            this.error("load() param expected: src or gltf");
            return model; // Return new empty model
        }

        const loader = performance ? this._glTFPerformanceLoader : this._glTFQualityLoader;

        if (params.metaModelSrc || params.metaModelData) {

            const objectDefaults = params.objectDefaults || this._objectDefaults || IFCObjectDefaults;

            const processMetaModelData = (metaModelData) => {

                this.viewer.metaScene.createMetaModel(modelId, metaModelData, {
                    includeTypes: params.includeTypes,
                    excludeTypes: params.excludeTypes
                });

                this.viewer.scene.canvas.spinner.processes--;

                var includeTypes;
                if (params.includeTypes) {
                    includeTypes = {};
                    for (let i = 0, len = params.includeTypes.length; i < len; i++) {
                        includeTypes[params.includeTypes[i]] = true;
                    }
                }

                var excludeTypes;
                if (params.excludeTypes) {
                    excludeTypes = {};
                    for (let i = 0, len = params.excludeTypes.length; i < len; i++) {
                        includeTypes[params.excludeTypes[i]] = true;
                    }
                }

                params.readableGeometry = false;

                params.prioritizeGLTFNode = (modelId, glTFNode) => {

                    // The "name" property of the glTF scene node contains the object ID, with which we can find a MetaObject
                    // in the MetaModel we just loaded. We'll create Node components in the Scene for all the nodes as we
                    // descend into them, but will give special treatment to those nodes that have a "name", ie. set initial
                    // state for those according to the MetaModel.

                    const name = glTFNode.name;

                    if (!name) {
                        return 0;
                    }

                    const nodeId = name;
                    const metaObject = this.viewer.metaScene.metaObjects[nodeId];
                    const type = (metaObject ? metaObject.type : "DEFAULT") || "DEFAULT";

                    if (metaObject) {
                        if (excludeTypes) {
                            if (excludeTypes[type]) {
                                return null;
                            }
                        }
                        if (includeTypes) {
                            if (!includeTypes[type]) {
                                return null;
                            }
                        }
                    }

                    const props = objectDefaults[type];

                    return props ? (props.priority || 0) : 0;
                };

                params.handleGLTFNode = (modelId, glTFNode, actions) => {

                    const name = glTFNode.name;

                    if (!name) {
                        return true; // Continue descending this node subtree
                    }

                    const nodeId = name;
                    const metaObject = this.viewer.metaScene.metaObjects[nodeId];
                    const type = (metaObject ? metaObject.type : "DEFAULT") || "DEFAULT";

                    actions.createEntity = {
                        id: nodeId,
                        isObject: true // Registers the Entity in Scene#objects
                    };

                    const props = objectDefaults[type];

                    if (props) { // Set Entity's initial rendering state for recognized type

                        if (props.visible === false) {
                            actions.createEntity.visible = false;
                        }

                        if (props.colorize) {
                            actions.createEntity.colorize = props.colorize;
                        }

                        if (props.pickable === false) {
                            actions.createEntity.pickable = false;
                        }

                        if (props.opacity !== undefined && props.opacity !== null) {
                            actions.createEntity.opacity = props.opacity;
                        }
                    }

                    return true; // Continue descending this glTF node subtree
                };

                if (params.src) {
                    loader.load(this, model, params.src, params);
                } else {
                    loader.parse(this, model, params.gltf, params);
                }
            };

            if (params.metaModelSrc) {

                const metaModelSrc = params.metaModelSrc;

                this.viewer.scene.canvas.spinner.processes++;

                this._dataSource.getMetaModel(metaModelSrc, (metaModelData) => {

                    this.viewer.scene.canvas.spinner.processes--;

                    processMetaModelData(metaModelData);

                }, (errMsg) => {
                    this.error(`load(): Failed to load model metadata for model '${modelId} from  '${metaModelSrc}' - ${errMsg}`);
                    this.viewer.scene.canvas.spinner.processes--;
                });

            } else if (params.metaModelData) {

                processMetaModelData(params.metaModelData);
            }

        } else {

            params.handleGLTFNode = (modelId, glTFNode, actions) => {

                const name = glTFNode.name;

                if (!name) {
                    return true; // Continue descending this node subtree
                }

                const id = name;

                actions.createEntity = { // Create an Entity for this glTF scene node
                    id: id,
                    isObject: true // Registers the Entity in Scene#objects
                };

                return true; // Continue descending this glTF node subtree
            };

            if (params.src) {
                loader.load(this, model, params.src, params);
            } else {
                loader.parse(this, model, params.gltf, params);
            }
        }

        model.once("destroyed", () => {
            this.viewer.metaScene.destroyMetaModel(modelId);
        });

        return model;
    }

    /**
     * Destroys this GLTFLoaderPlugin.
     */
    destroy() {
        super.destroy();
    }
}

export {GLTFLoaderPlugin}