import {utils} from "../../viewer/scene/utils.js"
import {PerformanceModel} from "../../viewer/scene/PerformanceModel/PerformanceModel.js";
import {Plugin} from "../../viewer/Plugin.js";
import {XKTDefaultDataSource} from "./XKTDefaultDataSource.js";
import {IFCObjectDefaults} from "../../viewer/metadata/IFCObjectDefaults.js";
import * as p from "./lib/pako.js";

let pako = window.pako || p;
if(!pako.inflate) {
    // See https://github.com/nodeca/pako/issues/97
    pako = pako.default;
}

const XKT_VERSION = 2; // XKT format version supported by this XKTLoaderPlugin

const decompressColor = (function () {
    const color2 = new Float32Array(3);
    return function (color) {
        color2[0] = color[0] / 255.0;
        color2[1] = color[1] / 255.0;
        color2[2] = color[2] / 255.0;
        return color2;
    };
})();

/**
 * {@link Viewer} plugin that loads models from xeokit's optimized *````.xkt````* format.
 *
 * <a href="https://xeokit.github.io/xeokit-sdk/examples/#loading_XKT_OTCConferenceCenter"><img src="http://xeokit.io/img/docs/XKTLoaderPlugin/XKTLoaderPlugin.png"></a>
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#loading_XKT_OTCConferenceCenter)]
 *
 * ## Overview
 *
 * * XKTLoaderPlugin is the most efficient way to load high-detail models into xeokit.
 * * An *````.xkt````* file is a single BLOB containing a model, compressed using geometry quantization
 * and [pako](https://nodeca.github.io/pako/).
 * * Set the position, scale and rotation of each model as you load it.
 * * Filter which IFC types get loaded.
 * * Configure initial default appearances for IFC types.
 * * Set a custom data source for *````.xkt````* and IFC metadata files.
 * * Does not support textures or physically-based materials.
 *
 * ## Credits
 *
 * XKTLoaderPlugin and the ````xeokit-gltf-to-xkt```` tool (see below) are based on prototypes
 * by [Toni Marti](https://github.com/tmarti) at [uniZite](https://www.unizite.com/login).
 *
 * ## Creating *````.xkt````* files
 *
 * Use the node.js-based [xeokit-gltf-to-xkt](https://github.com/xeokit/xeokit-gltf-to-xkt) tool to
 * convert your ````glTF```` IFC files to *````.xkt````* format.
 *
 * ## Scene representation
 *
 * When loading a model, XKTLoaderPlugin creates an {@link Entity} that represents the model, which
 * will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id}
 * in {@link Scene#models}. The XKTLoaderPlugin also creates an {@link Entity} for each object within the
 * model. Those Entities will have {@link Entity#isObject} set ````true```` and will be registered
 * by {@link Entity#id} in {@link Scene#objects}.
 *
 * ## Metadata
 *
 * XKTLoaderPlugin can also load an accompanying JSON metadata file with each model, which creates a {@link MetaModel} corresponding
 * to the model {@link Entity} and a {@link MetaObject} corresponding to each object {@link Entity}.
 *
 * Each {@link MetaObject} has a {@link MetaObject#type}, which indicates the classification of its corresponding {@link Entity}. When loading
 * metadata, we can also configure XKTLoaderPlugin with a custom lookup table of initial values to set on the properties of each type of {@link Entity}. By default, XKTLoaderPlugin
 * uses its own map of default colors and visibilities for IFC element types.
 *
 * ## Usage
 *
 * In the example below we'll load the Schependomlaan model from a [.xkt file](https://github.com/xeokit/xeokit-sdk/tree/master/examples/models/xkt/schependomlaan), along
 * with an accompanying JSON [IFC metadata file](https://github.com/xeokit/xeokit-sdk/tree/master/examples/metaModels/schependomlaan).
 *
 * This will create a bunch of {@link Entity}s that represents the model and its objects, along with a {@link MetaModel} and {@link MetaObject}s
 * that hold their metadata.
 *
 * Since this model contains IFC types, the XKTLoaderPlugin will set the initial appearance of each object {@link Entity} according to its IFC type in {@link XKTLoaderPlugin#objectDefaults}.
 *
 * Read more about this example in the user guide on [Viewing BIM Models Offline](https://github.com/xeokit/xeokit-sdk/wiki/Viewing-BIM-Models-Offline).
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_XKT_metadata_Schependomlaan)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 *
 * //------------------------------------------------------------------------------------------------------------------
 * // 1. Create a Viewer,
 * // 2. Arrange the camera
 * //------------------------------------------------------------------------------------------------------------------
 *
 * // 1
 * const viewer = new Viewer({
 *      canvasId: "myCanvas",
 *      transparent: true
 * });
 *
 * // 2
 * viewer.camera.eye = [-2.56, 8.38, 8.27];
 * viewer.camera.look = [13.44, 3.31, -14.83];
 * viewer.camera.up = [0.10, 0.98, -0.14];
 *
 * //------------------------------------------------------------------------------------------------------------------
 * // 1. Create a XKTLoaderPlugin,
 * // 2. Load a building model and JSON IFC metadata
 * //------------------------------------------------------------------------------------------------------------------
 *
 * // 1
 * const xktLoader = new XKTLoaderPlugin(viewer);
 *
 * // 2
 * const model = xktLoader.load({                                       // Returns an Entity that represents the model
 *     id: "myModel",
 *     src: "./models/xkt/schependomlaan/schependomlaan.xkt",
 *     metaModelSrc: "./metaModels/schependomlaan/metaModel.json",     // Creates a MetaModel (see below)
 *     edges: true
 * });
 *
 * model.on("loaded", () => {
 *
 *     //--------------------------------------------------------------------------------------------------------------
 *     // 1. Find metadata on the third storey
 *     // 2. Select all the objects in the building's third storey
 *     // 3. Fit the camera to all the objects on the third storey
 *     //--------------------------------------------------------------------------------------------------------------
 *
 *     // 1
 *     const metaModel = viewer.metaScene.metaModels["myModel"];       // MetaModel with ID "myModel"
 *     const metaObject
 *          = viewer.metaScene.metaObjects["0u4wgLe6n0ABVaiXyikbkA"];  // MetaObject with ID "0u4wgLe6n0ABVaiXyikbkA"
 *
 *     const name = metaObject.name;                                   // "01 eerste verdieping"
 *     const type = metaObject.type;                                   // "IfcBuildingStorey"
 *     const parent = metaObject.parent;                               // MetaObject with type "IfcBuilding"
 *     const children = metaObject.children;                           // Array of child MetaObjects
 *     const objectId = metaObject.id;                                 // "0u4wgLe6n0ABVaiXyikbkA"
 *     const objectIds = viewer.metaScene.getObjectIDsInSubtree(objectId);   // IDs of leaf sub-objects
 *     const aabb = viewer.scene.getAABB(objectIds);                   // Axis-aligned boundary of the leaf sub-objects
 *
 *     // 2
 *     viewer.scene.setObjectsSelected(objectIds, true);
 *
 *     // 3
 *     viewer.cameraFlight.flyTo(aabb);
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
 * We have the option to rotate, scale and translate each  *````.xkt````* model as we load it.
 *
 * This lets us load multiple models, or even multiple copies of the same model, and position them apart from each other.
 *
 * In the example below, we'll scale our model to half its size, rotate it 90 degrees about its local X-axis, then
 * translate it 100 units along its X axis.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#loading_XKT_Duplex_transform)]
 *
 * ````javascript
 * xktLoader.load({
 *      src: "./models/xkt/duplex/duplex.xkt",
 *      metaModelSrc: "./metaModels/duplex/metaModel.json",
 *      rotation: [90,0,0],
 *      scale: [0.5, 0.5, 0.5],
 *      position: [100, 0, 0]
 * });
 * ````
 *
 * ## Including and excluding IFC types
 *
 * We can also load only those objects that have the specified IFC types.
 *
 * In the example below, we'll load only the objects that represent walls.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_XKT_includeTypes)]
 *
 * ````javascript
 * const model2 = xktLoader.load({
 *     id: "myModel2",
 *     src: "./models/xkt/OTCConferenceCenter/OTCConferenceCenter.xkt",
 *     metaModelSrc: "./metaModels/OTCConferenceCenter/metaModel.json",
 *     includeTypes: ["IfcWallStandardCase"]
 * });
 * ````
 *
 * We can also load only those objects that **don't** have the specified IFC types.
 *
 * In the example below, we'll load only the objects that do not represent empty space.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_XKT_excludeTypes)]
 *
 * ````javascript
 * const model3 = xktLoader.load({
 *     id: "myModel3",
 *     src: "./models/xkt/OTCConferenceCenter/OTCConferenceCenter.xkt",
 *     metaModelSrc: "./metaModels/OTCConferenceCenter/metaModel.json",
 *     excludeTypes: ["IfcSpace"]
 * });
 * ````
 *
 * ## Configuring initial IFC object appearances
 *
 * We can specify the initial appearance of loaded objects according to their IFC types.
 *
 * This is useful for things like:
 *
 * * setting the colors to our objects according to their IFC types,
 * * automatically hiding ````IfcSpace```` objects, and
 * * ensuring that ````IfcWindow```` objects are always transparent.
 *
 * <br>
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#BIMOffline_XKT_objectDefaults)]
 *
 * ````javascript
 * const myObjectDefaults = {
 *
 *      IfcSpace: {
 *          visible: false
 *      },
 *      IfcWindow: {
 *          colorize: [0.337255, 0.303922, 0.870588], // Blue
 *          opacity: 0.3
 *      },
 *
 *      //...
 *
 *      DEFAULT: {
 *          colorize: [0.5, 0.5, 0.5]
 *      }
 * };
 *
 * const model4 = xktLoader.load({
 *      id: "myModel4",
 *      src: "./models/xkt/duplex/duplex.xkt",
 *      metaModelSrc: "./metaModels/duplex/metaModel.json", // Creates a MetaObject instances in scene.metaScene.metaObjects
 *      objectDefaults: myObjectDefaults // Use our custom initial default states for object Entities
 * });
 * ````
 *
 * ## Configuring a custom data source
 *
 * By default, XKTLoaderPlugin will load *````.xkt````* files and metadata JSON over HTTP.
 *
 * As shown below, we can customize the way XKTLoaderPlugin loads the files by configuring it with our own data source
 * object. For simplicity, our custom data source example also uses HTTP, using a couple of xeokit utility functions.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#loading_XKT_dataSource)]
 *
 * ````javascript
 * import {utils} from "./../src/viewer/scene/utils.js";
 *
 * class MyDataSource {
 *
 *      constructor() {
 *      }
 *
 *      // Gets metamodel JSON
 *      getMetaModel(metaModelSrc, ok, error) {
 *          console.log("MyDataSource#getMetaModel(" + metaModelSrc + ", ... )");
 *          utils.loadJSON(metaModelSrc,
 *              (json) => {
 *                  ok(json);
 *              },
 *              function (errMsg) {
 *                  error(errMsg);
 *              });
 *      }
 *
 *      // Gets the contents of the given .xkt file in an arraybuffer
 *      getXKT(src, ok, error) {
 *          console.log("MyDataSource#getXKT(" + xKTSrc + ", ... )");
 *          utils.loadArraybuffer(src,
 *              (arraybuffer) => {
 *                  ok(arraybuffer);
 *              },
 *              function (errMsg) {
 *                  error(errMsg);
 *              });
 *      }
 * }
 *
 * const xktLoader2 = new XKTLoaderPlugin(viewer, {
 *       dataSource: new MyDataSource()
 * });
 *
 * const model5 = xktLoader2.load({
 *      id: "myModel5",
 *      src: "./models/xkt/duplex/duplex.xkt",
 *      metaModelSrc: "./metaModels/duplex/metaModel.json" // Creates a MetaObject instances in scene.metaScene.metaObjects
 * });
 * ````
 * @class XKTLoaderPlugin
 */
class XKTLoaderPlugin extends Plugin {

    /**
     * @constructor
     *
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="XKTLoader"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Object} [cfg.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object.  Default value is {@link IFCObjectDefaults}.
     * @param {Object} [cfg.dataSource] A custom data source through which the XKTLoaderPlugin can load model and metadata files. Defaults to an instance of {@link XKTDefaultDataSource}, which loads uover HTTP.
     * @param {String[]} [cfg.includeTypes] When loading metadata, only loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     * @param {String[]} [cfg.excludeTypes] When loading metadata, never loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     */
    constructor(viewer, cfg = {}) {

        super("XKTLoader", viewer, cfg);

        this.dataSource = cfg.dataSource;
        this.objectDefaults = cfg.objectDefaults;
        this.includeTypes = cfg.includeTypes;
        this.excludeTypes = cfg.excludeTypes;
    }

    /**
     * The *````.xkt````* format version supported by this XKTLoaderPlugin.
     *
     * @type {Number}
     */
    static get XKTVersion() {
        return XKT_VERSION;
    }

    /**
     * Sets a custom data source through which the XKTLoaderPlugin can load models and metadata.
     *
     * Default value is {@link XKTDefaultDataSource}, which loads via HTTP.
     *
     * @type {Object}
     */
    set dataSource(value) {
        this._dataSource = value || new XKTDefaultDataSource();
    }

    /**
     * Gets the custom data source through which the XKTLoaderPlugin can load models and metadata.
     *
     * Default value is {@link XKTDefaultDataSource}, which loads via HTTP.
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
     * Sets the whitelist of the IFC types loaded by this XKTLoaderPlugin.
     *
     * When loading models with metadata, causes this XKTLoaderPlugin to only load objects whose types are in this
     * list. An object's type is indicated by its {@link MetaObject}'s {@link MetaObject#type}.
     *
     * Default value is ````undefined````.
     *
     * @type {String[]}
     */
    set includeTypes(value) {
        this._includeTypes = value;
    }

    /**
     * Gets the whitelist of the IFC types loaded by this XKTLoaderPlugin.
     *
     * When loading models with metadata, causes this XKTLoaderPlugin to only load objects whose types are in this
     * list. An object's type is indicated by its {@link MetaObject}'s {@link MetaObject#type}.
     *
     * Default value is ````undefined````.
     *
     * @type {String[]}
     */
    get includeTypes() {
        return this._includeTypes;
    }

    /**
     * Sets the blacklist of IFC types that are never loaded by this XKTLoaderPlugin.
     *
     * When loading models with metadata, causes this XKTLoaderPlugin to **not** load objects whose types are in this
     * list. An object's type is indicated by its {@link MetaObject}'s {@link MetaObject#type}.
     *
     * Default value is ````undefined````.
     *
     * @type {String[]}
     */
    set excludeTypes(value) {
        this._excludeTypes = value;
    }

    /**
     * Gets the blacklist of IFC types that are never loaded by this XKTLoaderPlugin.
     *
     * When loading models with metadata, causes this XKTLoaderPlugin to **not** load objects whose types are in this
     * list. An object's type is indicated by its {@link MetaObject}'s {@link MetaObject#type}.
     *
     * Default value is ````undefined````.
     *
     * @type {String[]}
     */
    get excludeTypes() {
        return this._excludeTypes;
    }

    /**
     * Loads a .xkt model into this XKTLoaderPlugin's {@link Viewer}.
     *
     * @param {*} params Loading parameters.
     * @param {String} [params.id] ID to assign to the root {@link Entity#id}, unique among all components in the Viewer's {@link Scene}, generated automatically by default.
     * @param {String} [params.src] Path to a *````.xkt````* file, as an alternative to the ````xkt```` parameter.
     * @param {ArrayBuffer} [params.xkt] The *````.xkt````* file data, as an alternative to the ````src```` parameter.
     * @param {String} [params.metaModelSrc] Path to an optional metadata file, as an alternative to the ````metaModelData```` parameter (see user guide: [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {*} [params.metaModelData] JSON model metadata, as an alternative to the ````metaModelSrc```` parameter (see user guide: [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {{String:Object}} [params.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object. Default value is {@link IFCObjectDefaults}.
     * @param {String[]} [params.includeTypes] When loading metadata, only loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     * @param {String[]} [params.excludeTypes] When loading metadata, never loads objects that have {@link MetaObject}s with {@link MetaObject#type} values in this list.
     * @param {Boolean} [params.edges=false] Whether or not xeokit renders the model with edges emphasized.
     * @param {Number[]} [params.position=[0,0,0]] The model World-space 3D position.
     * @param {Number[]} [params.scale=[1,1,1]] The model's World-space scale.
     * @param {Number[]} [params.rotation=[0,0,0]] The model's World-space rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [params.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]] The model's world transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Boolean} [params.edges=false] Indicates if the model's edges are initially emphasized.
     * @returns {Entity} Entity representing the model, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}.
     */
    load(params = {}) {

        if (params.id && this.viewer.scene.components[params.id]) {
            this.error("Component with this ID already exists in viewer: " + params.id + " - will autogenerate this ID");
            delete params.id;
        }

        const performanceModel = new PerformanceModel(this.viewer.scene, utils.apply(params, {
            isModel: true,
            preCompressed: true
        }));

        const modelId = performanceModel.id;  // In case ID was auto-generated

        if (!params.src && !params.xkt) {
            this.error("load() param expected: src or xkt");
            return performanceModel; // Return new empty model
        }

        const options = {};

        if (params.metaModelSrc || params.metaModelData) {

            const includeTypes = params.includeTypes || this._includeTypes;
            const excludeTypes = params.excludeTypes || this._excludeTypes;
            const objectDefaults = params.objectDefaults || this._objectDefaults;

            if (includeTypes) {
                options.includeTypesMap = {};
                for (let i = 0, len = includeTypes.length; i < len; i++) {
                    options.includeTypesMap[includeTypes[i]] = true;
                }
            }

            if (excludeTypes) {
                options.excludeTypesMap = {};
                for (let i = 0, len = excludeTypes.length; i < len; i++) {
                    options.excludeTypesMap[excludeTypes[i]] = true;
                }
            }

            if (objectDefaults) {
                options.objectDefaults = objectDefaults;
            }

            const processMetaModelData = (metaModelData) => {

                this.viewer.metaScene.createMetaModel(modelId, metaModelData, {
                    includeTypes: includeTypes,
                    excludeTypes: excludeTypes
                });

                this.viewer.scene.canvas.spinner.processes--;

                if (params.src) {
                    this._loadModel(params.src, params, options, performanceModel);

                } else {
                    this._parseModel(params.xkt, params, options, performanceModel);
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

            if (params.src) {
                this._loadModel(params.src, params, options, performanceModel);

            } else {
                this._parseModel(params.xkt, params, options, performanceModel);
            }
        }

        performanceModel.once("destroyed", () => {
            this.viewer.metaScene.destroyMetaModel(modelId);
        });

        return performanceModel;
    }

    _loadModel(src, params, options, performanceModel) {
        const spinner = this.viewer.scene.canvas.spinner;
        spinner.processes++;
        this._dataSource.getXKT(params.src, (arrayBuffer) => {
                this._parseModel(arrayBuffer, params, options, performanceModel);
                spinner.processes--;
            },
            (errMsg) => {
                spinner.processes--;
                this.error(errMsg);
                performanceModel.fire("error", errMsg);
            });
    }

    _parseModel(arrayBuffer, params, options, performanceModel) {
        const deflatedData = this._extractData(arrayBuffer);
        if (!deflatedData) { // Error
            return;
        }
        const inflatedData = this._inflateData(deflatedData);
        this._loadDataIntoModel(inflatedData, options, performanceModel);
    }

    _extractData(arrayBuffer) {
        const dataView = new DataView(arrayBuffer);
        const dataArray = new Uint8Array(arrayBuffer);
        const xktVersion = dataView.getUint32(0, true);
        if (xktVersion > XKT_VERSION) {
            this.error("Incompatible .XKT file version; this XKTLoaderPlugin supports versions <= V" + XKT_VERSION);
            return;
        }
        const numElements = dataView.getUint32(4, true);
        const elements = [];
        let byteOffset = (numElements + 2) * 4;
        for (let i = 0; i < numElements; i++) {
            const elementSize = dataView.getUint32((i + 2) * 4, true);
            elements.push(dataArray.subarray(byteOffset, byteOffset + elementSize));
            byteOffset += elementSize;
        }
        if (xktVersion >= 2) {
            return {
                xktVersion: xktVersion,
                positions: elements[0],
                normals: elements[1],
                indices: elements[2],
                edgeIndices: elements[3],
                meshPositions: elements[4],
                meshIndices: elements[5],
                meshEdgesIndices: elements[6],
                meshColors: elements[7],
                entityIDs: elements[8],
                entityMeshes: elements[9],
                entityIsObjects: elements[10],
                positionsDecodeMatrix: elements[11],
                entityMeshIds: elements[12],
                entityMatrices: elements[13],
                entityUsesInstancing: elements[14],
            };
        }
        return { // XKT version < 2
            xktVersion: xktVersion,
            positions: elements[0],
            normals: elements[1],
            indices: elements[2],
            edgeIndices: elements[3],
            meshPositions: elements[4],
            meshIndices: elements[5],
            meshEdgesIndices: elements[6],
            meshColors: elements[7],
            entityIDs: elements[8],
            entityMeshes: elements[9],
            entityIsObjects: elements[10],
            positionsDecodeMatrix: elements[11]
        };
    }

    _inflateData(deflatedData) {
        if (deflatedData.xktVersion >= 2) {
            return {
                xktVersion: deflatedData.xktVersion,
                positions: new Uint16Array(pako.inflate(deflatedData.positions).buffer),
                normals: new Int8Array(pako.inflate(deflatedData.normals).buffer),
                indices: new Uint32Array(pako.inflate(deflatedData.indices).buffer),
                edgeIndices: new Uint32Array(pako.inflate(deflatedData.edgeIndices).buffer),
                meshPositions: new Uint32Array(pako.inflate(deflatedData.meshPositions).buffer),
                meshIndices: new Uint32Array(pako.inflate(deflatedData.meshIndices).buffer),
                meshEdgesIndices: new Uint32Array(pako.inflate(deflatedData.meshEdgesIndices).buffer),
                meshColors: new Uint8Array(pako.inflate(deflatedData.meshColors).buffer),
                entityIDs: pako.inflate(deflatedData.entityIDs, {to: 'string'}),
                entityMeshes: new Uint32Array(pako.inflate(deflatedData.entityMeshes).buffer),
                entityIsObjects: new Uint8Array(pako.inflate(deflatedData.entityIsObjects).buffer),
                positionsDecodeMatrix: new Float32Array(pako.inflate(deflatedData.positionsDecodeMatrix).buffer),
                entityMeshIds: new Uint32Array(pako.inflate(deflatedData.entityMeshIds).buffer),
                entityMatrices: new Float32Array(pako.inflate(deflatedData.entityMatrices).buffer),
                entityUsesInstancing: new Uint8Array(pako.inflate(deflatedData.entityUsesInstancing).buffer),
            };
        }
        return { // XKT version < 2
            xktVersion: deflatedData.xktVersion,
            positions: new Uint16Array(pako.inflate(deflatedData.positions).buffer),
            normals: new Int8Array(pako.inflate(deflatedData.normals).buffer),
            indices: new Uint32Array(pako.inflate(deflatedData.indices).buffer),
            edgeIndices: new Uint32Array(pako.inflate(deflatedData.edgeIndices).buffer),
            meshPositions: new Uint32Array(pako.inflate(deflatedData.meshPositions).buffer),
            meshIndices: new Uint32Array(pako.inflate(deflatedData.meshIndices).buffer),
            meshEdgesIndices: new Uint32Array(pako.inflate(deflatedData.meshEdgesIndices).buffer),
            meshColors: new Uint8Array(pako.inflate(deflatedData.meshColors).buffer),
            entityIDs: pako.inflate(deflatedData.entityIDs, {to: 'string'}),
            entityMeshes: new Uint32Array(pako.inflate(deflatedData.entityMeshes).buffer),
            entityIsObjects: new Uint8Array(pako.inflate(deflatedData.entityIsObjects).buffer),
            positionsDecodeMatrix: new Float32Array(pako.inflate(deflatedData.positionsDecodeMatrix).buffer)
        };
    }

    _loadDataIntoModel(inflatedData, options, performanceModel) {

        if (inflatedData.xktVersion >= 2) {

            const positions = inflatedData.positions;
            const normals = inflatedData.normals;
            const indices = inflatedData.indices;
            const edgeIndices = inflatedData.edgeIndices;
            const meshPositions = inflatedData.meshPositions;
            const meshIndices = inflatedData.meshIndices;
            const meshEdgesIndices = inflatedData.meshEdgesIndices;
            const meshColors = inflatedData.meshColors;
            const entityIDs = JSON.parse(inflatedData.entityIDs);
            const entityMeshes = inflatedData.entityMeshes;
            const entityIsObjects = inflatedData.entityIsObjects;
            const entityMeshIds = inflatedData.entityMeshIds;
            const entityMatrices = inflatedData.entityMatrices;
            const entityUsesInstancing = inflatedData.entityUsesInstancing;

            const numMeshes = meshPositions.length;
            const numEntities = entityMeshes.length;

            const _alreadyCreatedGeometries = {};

            for (let i = 0; i < numEntities; i++) {

                const entityId = entityIDs [i];
                const metaObject = this.viewer.metaScene.metaObjects[entityId];
                const entityDefaults = {};
                const meshDefaults = {};
                const entityMatrix = entityMatrices.subarray((i * 16), (i * 16) + 16);

                if (metaObject) {

                    if (options.excludeTypesMap && metaObject.type && options.excludeTypesMap[metaObject.type]) {
                        continue;
                    }

                    if (options.includeTypesMap && metaObject.type && (!options.includeTypesMap[metaObject.type])) {
                        continue;
                    }

                    const props = options.objectDefaults ? options.objectDefaults[metaObject.type || "DEFAULT"] : null;

                    if (props) {
                        if (props.visible === false) {
                            entityDefaults.visible = false;
                        }
                        if (props.pickable === false) {
                            entityDefaults.pickable = false;
                        }
                        if (props.colorize) {
                            meshDefaults.color = props.colorize;
                        }
                        if (props.opacity !== undefined && props.opacity !== null) {
                            meshDefaults.opacity = props.opacity;
                        }
                    }
                } else {
                    //this.warn("metaobject not found for entity: " + entityId);
                }

                const lastEntity = (i === numEntities - 1);

                const meshIds = [];

                for (let j = entityMeshes [i], jlen = lastEntity ? entityMeshIds.length : entityMeshes [i + 1]; j < jlen; j++) {
                    var jj = entityMeshIds [j];

                    const lastMesh = (jj === (numMeshes - 1));
                    const meshId = entityId + ".mesh." + jj;

                    const color = decompressColor(meshColors.subarray((jj * 4), (jj * 4) + 3));
                    const opacity = meshColors[(jj * 4) + 3] / 255.0;

                    var tmpPositions = positions.subarray(meshPositions [jj], lastMesh ? positions.length : meshPositions [jj + 1]);
                    var tmpNormals = normals.subarray(meshPositions [jj], lastMesh ? positions.length : meshPositions [jj + 1]);
                    var tmpIndices = indices.subarray(meshIndices [jj], lastMesh ? indices.length : meshIndices [jj + 1]);
                    var tmpEdgeIndices = edgeIndices.subarray(meshEdgesIndices [jj], lastMesh ? edgeIndices.length : meshEdgesIndices [jj + 1]);

                    if (entityUsesInstancing [i] === 1) {
                        var geometryId = "geometry." + jj;

                        if (!(geometryId in _alreadyCreatedGeometries)) {

                            performanceModel.createGeometry({
                                id: geometryId,
                                positions: tmpPositions,
                                normals: tmpNormals,
                                indices: tmpIndices,
                                edgeIndices: tmpEdgeIndices,
                                primitive: "triangles",
                                positionsDecodeMatrix: inflatedData.positionsDecodeMatrix,
                            });

                            _alreadyCreatedGeometries [geometryId] = true;
                        }

                        performanceModel.createMesh(utils.apply(meshDefaults,{
                            id: meshId,
                            color: color,
                            opacity: opacity,
                            matrix: entityMatrix,
                            geometryId: geometryId,
                        }));

                        meshIds.push(meshId);
                    } else {
                        performanceModel.createMesh(utils.apply(meshDefaults, {
                            id: meshId,
                            primitive: "triangles",
                            positions: tmpPositions,
                            normals: tmpNormals,
                            indices: tmpIndices,
                            edgeIndices: tmpEdgeIndices,
                            positionsDecodeMatrix: inflatedData.positionsDecodeMatrix,
                            color: color,
                            opacity: opacity
                        }));

                        meshIds.push(meshId);
                    }
                }

                if (meshIds.length) {
                    performanceModel.createEntity(utils.apply(entityDefaults, {
                        id: entityId,
                        isObject: (entityIsObjects [i] === 1),
                        meshIds: meshIds
                    }));
                }
            }

        } else { // XKT version <= 2

            const positions = inflatedData.positions;
            const normals = inflatedData.normals;
            const indices = inflatedData.indices;
            const edgeIndices = inflatedData.edgeIndices;
            const meshPositions = inflatedData.meshPositions;
            const meshIndices = inflatedData.meshIndices;
            const meshEdgesIndices = inflatedData.meshEdgesIndices;
            const meshColors = inflatedData.meshColors;
            const entityIDs = JSON.parse(inflatedData.entityIDs);
            const entityMeshes = inflatedData.entityMeshes;
            const entityIsObjects = inflatedData.entityIsObjects;
            const numMeshes = meshPositions.length;
            const numEntities = entityMeshes.length;

            for (let i = 0; i < numEntities; i++) {

                const entityId = entityIDs [i];
                const metaObject = this.viewer.metaScene.metaObjects[entityId];
                const entityDefaults = {};
                const meshDefaults = {};

                if (metaObject) {

                    if (options.excludeTypesMap && metaObject.type && options.excludeTypesMap[metaObject.type]) {
                        continue;
                    }

                    if (options.includeTypesMap && metaObject.type && (!options.includeTypesMap[metaObject.type])) {
                        continue;
                    }

                    const props = options.objectDefaults ? options.objectDefaults[metaObject.type || "DEFAULT"] : null;

                    if (props) {
                        if (props.visible === false) {
                            entityDefaults.visible = false;
                        }
                        if (props.pickable === false) {
                            entityDefaults.pickable = false;
                        }
                        if (props.colorize) {
                            meshDefaults.color = props.colorize;
                        }
                        if (props.opacity !== undefined && props.opacity !== null) {
                            meshDefaults.opacity = props.opacity;
                        }
                    }
                } else {
                    //    this.warn("metaobject not found for entity: " + entityId);
                }

                const lastEntity = (i === numEntities - 1);
                const meshIds = [];

                for (let j = entityMeshes [i], jlen = lastEntity ? entityMeshes.length : entityMeshes [i + 1]; j < jlen; j++) {

                    const lastMesh = (j === (numMeshes - 1));
                    const meshId = entityId + ".mesh." + j;

                    const color = decompressColor(meshColors.subarray((j * 4), (j * 4) + 3));
                    const opacity = meshColors[(j * 4) + 3] / 255.0;

                    performanceModel.createMesh(utils.apply(meshDefaults, {
                        id: meshId,
                        primitive: "triangles",
                        positions: positions.subarray(meshPositions [j], lastMesh ? positions.length : meshPositions [j + 1]),
                        normals: normals.subarray(meshPositions [j], lastMesh ? positions.length : meshPositions [j + 1]),
                        indices: indices.subarray(meshIndices [j], lastMesh ? indices.length : meshIndices [j + 1]),
                        edgeIndices: edgeIndices.subarray(meshEdgesIndices [j], lastMesh ? edgeIndices.length : meshEdgesIndices [j + 1]),
                        positionsDecodeMatrix: inflatedData.positionsDecodeMatrix,
                        color: color,
                        opacity: opacity
                    }));

                    meshIds.push(meshId);
                }

                performanceModel.createEntity(utils.apply(entityDefaults, {
                    id: entityId,
                    isObject: (entityIsObjects [i] === 1),
                    meshIds: meshIds
                }));
            }
        }

        performanceModel.finalize();

        performanceModel.scene.once("tick", () => {
            performanceModel.scene.fire("modelLoaded", performanceModel.id); // FIXME: Assumes listeners know order of these two events
            performanceModel.fire("loaded", true, true);
        });
    }
}

export {XKTLoaderPlugin}
