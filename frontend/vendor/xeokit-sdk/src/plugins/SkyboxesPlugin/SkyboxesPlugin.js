import {Plugin} from "../../viewer/Plugin.js";
import {Skybox} from "../../../xeokit/skybox/skybox.js"

/**
 * {@link Viewer} plugin that manages skyboxes
 *
 * @example
 *
 * // Create a Viewer
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * // Add a GLTFModelsPlugin
 * var gltfLoaderPlugin = new GLTFModelsPlugin(viewer, {
 *     id: "GLTFModels"  // Default value
 * });
 *
 * // Add a SkyboxesPlugin
 * var skyboxesPlugin = new SkyboxesPlugin(viewer, {
 *     id: "Skyboxes" // Default value
 * });
 *
 * // Load a glTF model
 * const model = gltfLoaderPlugin.load({
 *     id: "myModel",
 *     src: "./models/gltf/mygltfmodel.gltf"
 * });
 *
 * // Create three directional World-space lights. "World" means that they will appear as if part
 * // of the world, instead of "View", where they move with the user's head.
 *
 * skyboxesPlugin.createLight({
 *     id: "keyLight",
 *     dir: [0.8, -0.6, -0.8],
 *     color: [1.0, 0.3, 0.3],
 *     intensity: 1.0,
 *     space: "world"
 * });
 *
 * skyboxesPlugin.createLight({
 *     id: "fillLight",
 *     dir: [-0.8, -0.4, -0.4],
 *     color: [0.3, 1.0, 0.3],
 *     intensity: 1.0,
 *     space: "world"
 * });
 *
 * skyboxesPlugin.createDirLight({
 *     id: "rimLight",
 *     dir: [0.2, -0.8, 0.8],
 *     color: [0.6, 0.6, 0.6],
 *     intensity: 1.0,
 *     space: "world"
 * });
 *
 * @class SkyboxesPlugin
 */
class SkyboxesPlugin extends Plugin {

    constructor(viewer) {
        super("skyboxes", viewer);
        this.skyboxes = {};
    }

    /**
     * @private
     */
    send(name, value) {
        switch (name) {
            case "clear":
                this.clear();
                break;
        }
    }

    /**
     * @private
     */
    writeBookmark(bookmark) {
        // var states = [];
        // for (var id in this.skyboxes) {
        //     if (this.skyboxes.hasOwnProperty(id)) {
        //         var skybox = this.skyboxes[id];
        //         states.push({
        //             id: id,
        //             active: skybox.active
        //         });
        //     }
        // }
        // if (states.length > 0) {
        //     (bookmark.plugins = bookmark.plugins || {}).skyboxes = states;
        // }
    }

    /**
     * @private
     */
    readBookmark(bookmark) {
        this.clear();
        // var plugins = bookmark.plugins;
        // if (plugins) {
        //     var states = plugins.skyboxes;
        //     if (states) {
        //         for (var i = 0, len = states.length; i < len; i++) {
        //             var state = states[i];
        //             this.createSkybox(state.id, state);
        //         }
        //     }
        // }
    }

    /**
     Creates a skybox.

     @param {String} id Unique ID to assign to the skybox.
     @param {Object} params Skybox configuration.
     @param {Boolean} [params.active=true] Whether the skybox plane is initially active. Only skyboxes while this is true.
     @returns {Skybox} The new skybox.
     */
    createSkybox(id, params) {
        if (this.viewer.scene.components[id]) {
            this.error("Component with this ID already exists: " + id);
            return this;
        }
        var skybox = new Skybox(this.viewer.scene, {
            id: id,
            pos: params.pos,
            dir: params.dir,
            active: true || params.active
        });
        this.skyboxes[id] = skybox;
        return skybox;
    }

    /**
     Destroys a skybox.
     @param id
     */
    destroySkybox(id) {
        var skybox = this.skyboxes[id];
        if (!skybox) {
            this.error("Skybox not found: " + id);
            return;
        }
        skybox.destroy();
    }

    /**
     Destroys all skyboxes.
     */
    clear() {
        var ids = Object.keys(this.viewer.scene.skyboxes);
        for (var i = 0, len = ids.length; i < len; i++) {
            this.destroySkybox(ids[i]);
        }
    }

    /**
     * Destroys this plugin.
     *
     * Clears skyboxes from the Viewer first.
     */
    destroy() {
        this.clear();
        super.clear();
    }
}

export {SkyboxesPlugin}
