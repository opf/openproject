import {math} from "../math/math.js";
import {utils} from "../utils.js";

const color = math.vec3();

/**
 * @desc Saves and restores a snapshot of the visual state of the {@link Entity}'s that represent objects within a {@link Scene}.
 *
 * * An Entity represents an object when {@link Entity#isObject} is ````true````.
 * * Each object-Entity is registered by {@link Entity#id} in {@link Scene#objects}.
 *
 * ## Usage
 *
 * In the example below, we'll create a {@link Viewer} and use an {@link XKTLoaderPlugin} to load an ````.xkt```` model. When the model has loaded, we'll hide a couple of {@link Entity}s and save a snapshot of the visual states of all the Entitys in an ObjectsMemento. Then we'll show all the Entitys
 * again, and then we'll restore the visual states of all the Entitys again from the ObjectsMemento, which will hide those two Entitys again.
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {ObjectsMemento} from "../src/scene/mementos/ObjectsMemento.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * // Load a model
 * const xktLoader = new XKTLoaderPlugin(viewer);
 *
 * const model = xktLoader.load({
 *     id: "myModel",
 *     src: "./models/xkt/schependomlaan/schependomlaan.xkt"
 * });
 *
 * model.on("loaded", () => {
 *
 *      // Model has loaded
 *
 *      // Hide a couple of objects
 *      viewer.scene.objects["0u4wgLe6n0ABVaiXyikbkA"].visible = false;
 *      viewer.scene.objects["3u4wgLe3n0AXVaiXyikbYO"].visible = false;
 *
 *      // Save memento of all object states, which includes those two hidden objects
 *      const objectsMemento = new ObjectsMemento();
 *
 *      objectsMemento.saveObjects(viewer.scene);
 *
 *      // Show all objects
 *      viewer.scene.setObjectsVisible(viewer.scene.objectIds, true);
 *
 *      // Restore the objects states again, which involves hiding those two objects again
 *      objectsMemento.restoreObjects(viewer.scene);
 * });
 * `````
 *
 * ## Masking Saved State
 *
 * We can optionally supply a mask to focus what state we save and restore.
 *
 * For example, to save and restore only the {@link Entity#visible} and {@link Entity#clippable} states:
 *
 * ````javascript
 * objectsMemento.saveObjects(viewer.scene, {
 *     visible: true,
 *     clippable: true
 * });
 *
 * //...
 *
 * // Restore the objects states again
 * objectsMemento.restoreObjects(viewer.scene);
 * ````
 */
class ObjectsMemento {

    /**
     * Creates an ObjectsState.
     *
     * @param {Scene} [scene] When given, immediately saves the given {@link Scene}'s {@link Entity} states to this ObjectsState.
     */
    constructor(scene) {

        /** @private */
        this.objectsVisible = [];

        /** @private */
        this.objectsEdges = [];

        /** @private */
        this.objectsXrayed = [];

        /** @private */
        this.objectsHighlighted = [];

        /** @private */
        this.objectsSelected = [];

        /** @private */
        this.objectsClippable = [];

        /** @private */
        this.objectsPickable = [];

        /** @private */
        this.objectsColorize = [];

        /** @private */
        this.objectsOpacity = [];

        /** @private */
        this.numObjects = 0;

        if (scene) {
            this.saveObjects(scene);
        }
    }

    /**
     * Saves a snapshot of the visual state of the {@link Entity}'s that represent objects within a {@link Scene}.
     *
     * @param {Scene} scene The scene.
     * @param {Object} [mask] Masks what state gets saved. Saves all state when not supplied.
     * @param {boolean} [mask.visible] Saves {@link Entity#visible} values when ````true````.
     * @param {boolean} [mask.visible] Saves {@link Entity#visible} values when ````true````.
     * @param {boolean} [mask.edges] Saves {@link Entity#edges} values when ````true````.
     * @param {boolean} [mask.xrayed] Saves {@link Entity#xrayed} values when ````true````.
     * @param {boolean} [mask.highlighted] Saves {@link Entity#highlighted} values when ````true````.
     * @param {boolean} [mask.selected] Saves {@link Entity#selected} values when ````true````.
     * @param {boolean} [mask.clippable] Saves {@link Entity#clippable} values when ````true````.
     * @param {boolean} [mask.pickable] Saves {@link Entity#pickable} values when ````true````.
     * @param {boolean} [mask.colorize] Saves {@link Entity#colorize} values when ````true````.
     * @param {boolean} [mask.opacity] Saves {@link Entity#opacity} values when ````true````.
     */
    saveObjects(scene, mask) {

        this.numObjects = 0;

        this._mask = mask ? utils.apply(mask, {}) : null;

        const objects = scene.objects;
        const visible = (!mask || mask.visible);
        const edges = (!mask || mask.edges);
        const xrayed = (!mask || mask.xrayed);
        const highlighted = (!mask || mask.highlighted);
        const selected = (!mask || mask.selected);
        const clippable = (!mask || mask.clippable);
        const pickable = (!mask || mask.pickable);
        const colorize = (!mask || mask.colorize);
        const opacity = (!mask || mask.opacity);

        for (var objectId in objects) {
            if (objects.hasOwnProperty(objectId)) {
                const object = objects[objectId];
                const i = this.numObjects;
                if (visible) {
                    this.objectsVisible[i] = object.visible;
                }
                if (edges) {
                    this.objectsEdges[i] = object.edges;
                }
                if (xrayed) {
                    this.objectsXrayed[i] = object.xrayed;
                }
                if (highlighted) {
                    this.objectsHighlighted[i] = object.highlighted;
                }
                if (selected) {
                    this.objectsSelected[i] = object.selected;
                }
                if (clippable) {
                    this.objectsClippable[i] = object.clippable;
                }
                if (pickable) {
                    this.objectsPickable[i] = object.pickable;
                }
                if (colorize) {
                    const objectColor = object.colorize;
                    this.objectsColorize[i * 3 + 0] = objectColor[0];
                    this.objectsColorize[i * 3 + 1] = objectColor[1];
                    this.objectsColorize[i * 3 + 2] = objectColor[2];
                }
                if (opacity) {
                    this.objectsOpacity[i] = object.opacity;
                }
                this.numObjects++;
            }
        }
    }

    /**
     * Restores a {@link Scene}'s {@link Entity}'s to their state previously captured with {@link ObjectsMemento#saveObjects}.
     * @param {Scene} scene The scene.
     */
    restoreObjects(scene) {

        const mask = this._mask;

        const visible = (!mask || mask.visible);
        const edges = (!mask || mask.edges);
        const xrayed = (!mask || mask.xrayed);
        const highlighted = (!mask || mask.highlighted);
        const selected = (!mask || mask.selected);
        const clippable = (!mask || mask.clippable);
        const pickable = (!mask || mask.pickable);
        const colorize = (!mask || mask.colorize);
        const opacity = (!mask || mask.opacity);

        var i = 0;

        const objects = scene.objects;

        for (var objectId in objects) {
            if (objects.hasOwnProperty(objectId)) {
                const object = objects[objectId];
                if (visible) {
                    object.visible = this.objectsVisible[i];
                }
                if (edges) {
                    object.edges = this.objectsEdges[i];
                }
                if (xrayed) {
                    object.xrayed = this.objectsXrayed[i];
                }
                if (highlighted) {
                    object.highlighted = this.objectsHighlighted[i];
                }
                if (selected) {
                    object.selected = this.objectsSelected[i];
                }
                if (clippable) {
                    object.clippable = this.objectsClippable[i];
                }
                if (pickable) {
                    object.pickable = this.objectsPickable[i];
                }
                if (colorize) {
                    color[0] = this.objectsColorize[i * 3 + 0];
                    color[1] = this.objectsColorize[i * 3 + 1];
                    color[2] = this.objectsColorize[i * 3 + 2];
                    object.colorize = color;
                }
                if (opacity) {
                    object.opacity = this.objectsOpacity[i];
                }
                i++;
            }
        }
    }
}

export {ObjectsMemento};