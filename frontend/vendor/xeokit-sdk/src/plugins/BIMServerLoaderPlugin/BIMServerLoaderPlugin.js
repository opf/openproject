import {Plugin} from "../../viewer/Plugin.js";
import {PerformanceModel} from "../../viewer/scene/PerformanceModel/PerformanceModel.js";

import {BIMServerPerformanceGeometryLoader} from "./lib/BIMServerPerformanceGeometryLoader.js";
import {loadBIMServerMetaModel} from "./lib/loadBIMServerMetaModel.js";
import {IFCObjectDefaults} from "../../viewer/metadata/IFCObjectDefaults.js";
import {utils} from "../../viewer/scene/utils.js";

/**
 * {@link Viewer} plugin that loads models from a [BIMServer](http://bimserver.org).
 *
 * Tested with BIMServer v1.5.120 and IFC schema ifc2x3tc1.
 *
 * * For each model loaded, creates a tree of {@link Entity}s within its {@link Viewer}'s {@link Scene}, with the root {@link Entity} representing the model and sub-{@link Entity}s representing objects within the model.
 * * The root {@link Entity} will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}.
 * * Each sub-{@link Entity} that represents an object will have {@link Entity#isObject} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#objects}.
 * * When loading a model, we can specify a World-space transformation to position and orient it, along with initial rendering states to recursively apply to the Entity tree.
 *
 * ## Usage
 *
 * In the example below, we'll load the latest revision of a project's model from BIMSserver. We'll assume that we have a BIMServer
 * instance running and serving requests on port 8082, with a model loaded for project ID ````131073````.
 *
 * Since xeokit's default World "up" direction is +Y, while the model's "up" is +Z, we'll rotate the
 * model 90 degrees about the X-axis as we load it. Note that we could also instead configure xeokit to use +Z as "up".
 *
 * A BIMServerLoaderPlugin is configured with a BIMServerClient, which provides a client-side facade through which
 * we can issue RPC calls to the BIMServer Service Interface. The BIMServerLoaderPlugin makes RPC calls through that
 * to download the model and it's IFC metadata.
 *
 * Note that BIMServerLoaderPlugin works with BIMServer V1.5.120 or later.
 *
 * Read more about this example in the user guide on [Viewing Models from BIMServer](https://github.com/xeokit/xeokit-sdk/wiki/Viewing-Models-from-BIMServer).
 *
 *  [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#BIMServer_Schependomlaan)]
 *
 * ````javascript
 * import {Viewer} from "./../src/viewer/Viewer.js";
 * import BimServerClient from "./../src/viewer/utils/BIMServerClient/bimserverclient.js"
 * import {BIMServerLoaderPlugin} from "./../src/plugins/BIMServerLoaderPlugin/BIMServerLoaderPlugin.js";
 *
 * const bimServerAddress = "https://xeokit.cleverapps.io/";
 * const username = "kevin.flynn@en.com";
 * const password = "secretPassword";
 * const poid = 196609;
 *
 * // Create a xeokit Viewer
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * // Create a BimServerClient
 * const bimServerClient = new BimServerClient(bimServerAddress);
 *
 * // Add a BIMServerLoaderPlugin to the Viewer, configured with the BIMServerClient
 * const bimServerLoader = new BIMServerLoaderPlugin(viewer, {
 *     bimServerClient: bimServerClient
 * });
 *
 * // Initialize the BIMServer client
 * bimServerClient.init(() => {
 *
 *     // Login to BIMServer
 *     bimServerClient.login(username, password, () => {
 *
 *         // Query a project by ID
 *         bimServerClient.call("ServiceInterface", "getProjectByPoid", {
 *             poid: poid
 *         }, (project) => {
 *
 *             // From the project info returned by BIMServerClient, we'll get the ID of the latest
 *             // model revision and the version of the IFC schema to which the model conforms.
 *
 *             // Load the latest revision of the project
 *
 *             const roid = project.lastRevisionId;
 *             const schema = project.schema;
 *
 *             var model = bimServerLoader.load({ // Returns an Entity
 *                 id: "myModel",
 *                 poid: poid,                      // Project ID
 *                 roid: roid,                      // Revision ID
 *                 schema: schema,                  // Schema version
 *                 edges: true,                     // Render with emphasized edges (default is false)
 *                 lambertMaterial: true,          // Lambertian flat-shading instead of default Blinn/Phong
 *                 scale: [0.001, 0.001, 0.001],    // Shrink the model a bit
 *                 rotation: [-90, 0, 0]            // Rotate model for World +Y "up"
 *             });
 *
 *             const scene = viewer.scene;  // xeokit.Scene
 *             const camera = scene.camera; // xeokit.Camera
 *
 *             model.on("loaded", () => { // When loaded, fit camera and start orbiting
 *                 camera.orbitPitch(20);
 *                 viewer.cameraFlight.flyTo(model);
 *                 scene.on("tick", () => {
 *                     camera.orbitYaw(0.3);
 *                 })
 *
 *                 // We can find the model Entity by ID
 *                 model = viewer.scene.models["myModel"];
 *
 *                 // To destroy the model, call destroy() on the model Entity
 *                 model.destroy();
 *             });
 *
 *             model.on("error", function(errMsg}
 *                  console.error("Error while loading: " + errMsg);
 *             });
 *         });
 *     });
 * });
 * ````
 * @class BIMServerLoaderPluginOLD
 */
class BIMServerLoaderPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="BIMServerModels"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Object} cfg.bimServerClient A BIMServer client API instance.
     * @param {{String:Object}} [cfg.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object. Default value for this parameter is {@link IFCObjectDefaults}.
     */
    constructor(viewer, cfg) {

        super("BIMServerModels", viewer, cfg);

        /**
         * Version of BIMServer supported by this plugin.
         * @type {string}
         */
        this.BIMSERVER_VERSION = "1.5";

        if (!cfg.bimServerClient) {
            this.error("Config expected: bimServerClient");
        }

        /**
         * The BIMServer API.
         * @type {BIMServerClient}
         */
        this.bimServerClient = cfg.bimServerClient;

        /**
         * IFC types that are hidden by default.
         * @type {{IfcOpeningElement: boolean, IfcSpace: boolean}}
         */
        this.hiddenTypes = {
            "IfcOpeningElement": true,
            "IfcSpace": true
        };

        this.objectDefaults = cfg.objectDefaults;
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
     * Loads a model from a BIMServer into this BIMServerLoaderPlugin's {@link Viewer}.
     *
     * Creates a tree of {@link Entity}s that represents the model.
     *
     * The root {@link Entity} will have {@link Entity#isModel} set true to indicate that it represents a model, and will therefore be registered in {@link Scene#models}.
     *
     * @param {Object} params Loading parameters.
     * @param {String} [params.id] ID to assign to the root {@link Entity#id}, unique among all components in the Viewer's {@link Scene}, generated automatically by default.
     * @param {Number} params.poid ID of the model's project within BIMServer.
     * @param {Number} params.roid ID of the model's revision within BIMServer. See the class example for how to query the latest project revision ID via the BIMServer client API.
     * @param {Number} params.schema The model's IFC schema. See the class example for how to query the project's schema via the BIMServer client API.
     * @param {{String:Object}} [params.objectDefaults] Map of initial default states for each loaded {@link Entity} that represents an object. Default value for this parameter is {@link IFCObjectDefaults}.
     * @param {Boolean} [params.edges=false] Whether or not xeokit renders the model with edges emphasized.
     * @param {Number[]} [params.position=[0,0,0]] The model World-space 3D position.
     * @param {Number[]} [params.scale=[1,1,1]] The model's World-space scale.
     * @param {Number[]} [params.rotation=[0,0,0]] The model's World-space rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [params.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]] The model's world transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Boolean} [params.backfaces=false] When true, allows visible backfaces, wherever specified. When false, ignores backfaces.
     * @param {Number} [params.edgeThreshold=20] When xraying, highlighting, selecting or edging, this is the threshold angle between normals of adjacent triangles, below which their shared wireframe edge is not drawn.
     * @returns {Entity} Root Entity representing the loaded model. The Entity will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}
     */
    load(params) {

        const self = this;

        params = params || {};

        if (params.id && this.viewer.scene.components[params.id]) {
            this.error("Component with this ID already exists in viewer: " + params.id + " - will autogenerate this ID");
            delete params.id;
        }

        const poid = params.poid;
        const roid = params.roid;
        const schema = params.schema;
        const viewer = this.viewer;
        const scene = viewer.scene;
        const bimServerClient = this.bimServerClient;
        const objectDefaults = params.objectDefaults || this._objectDefaults || IFCObjectDefaults;

        const performanceModel = new PerformanceModel(scene, params);
        const modelId = performanceModel.id;

        var onTick;

        if (!poid) {
            this.error("load() param expected: poid");
            return performanceModel; // TODO: Finalize?
        }

        if (!roid) {
            this.error("load() param expected: roid");
            return performanceModel; // TODO: Finalize?
        }

        if (!schema) {
            this.error("load() param expected: schema");
            return performanceModel; // TODO: Finalize?
        }

        const logging = !!params.logging;

        scene.canvas.spinner.processes++;

        bimServerClient.getModel(poid, roid, schema, false, bimServerClientModel => {  // TODO: Preload not necessary combined with the bruteforce tree

            loadBIMServerMetaModel(viewer, modelId, poid, roid, schema, bimServerClientModel).then(function () {

                performanceModel.once("destroyed", function () {
                    viewer.metaScene.destroyMetaModel(modelId);
                });

                const oids = [];
                const oidToGuid = {};
                const guidToOid = {};

                const visit = metaObject => {
                    oids[metaObject.external.gid] = metaObject.external.extId;
                    oidToGuid[metaObject.external.extId] = metaObject.id;
                    guidToOid[metaObject.id] = metaObject.external.extId;
                    for (let i = 0; i < (metaObject.children || []).length; ++i) {
                        visit(metaObject.children[i]);
                    }
                };

                const metaModel = viewer.metaScene.metaModels[modelId];
                const rootMetaObject = metaModel.rootMetaObject;

                visit(rootMetaObject);

                const loader = new BIMServerPerformanceGeometryLoader(bimServerClient, bimServerClientModel, roid, null, {

                    objectDefaults: objectDefaults,

                    log: function (msg) {
                        if (logging) {
                            self.log(msg);
                        }
                    },

                    error: function (msg) {
                        self.error(msg);
                        performanceModel.fire("error", msg);
                    },

                    warn: function (msg) {
                        self.warn(msg);
                    },

                    gotModelBoundary: function (boundary) {

                        const xmin = boundary[0];
                        const ymin = boundary[1];
                        const zmin = boundary[2];
                        const xmax = boundary[3];
                        const ymax = boundary[4];
                        const zmax = boundary[5];

                        const diagonal = Math.sqrt(
                            Math.pow(xmax - xmin, 2) +
                            Math.pow(ymax - ymin, 2) +
                            Math.pow(zmax - zmin, 2));

                        const scale = 100 / diagonal;

                        const center = [
                            scale * ((xmax + xmin) / 2),
                            scale * ((ymax + ymin) / 2),
                            scale * ((zmax + zmin) / 2)
                        ];

                        // TODO

                        //o.viewer.setScale(scale); // Temporary until we find a better scaling system.
                    },

                    createGeometry: function (geometryDataId, positions, normals, indices) {
                        const geometryId = `${modelId}.${geometryDataId}`;
                        performanceModel.createGeometry({
                            id: geometryId,
                            primitive: "triangles",
                            positions: positions,
                            normals: normals,
                            indices: indices
                        });
                    },

                    createMeshInstancingGeometry: function (geometryDataId, matrix, color, opacity) {
                        const meshId = `${modelId}.${geometryDataId}.mesh`;
                        const geometryId = `${modelId}.${geometryDataId}`;
                        performanceModel.createMesh({
                            id: meshId,
                            geometryId: geometryId,
                            matrix: matrix,
                            color: color,
                            opacity: opacity
                        });
                    },

                    createMeshSpecifyingGeometry: function (geometryDataId, positions, normals, indices, matrix, color, opacity) {
                        const meshId = `${modelId}.${geometryDataId}.mesh`;
                        performanceModel.createMesh({
                            id: meshId,
                            primitive: "triangles",
                            positions: positions,
                            normals: normals,
                            indices: indices,
                            matrix: matrix,
                            color: color,
                            opacity: opacity
                        });
                    },

                    createEntity(id, geometryDataId, ifcType) { // Pass in color to set transparency
                        id = oidToGuid[id];
                        const meshId = `${modelId}.${geometryDataId}.mesh`;
                        if (scene.objects[id]) {
                            self.error(`Can't create object - object with id ${id} already exists`);
                            return;
                        }
                        if (scene.components[id]) {
                            self.error(`Can't create object - scene component with this ID already exists: ${id}`);
                            return;
                        }
                        ifcType = ifcType || "DEFAULT";
                        const props = objectDefaults[ifcType] || {};
                        performanceModel.createEntity(utils.apply(props, {
                            id: id,
                            isObject: true,
                            meshIds: [meshId]
                        }));
                    }
                });

                loader.addProgressListener((progress, nrObjectsRead, totalNrObjects) => {
                    if (progress === "start") {
                        if (logging) {
                            self.log("Started loading geometries");
                        }
                    } else if (progress === "done") {
                        if (logging) {
                            self.log(`Finished loading geometries (${totalNrObjects} objects received)`);
                        }

                        viewer.scene.off(onTick);

                        scene.canvas.spinner.processes--;

                        performanceModel.finalize();
                        performanceModel.fire("loaded");
                    }
                });

                loader.setLoadOids(oids); // TODO: Why do we do this?

                onTick = viewer.scene.on("tick", () => {
                    loader.process();
                });

                loader.start();
            });
        });

        return performanceModel;
    }

    /**
     * Destroys this BIMServerLoaderPlugin.
     */
    destroy() {
        super.destroy();
    }
}

export {BIMServerLoaderPlugin}
