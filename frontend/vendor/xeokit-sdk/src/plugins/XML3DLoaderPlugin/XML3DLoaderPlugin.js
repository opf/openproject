import {utils} from "../../viewer/scene/utils.js"
import {Node} from "../../viewer/scene/nodes/Node.js";
import {Plugin} from "../../viewer/Plugin.js";
import {XML3DLoader} from "./XML3DLoader.js";

/**
 * {@link Viewer} plugin that loads models from [3DXML](https://en.wikipedia.org/wiki/3DXML) files.
 *
 * * Creates an {@link Entity} representing each model it loads, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}.
 * * Creates an {@link Entity} for each object within the model, which will have {@link Entity#isObject} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#objects}.
 * * When loading, can set the World-space position, scale and rotation of each model within World space, along with initial properties for all the model's {@link Entity}s.
 *
 * Note that the name of this plugin is intentionally munged to "XML3D" because a JavaScript class name cannot begin with a numeral.
 *
 * An 3DXML model is a zip archive that bundles multiple XML files and assets. Internally, the XML3DLoaderPlugin uses the
 * [zip.js](https://gildas-lormeau.github.io/zip.js/) library to unzip them before loading. The zip.js library uses
 * [Web workers](https://www.w3.org/TR/workers/) for fast unzipping, so XML3DLoaderPlugin requires that we configure it
 * with a ````workerScriptsPath```` property specifying the directory where zip.js keeps its Web worker script. See
 * the example for how to do that.
 *
 * ## Usage
 *
 * In the example below, we'll use an XML3DLoaderPlugin to load a 3DXML model. When the model has loaded,
 * we'll use the {@link CameraFlightAnimation} to fly the {@link Camera} to look at boundary of the model. We'll
 * then get the model's {@link Entity} from the {@link Scene} and highlight the whole model.
 *
 * * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#loading_3DXML_Widget)]
 *
 * ````javascript
 * // Create a xeokit Viewer
 * const viewer = new Viewer({
 *      canvasId: "myCanvas"
 * });
 *
 * // Add an XML3DLoaderPlugin to the Viewer
 * var plugin = new XML3DLoaderPlugin(viewer, {
 *      id: "XML3DLoader",  // Default value
 *      workerScriptsPath : "../../src/plugins/XML3DLoader/zipjs/" // Path to zip.js workers dir
 * });
 *
 * // We can also get the plugin by its ID on the Viewer
 * plugin = viewer.plugins.XML3DLoader;
 *
 * // Load the 3DXML model
 * var model = plugin.load({ // Model is an Entity
 *     id: "myModel",
 *     src: "./models/xml3d/3dpreview.3dxml",
 *     scale: [0.1, 0.1, 0.1],
 *     rotate: [90, 0, 0],
 *     translate: [100,0,0],
 *     edges: true
 * });
 *
 * // When the model has loaded, fit it to view
 * model.on("loaded", function() {
 *      viewer.cameraFlight.flyTo(model);
 * });
 *
 * // Update properties of the model via the entity
 * model.highlighted = true;
 *
 * // Find the model Entity by ID
 * model = viewer.scene.models["myModel"];
 *
 * // Destroy the model
 * model.destroy();
 * ````
 *
 * @class XML3DLoaderPlugin
 */

class XML3DLoaderPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="XML3DLoader"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {String} cfg.workerScriptsPath Path to the directory that contains the
     * bundled [zip.js](https://gildas-lormeau.github.io/zip.js/) archive, which is a dependency of this plugin. This directory
     * contains the script that is used by zip.js to instantiate Web workers, which assist with unzipping the 3DXML, which is a ZIP archive.
     */
    constructor(viewer, cfg = {}) {

        super("XML3DLoader", viewer, cfg);

        if (!cfg.workerScriptsPath) {
            this.error("Config expected: workerScriptsPath");
            return
        }

        this._workerScriptsPath = cfg.workerScriptsPath;

        /**
         * @private
         */
        this._loader = new XML3DLoader(this, cfg);

        /**
         * Supported 3DXML schema versions
         * @property supportedSchemas
         * @type {string[]}
         */
        this.supportedSchemas = this._loader.supportedSchemas;
    }

    /**
     * Loads a 3DXML model from a file into this XML3DLoaderPlugin's {@link Viewer}.
     *
     * Creates a tree of {@link Entity}s within the Viewer's {@link Scene} that represents the model.
     *
     * @param {*} params  Loading parameters.
     * @param {String} params.id ID to assign to the model's root {@link Entity}, unique among all components in the Viewer's {@link Scene}.
     * @param {String} [params.src] Path to a 3DXML file.
     * @param {Boolean} [params.edges=false] Whether or not xeokit renders the {@link Entity} with edges emphasized.
     * @param {Number[]} [params.position=[0,0,0]] The model's World-space 3D position.
     * @param {Number[]} [params.scale=[1,1,1]] The model's World-space scale.
     * @param {Number[]} [params.rotation=[0,0,0]] The model's World-space rotation, as Euler angles given in degrees, for each of the X, Y and Z axis.
     * @param {Number[]} [params.matrix=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]] The model's world transform matrix. Overrides the position, scale and rotation parameters.
     * @param {Boolean} [params.backfaces=false] When true, allows visible backfaces, wherever specified in the 3DXML. When false, ignores backfaces.
     * @param {Number} [params.edgeThreshold=20] When xraying, highlighting, selecting or edging, this is the threshold angle between normals of adjacent triangles, below which their shared wireframe edge is not drawn.
     * @returns {Entity} Entity representing the model, which will have {@link Entity#isModel} set ````true```` and will be registered by {@link Entity#id} in {@link Scene#models}
     */
    load(params = {}) {

        params.workerScriptsPath = this._workerScriptsPath;

        const self = this;

        if (params.id && this.viewer.scene.components[params.id]) {
            this.error("Component with this ID already exists in viewer: " + params.id + " - will autogenerate this ID");
            delete params.id;
        }

        const modelNode = new Node(this.viewer.scene, utils.apply(params, {
            isModel: true
        }));

        const src = params.src;

        if (!src) {
            this.error("load() param expected: src");
            return modelNode; // Return new empty model
        }

        this._loader.load(this, modelNode, src, params);

        return modelNode;
    }
}

export {XML3DLoaderPlugin}