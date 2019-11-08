import {Plugin} from "../../viewer/Plugin.js";
import {AngleMeasurement} from "./AngleMeasurement.js";
import {AngleMeasurementsControl} from "./AngleMeasurementsControl.js";

/**
 * {@link Viewer} plugin for measuring angles.
 *
 * [<img src="https://user-images.githubusercontent.com/83100/63641903-61488180-c6b6-11e9-8e00-895b9d16dc4b.gif">](https://xeokit.github.io/xeokit-sdk/examples/#measurements_angle_createWithMouse)
 *
 * * [[Example 1: Model with angle measurements](https://xeokit.github.io/xeokit-sdk/examples/#measurements_angle_modelWithMeasurements)]
 * * [[Example 2: Create angle measurements with mouse](https://xeokit.github.io/xeokit-sdk/examples/#measurements_angle_createWithMouse)]
 *
 * ## Overview
 *
 * * An {@link AngleMeasurement} shows the angle between two connected 3D line segments, given
 * as three positions on the surface(s) of one or more {@link Entity}s.
 * * As shown on the screen capture above, a AngleMeasurement has two wires that show the line segments, with a label that shows the angle between them.
 * * Create AngleMeasurements programmatically with {@link AngleMeasurementsPlugin#createMeasurement}.
 * * Create AngleMeasurements interactively using the {@link AngleMeasurementsControl}, located at {@link AngleMeasurementsPlugin#control}.
 * * Existing AngleMeasurements are registered by ID in {@link AngleMeasurementsPlugin#measurements}.
 * * Destroy AngleMeasurements using {@link AngleMeasurementsPlugin#destroyMeasurement}.
 * * Configure global measurement units and scale via {@link Metrics}, located at {@link Scene#metrics}
 *
 * ## Example 1: Creating AngleMeasurements Programmatically
 *
 * In our first example, we'll use an {@link XKTLoaderPlugin} to load a model, and then use a AngleMeasurementsPlugin to programmatically create two {@link AngleMeasurement}s.
 *
 * Note how each AngleMeasurement has ````origin````, ````corner```` and  ````target````, which each indicate a 3D World-space
 * position on the surface of an {@link Entity}. These can be aon the same Entity, or on different Entitys.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#measurements_angle_modelWithMeasurements)]
 *
 * ````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 * import {AngleMeasurementsPlugin} from "../src/plugins/AngleMeasurementsPlugin/AngleMeasurementsPlugin.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas",
 *     transparent: true
 * });
 *
 * viewer.scene.camera.eye = [-2.37, 18.97, -26.12];
 * viewer.scene.camera.look = [10.97, 5.82, -11.22];
 * viewer.scene.camera.up = [0.36, 0.83, 0.40];
 *
 * const xktLoader = new XKTLoaderPlugin(viewer);
 *
 * const angleMeasurements = new AngleMeasurementsPlugin(viewer);
 *
 * const model = xktLoader.load({
 *      src: "./models/xkt/duplex/duplex.xkt"
 * });
 *
 * model.on("loaded", () => {
 *
 *      const myMeasurement1 = angleMeasurements.createMeasurement({
 *          id: "myAngleMeasurement1",
 *          origin: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"],
 *              worldPos: [0.044, 5.998, 17.767]
 *          },
 *          corner: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"],
 *              worldPos: [0.044, 5.998, 17.767]
 *          },
 *          target: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"],
 *              worldPos: [4.738, 3.172, 17.768]
 *          },
 *          visible: true
 *      });
 *
 *      const myMeasurement2 = angleMeasurements.createMeasurement({
 *          id: "myAngleMeasurement2",
 *          origin: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FNr2"],
 *              worldPos: [0.457, 2.532, 17.766]
 *          },
 *          corner: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FNr2"],
 *              worldPos: [0.457, 2.532, 17.766]
 *          },
 *          target: {
 *              entity: viewer.scene.objects["1CZILmCaHETO8tf3SgGEXu"],
 *              worldPos: [0.436, 0.001, 22.135]
 *          },
 *          visible: true
 *      });
 * });
 * ````
 *
 * ## Example 2: Creating AngleMeasurements Interactively
 *
 * In our second example, we'll use an {@link XKTLoaderPlugin} to load a model, then we'll use the AngleMeasurementPlugin's {@link AngleMeasurementsControl} to interactively create {@link AngleMeasurement}s with mouse or touch input.
 *
 * After we've activated the AngleMeasurementsControl, the first click on any {@link Entity} begins constructing a AngleMeasurement, fixing its
 * origin to that Entity. The next click on any Entity will fix the AngleMeasurement's corner, and the next click after
 * that will fix its target and complete the AngleMeasurement.
 *
 * The AngleMeasurementControl will then wait for the next click on any Entity, to begin constructing
 * another AngleMeasurement, and so on, until deactivated again.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#measurements_angle_createWithMouse)]
 *
 * ````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 * import {AngleMeasurementsPlugin} from "../src/plugins/AngleMeasurementsPlugin/AngleMeasurementsPlugin.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas",
 *     transparent: true
 * });
 *
 * viewer.scene.camera.eye = [-2.37, 18.97, -26.12];
 * viewer.scene.camera.look = [10.97, 5.82, -11.22];
 * viewer.scene.camera.up = [0.36, 0.83, 0.40];
 *
 * const xktLoader = new XKTLoaderPlugin(viewer);
 *
 * const angleMeasurements = new AngleMeasurementsPlugin(viewer);
 *
 * const model = xktLoader.load({
 *     src: "./models/xkt/duplex/duplex.xkt"
 * });
 *
 * angleMeasurements.control.activate();  // <------------ Activate the AngleMeasurementsControl
 * ````
 */
class AngleMeasurementsPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} [cfg]  Plugin configuration.
     * @param {String} [cfg.id="AngleMeasurements"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {HTMLElement} [cfg.container] Container DOM element for markers and labels. Defaults to ````document.body````.
    */
    constructor(viewer, cfg = {}) {

        super("AngleMeasurements", viewer);

        this._container = cfg.container || document.body;

        this._control = new AngleMeasurementsControl(this);

        this._measurements = {};
    }

    /**
     * @private
     */
    send(name, value) {

    }

    /**
     * Gets the {@link AngleMeasurementsControl}, which creates {@link AngleMeasurement}s from user input.
     *
     * @type {AngleMeasurementsControl}
     */
    get control() {
        return this._control;
    }

    /**
     * Gets the existing {@link AngleMeasurement}s, each mapped to its {@link AngleMeasurement#id}.
     *
     * @type {{String:AngleMeasurement}}
     */
    get measurements() {
        return this._measurements;
    }

    /**
     * Creates an {@link AngleMeasurement}.
     *
     * The AngleMeasurement is then registered by {@link AngleMeasurement#id} in {@link AngleMeasurementsPlugin#measurements}.
     *
     * @param {Object} params {@link AngleMeasurement} configuration.
     * @param {String} params.id Unique ID to assign to {@link AngleMeasurement#id}. The AngleMeasurement will be registered by this in {@link AngleMeasurementsPlugin#measurements} and {@link Scene.components}. Must be unique among all components in the {@link Viewer}.
     * @param {Number[]} params.origin.worldPos Origin World-space 3D position.
     * @param {Entity} params.origin.entity Origin Entity.
     * @param {Number[]} params.corner.worldPos Corner World-space 3D position.
     * @param {Entity} params.corner.entity Corner Entity.
     * @param {Number[]} params.target.worldPos Target World-space 3D position.
     * @param {Entity} params.target.entity Target Entity.
     * @param {Boolean} [params.visible=true] Whether to initially show the {@link AngleMeasurement}.
     * @returns {AngleMeasurement} The new {@link AngleMeasurement}.
     */
    createMeasurement(params = {}) {
        if (this.viewer.scene.components[params.id]) {
            this.error("Viewer scene component with this ID already exists: " + params.id);
            delete params.id;
        }
        const origin = params.origin;
        const corner = params.corner;
        const target = params.target;
        const measurement = new AngleMeasurement(this, {
            id: params.id,
            plugin: this,
            container: this._container,
            origin: {
                entity: origin.entity,
                worldPos: origin.worldPos
            },
            corner: {
                entity: corner.entity,
                worldPos: corner.worldPos
            },
            target: {
                entity: target.entity,
                worldPos: target.worldPos
            },

            visible: params.visible,
            originVisible: true,
            originWireVisible: true,
            cornerVisible: true,
            targetWireVisible: true,
            targetVisible: true,
        });
        this._measurements[measurement.id] = measurement;
        measurement.on("destroyed", () => {
            delete this._measurements[measurement.id];
        });
        return measurement;
    }

    /**
     * Destroys a {@link AngleMeasurement}.
     *
     * @param {String} id ID of AngleMeasurement to destroy.
     */
    destroyMeasurement(id) {
        const measurement = this._measurements[id];
        if (!measurement) {
            this.log("AngleMeasurement not found: " + id);
            return;
        }
        measurement.destroy();
    }

    /**
     * Destroys all {@link AngleMeasurement}s.
     */
    clear() {
        const ids = Object.keys(this._measurements);
        for (var i = 0, len = ids.length; i < len; i++) {
            this.destroyMeasurement(ids[i]);
        }
    }

    /**
     * Destroys this AngleMeasurementsPlugin.
     *
     * Destroys all {@link AngleMeasurement}s first.
     */
    destroy() {
        this.clear();
        super.destroy();
    }
}

export {AngleMeasurementsPlugin}
