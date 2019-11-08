import {Plugin} from "../../viewer/Plugin.js";
import {DistanceMeasurement} from "./DistanceMeasurement.js";
import {DistanceMeasurementsControl} from "./DistanceMeasurementsControl.js";

/**
 * {@link Viewer} plugin for measuring point-to-point distances.
 *
 * [<img src="https://user-images.githubusercontent.com/83100/63047331-867a0a80-bed4-11e9-892f-398740013c5f.gif">](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_createWithMouse)
 *
 * * [[Example 1: Model with distance measurements](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_modelWithMeasurements)]
 * * [[Example 2: Create distance measurements with mouse](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_createWithMouse)]
 * * [[Example 3: Configuring units and scale](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_unitsAndScale)]
 *
 * ## Overview
 *
 * * A {@link DistanceMeasurement} represents a point-to-point measurement between two 3D points on one or two {@link Entity}s.
 * * As shown on the screen capture above, a DistanceMeasurement has one wire (light blue) that shows the direct point-to-point measurement,
 * and three more wires (red, green and blue) that show the distance on each of the World-space X, Y and Z axis.
 * * Create DistanceMeasurements programmatically with {@link DistanceMeasurementsPlugin#createMeasurement}.
 * * Create DistanceMeasurements interactively using the {@link DistanceMeasurementsControl}, located at {@link DistanceMeasurementsPlugin#control}.
 * * Existing DistanceMeasurements are registered by ID in {@link DistanceMeasurementsPlugin#measurements}.
 * * Destroy DistanceMeasurements using {@link DistanceMeasurementsPlugin#destroyMeasurement}.
 * * Configure global measurement units and scale via {@link Metrics}, located at {@link Scene#metrics}.
 *
 * ## Example 1: Creating DistanceMeasurements Programmatically
 *
 * In our first example, we'll use an {@link XKTLoaderPlugin} to load a model, and then use a DistanceMeasurementsPlugin to programmatically create two {@link DistanceMeasurement}s.
 *
 * Note how each DistanceMeasurement has ````origin```` and ````target```` endpoints, which each indicate a 3D World-space
 * position on the surface of an {@link Entity}. The endpoints can be attached to the same Entity, or to different Entitys.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_modelWithMeasurements)]
 *
 * ````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 * import {DistanceMeasurementsPlugin} from "../src/plugins/DistanceMeasurementsPlugin/DistanceMeasurementsPlugin.js";
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
 * const distanceMeasurements = new DistanceMeasurementsPlugin(viewer);
 *
 * const model = xktLoader.load({
 *      src: "./models/xkt/duplex/duplex.xkt"
 * });
 *
 * model.on("loaded", () => {
 *
 *      const myMeasurement1 = distanceMeasurements.createMeasurement({
 *          id: "distanceMeasurement1",
 *          origin: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"],
 *              worldPos: [0.044, 5.998, 17.767]
 *          },
 *          target: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"],
 *              worldPos: [4.738, 3.172, 17.768]
 *          },
 *          visible: true,
 *          wireVisible: true
 *      });
 *
 *      const myMeasurement2 = distanceMeasurements.createMeasurement({
 *          id: "distanceMeasurement2",
 *          origin: {
 *              entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FNr2"],
 *              worldPos: [0.457, 2.532, 17.766]
 *          },
 *          target: {
 *              entity: viewer.scene.objects["1CZILmCaHETO8tf3SgGEXu"],
 *              worldPos: [0.436, 0.001, 22.135]
 *          },
 *          visible: true,
 *          wireVisible: true
 *      });
 * });
 * ````
 *
 * ## Example 2: Creating DistanceMeasurements Interactively
 *
 * In our second example, we'll use an {@link XKTLoaderPlugin} to load a model, then we'll use the DistanceMeasurementPlugin's {@link DistanceMeasurementsControl} to interactively create {@link DistanceMeasurement}s with mouse or touch input.
 *
 * After we've activated the DistanceMeasurementsControl, the first click on any {@link Entity} begins constructing a DistanceMeasurement, fixing its
 * origin to that Entity. The next click on any Entity will complete the DistanceMeasurement, fixing its target to that second Entity.
 *
 * The DistanceMeasurementControl will then wait for the next click on any Entity, to begin constructing
 * another DistanceMeasurement, and so on, until deactivated again.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_createWithMouse)]
 *
 * ````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {XKTLoaderPlugin} from "../src/plugins/XKTLoaderPlugin/XKTLoaderPlugin.js";
 * import {DistanceMeasurementsPlugin} from "../src/plugins/DistanceMeasurementsPlugin/DistanceMeasurementsPlugin.js";
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
 * const distanceMeasurements = new DistanceMeasurementsPlugin(viewer);
 *
 * const model = xktLoader.load({
 *     src: "./models/xkt/duplex/duplex.xkt"
 * });
 *
 * distanceMeasurements.control.activate();  // <------------ Activate the DistanceMeasurementsControl
 * ````
 *
 * ## Example 3: Configuring Measurement Units and Scale
 *
 * In our third example, we'll use the  {@link Scene}'s {@link Metrics} to set the global unit of measurement to ````"meters"````. We'll also specify that a unit within the World-space coordinate system represents ten meters.
 *
 * The wires belonging to our DistanceMeasurements show their lengths in Real-space coordinates, in the current unit of measurement. They will dynamically update as we set these configurations.
 *
 * * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#measurements_distance_unitsAndScale)]
 *
 * ````JavaScript
 * const metrics = viewer.scene.metrics;

 * metrics.units = "meters";
 * metrics.scale = 10.0;
 * ````
 */
class DistanceMeasurementsPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} [cfg]  Plugin configuration.
     * @param {String} [cfg.id="DistanceMeasurements"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Number} [cfg.labelMinAxisLength=25] The minimum length, in pixels, of an axis wire beyond which its label is shown.
     * @param {HTMLElement} [cfg.container] Container DOM element for markers and labels. Defaults to ````document.body````.
     */
    constructor(viewer, cfg = {}) {

        super("DistanceMeasurements", viewer);

        this._container = cfg.container || document.body;

        this._control = new DistanceMeasurementsControl(this);

        this._measurements = {};

        this.labelMinAxisLength = cfg.labelMinAxisLength;
    }

    /**
     * @private
     */
    send(name, value) {

    }

    /**
     * Gets the {@link DistanceMeasurementsControl}, which creates {@link DistanceMeasurement}s from user input.
     *
     * @type {DistanceMeasurementsControl}
     */
    get control() {
        return this._control;
    }

    /**
     * Gets the existing {@link DistanceMeasurement}s, each mapped to its {@link DistanceMeasurement#id}.
     *
     * @type {{String:DistanceMeasurement}}
     */
    get measurements() {
        return this._measurements;
    }

    /**
     * Sets the minimum length, in pixels, of an axis wire beyond which its label is shown.
     *
     * The axis wire's label is not shown when its length is less than this value.
     *
     * This is ````25```` pixels by default.
     *
     * Must not be less than ````1````.
     *
     * @type {number}
     */
    set labelMinAxisLength(labelMinAxisLength) {
        if (labelMinAxisLength < 1) {
            this.error("labelMinAxisLength must be >= 1; defaulting to 25");
            labelMinAxisLength = 25;
        }
        this._labelMinAxisLength = labelMinAxisLength || 25;
    }

    /**
     * Gets the minimum length, in pixels, of an axis wire beyond which its label is shown.
     * @returns {number}
     */
    get labelMinAxisLength() {
        return this._labelMinAxisLength;
    }

    /**
     * Creates a {@link DistanceMeasurement}.
     *
     * The DistanceMeasurement is then registered by {@link DistanceMeasurement#id} in {@link DistanceMeasurementsPlugin#measurements}.
     *
     * @param {Object} params {@link DistanceMeasurement} configuration.
     * @param {String} params.id Unique ID to assign to {@link DistanceMeasurement#id}. The DistanceMeasurement will be registered by this in {@link DistanceMeasurementsPlugin#measurements} and {@link Scene.components}. Must be unique among all components in the {@link Viewer}.
     * @param {Number[]} params.origin.worldPos Origin World-space 3D position.
     * @param {Entity} params.origin.entity Origin Entity.
     * @param {Number[]} params.target.worldPos Target World-space 3D position.
     * @param {Entity} params.target.entity Target Entity.
     * @param {Boolean} [params.visible=true] Whether to initially show the {@link DistanceMeasurement}.
     * @param {Boolean} [params.originVisible=true] Whether to initially show the {@link DistanceMeasurement} origin.
     * @param {Boolean} [params.targetVisible=true] Whether to initially show the {@link DistanceMeasurement} target.
     * @param {Boolean} [params.wireVisible=true] Whether to initially show the direct point-to-point wire between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target}.
     * @param {Boolean} [params.axisVisible=true] Whether to initially show the axis-aligned wires between {@link DistanceMeasurement#origin} and {@link DistanceMeasurement#target}.
     * @returns {DistanceMeasurement} The new {@link DistanceMeasurement}.
     */
    createMeasurement(params = {}) {
        if (this.viewer.scene.components[params.id]) {
            this.error("Viewer scene component with this ID already exists: " + params.id);
            delete params.id;
        }
        const origin = params.origin;
        const target = params.target;
        const measurement = new DistanceMeasurement(this, {
            id: params.id,
            plugin: this,
            container: this._container,
            origin: {
                entity: origin.entity,
                worldPos: origin.worldPos
            },
            target: {
                entity: target.entity,
                worldPos: target.worldPos
            },
            visible: params.visible,
            wireVisible: params.wireVisible,
            originVisible: params.originVisible,
            targetVisible: params.targetVisible,
        });
        this._measurements[measurement.id] = measurement;
        measurement.on("destroyed", () => {
            delete this._measurements[measurement.id];
        });
        return measurement;
    }

    /**
     * Destroys a {@link DistanceMeasurement}.
     *
     * @param {String} id ID of DistanceMeasurement to destroy.
     */
    destroyMeasurement(id) {
        const measurement = this._measurements[id];
        if (!measurement) {
            this.log("DistanceMeasurement not found: " + id);
            return;
        }
        measurement.destroy();
    }

    /**
     * Destroys all {@link DistanceMeasurement}s.
     */
    clear() {
        const ids = Object.keys(this._measurements);
        for (var i = 0, len = ids.length; i < len; i++) {
            this.destroyMeasurement(ids[i]);
        }
    }

    /**
     * Destroys this DistanceMeasurementsPlugin.
     *
     * Destroys all {@link DistanceMeasurement}s first.
     */
    destroy() {
        this.clear();
        super.destroy();
    }
}

export {DistanceMeasurementsPlugin}
