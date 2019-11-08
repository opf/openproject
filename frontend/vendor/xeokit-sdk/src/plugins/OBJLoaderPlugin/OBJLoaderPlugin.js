import {Plugin} from "../../viewer/Plugin.js";
import {Node} from "../../viewer/scene/nodes/Node.js";
import {utils} from "../../viewer/scene/utils.js";
import {OBJLoader} from "./OBJLoader.js";

/**
 * {@link Viewer} plugin that loads models from [OBJ](https://en.wikipedia.org/wiki/Wavefront_.obj_file) files.
 *
 * * Creates an {@link Entity} representing each model it loads, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}.
 * * Creates an {@link Entity} for each object within the model, which will have {@link Entity#isObject} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#objects}.
 * * When loading, can set the World-space position, scale and rotation of each model within World space, along with initial properties for all the model's {@link Entity}s.
 *
 * ## Metadata
 *
 * OBJLoaderPlugin can also load an accompanying JSON metadata file with each model, which creates a {@link MetaModel} corresponding
 * to the model {@link Entity} and a {@link MetaObject} corresponding to each object {@link Entity}.
 *
 * Each {@link MetaObject} has a {@link MetaObject#type}, which indicates the classification of its corresponding {@link Entity}. When loading
 * metadata, we can also provide GLTFModelLoaderPlugin with a custom lookup table of initial values to set on the properties of each type of {@link Entity}. By default, OBJLoaderPlugin
 * uses its own map of standard default colors, visibilities and opacities for IFC element types.

 *
 * ## Usage
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#loading_OBJ_SportsCar)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {OBJLoaderPlugin} from "../src/plugins/OBJLoaderPlugin/OBJLoaderPlugin.js";
 *
 * // Create a xeokit Viewer and arrange the camera
 * const viewer = new Viewer({
 *      canvasId: "myCanvas",
 *      transparent: true
 * });
 *
 * viewer.camera.orbitPitch(20);
 *
 * // Add an OBJLoaderPlugin to the Viewer
 * const objLoader = new OBJLoaderPlugin(viewer);
 *
 * // Load an OBJ model
 * var model = objLoader.load({ // Model is an Entity
 *      id: "myModel",
 *      src: "./models/obj/sportsCar/sportsCar.obj",
 *      edges: true
 * });
 *
 * // When the model has loaded, fit it to view
 * model.on("loaded", () => {
 *      viewer.cameraFlight.flyTo(model);
 * })
 *
 * // Find the model Entity by ID
 * model = viewer.scene.models["myModel"];
 *
 * // Update properties of the model Entity
 * model.highlight = [1,0,0];
 *
 * // Destroy the model
 * model.destroy();
 * ````
 * @class OBJLoaderPlugin
 */
class OBJLoaderPlugin extends Plugin {

    /**
     * @constructor
     *
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg Plugin configuration.
     * @param {String} [cfg.id="OBJLoader"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     */
    constructor(viewer, cfg) {

        super("OBJLoader", viewer, cfg);

        /**
         * @private
         */
        this._loader = new OBJLoader();
    }

    /**
     * Loads an OBJ model from a file into this OBJLoader's {@link Viewer}.
     *
     * @param {*} params  Loading parameters.
     * @param {String} params.id ID to assign to the model's root {@link Entity}, unique among all components in the Viewer's {@link Scene}.
     * @param {String} params.src Path to an OBJ file.
     * @param {String} [params.metaModelSrc] Path to an optional metadata file (see: [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {Number[]} [params.position=[0,0,0]] The model World-space 3D position.
     * @param {Number[]} [params.scale=[1,1,1]] The model's World-space scale.
     * @param {Number[]} [params.rotation=[0,0,0]] The model's World-space rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [params.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]] The model's world transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Number} [params.edgeThreshold=20] When xraying, highlighting, selecting or edging, this is the threshold angle between normals of adjacent triangles, below which their shared wireframe edge is not drawn.
     * @returns {Entity} Entity representing the model, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}
     */
    load(params = {}) {

        if (params.id && this.viewer.scene.components[params.id]) {
            this.error("Component with this ID already exists in viewer: " + params.id + " - will autogenerate this ID");
            delete params.id;
        }

        var modelNode = new Node(this.viewer.scene, utils.apply(params, {
            isModel: true
        }));

        const modelId = modelNode.id;  // In case ID was auto-generated
        const src = params.src;

        if (!src) {
            this.error("load() param expected: src");
            return modelNode;
        }

        if (params.metaModelSrc) {
            const metaModelSrc = params.metaModelSrc;
            utils.loadJSON(metaModelSrc,
                (modelMetadata) => {
                    this.viewer.metaScene.createMetaModel(modelId, modelMetadata);
                    this._loader.load(modelNode, src, params);
                },
                (errMsg) => {
                    this.error(`load(): Failed to load model modelMetadata for model '${modelId} from  '${metaModelSrc}' - ${errMsg}`);
                });
        } else {
            this._loader.load(modelNode, src, params);
        }

        modelNode.once("destroyed", () => {
            this.viewer.metaScene.destroyMetaModel(modelId);
        });

        return modelNode;
    }

    /**
     * Destroys this OBJLoaderPlugin.
     */
    destroy() {
        super.destroy();
    }
}

export {OBJLoaderPlugin}