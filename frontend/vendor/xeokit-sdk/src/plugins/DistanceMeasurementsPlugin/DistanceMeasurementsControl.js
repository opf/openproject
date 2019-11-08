import {Component} from "../../viewer/scene/Component.js";
import {math} from "../../viewer/scene/math/math.js";

const HOVERING = 0;
const FINDING_ORIGIN = 1;
const FINDING_TARGET = 2;

/**
 * Creates {@link DistanceMeasurement}s from mouse and touch input.
 *
 * Belongs to a {@link DistanceMeasurementsPlugin}. Located at {@link DistanceMeasurementsPlugin#control}.
 *
 * Once the DistanceMeasurementControl is activated, the first click on any {@link Entity} begins constructing a {@link DistanceMeasurement}, fixing its origin to that Entity. The next click on any Entity will complete the DistanceMeasurement, fixing its target to that second Entity. The DistanceMeasurementControl will then wait for the next click on any Entity, to begin constructing another DistanceMeasurement, and so on, until deactivated.
 *
 * See {@link DistanceMeasurementsPlugin} for more info.
 */
class DistanceMeasurementsControl extends Component {

    /**
     * @private
     */
    constructor(plugin) {

        super(plugin.viewer.scene);

        /**
         * The {@link DistanceMeasurementsPlugin} that owns this DistanceMeasurementsControl.
         * @type {DistanceMeasurementsPlugin}
         */
        this.plugin = plugin;

        this._active = false;
        this._state = HOVERING;
        this._currentDistMeasurement = null;
        this._prevDistMeasurement = null;
        this._onhoverSurface = null;
        this._onPickedSurface = null;
        this._onHoverNothing = null;
        this._onPickedNothing = null;
    }

    /** Gets if this DistanceMeasurementsControl is currently active, where it is responding to input.
     *
     * @returns {boolean}
     */
    get active() {
        return this._active;
    }

    /**
     * Activates this DistanceMeasurementsControl, ready to respond to input.
     */
    activate() {

        if (this._active) {
            return;
        }

        const cameraControl = this.plugin.viewer.cameraControl;

        let over = false;
        let entity = null;
        let worldPos = math.vec3();

        this._onhoverSurface = cameraControl.on("hoverSurface", e => {

            over = true;
            entity = e.entity;
            worldPos.set(e.worldPos);

            if (this._state === HOVERING) {
                document.body.style.cursor = "pointer";
                return;
            }

            if (this._currentDistMeasurement) {
                switch (this._state) {
                    case FINDING_TARGET:
                        this._currentDistMeasurement.wireVisible = true;
                        this._currentDistMeasurement.axisVisible = true;
                        this._currentDistMeasurement.target.entity = e.entity;
                        this._currentDistMeasurement.target.worldPos = e.worldPos;
                        document.body.style.cursor = "pointer";
                        break;
                }
            }
        });

        var lastX;
        var lastY;
        const tolerance = 2;

        this._onInputMouseDown = this.plugin.viewer.scene.input.on("mousedown", (coords) => {
            lastX = coords[0];
            lastY = coords[1];
        });

        this._onInputMouseUp = this.plugin.viewer.scene.input.on("mouseup", (coords) => {

            if (coords[0] > lastX + tolerance || coords[0] < lastX - tolerance || coords[1] > lastY + tolerance || coords[1] < lastY - tolerance) {
                return;
            }

            switch (this._state) {

                case HOVERING:
                    if (this._prevDistMeasurement) {
                        this._prevDistMeasurement.originVisible = true;
                        this._prevDistMeasurement.targetVisible = true;
                        this._prevDistMeasurement.axisVisible = true;
                    }
                    if (over) {
                        this._currentDistMeasurement = this.plugin.createMeasurement({
                            id: math.createUUID(),
                            origin: {
                                entity: entity,
                                worldPos: worldPos
                            },
                            target: {
                                entity: entity,
                                worldPos: worldPos
                            }
                        });
                        this._currentDistMeasurement.axisVisible = false;
                        this._currentDistMeasurement.targetVisible = true;
                        this._prevDistMeasurement = this._currentDistMeasurement;
                        this._state = FINDING_TARGET;
                    }
                    break;

                case FINDING_TARGET:
                    if (over) {
                        this._currentDistMeasurement.axisVisible = true;
                        this._currentDistMeasurement.targetVisible = true;
                        this._currentDistMeasurement = null;
                        this._prevDistMeasurement = null;
                        this._state = HOVERING;
                    } else {
                        if (this._currentDistMeasurement) {
                            this._currentDistMeasurement.destroy();
                            this._currentDistMeasurement = null;
                            this._prevDistMeasurement = null;
                            this._state = HOVERING;
                        }
                    }
                    break;
            }
        });

        this._onHoverNothing = cameraControl.on("hoverOff", e => {
            over = false;
            if (this._currentDistMeasurement) {
                switch (this._state) {
                    case HOVERING:
                        break;
                    case FINDING_ORIGIN:
                        this._currentDistMeasurement.wireVisible = false;
                        this._currentDistMeasurement.originVisible = false;
                        this._currentDistMeasurement.axisVisible = false;
                        break;
                    case FINDING_TARGET:
                        this._currentDistMeasurement.wireVisible = false;
                        this._currentDistMeasurement.targetVisible = false;
                        this._currentDistMeasurement.axisVisible = false;
                        break;
                }
            }
            document.body.style.cursor = "default";
        });

        this._onPickedNothing = cameraControl.on("pickedNothing", e => {
            if (this._currentDistMeasurement) {
                this._currentDistMeasurement.destroy();
                this._currentDistMeasurement = null;
                this._prevDistMeasurement = null;
                this._state = HOVERING
            }
        });

        this._active = true;
    }

    /**
     * Deactivates this DistanceMeasurementsControl, making it unresponsive to input.
     *
     * Destroys any {@link DistanceMeasurement} under construction.
     */
    deactivate() {

        if (!this._active) {
            return;
        }

        this.reset();

        const cameraControl = this.plugin.viewer.cameraControl;
        const input = this.plugin.viewer.scene.input;

        input.off(this._onInputMouseDown);

        cameraControl.off(this._onhoverSurface);
        cameraControl.off(this._onPickedSurface);
        cameraControl.off(this._onHoverNothing);
        cameraControl.off(this._onPickedNothing);

        this._currentDistMeasurement = null;

        this._active = false;
    }

    /**
     * Resets this DistanceMeasurementsControl.
     *
     * Destroys any {@link DistanceMeasurement} under construction.
     *
     * Does nothing if the DistanceMeasurementsControl is not active.
     */
    reset() {

        if (!this._active) {
            return;
        }

        if (this._currentDistMeasurement) {
            this._currentDistMeasurement.destroy();
            this._currentDistMeasurement = null;
        }
        this._prevDistMeasurement = null;
        this._state = HOVERING;
    }

    /**
     * @private
     */
    destroy() {
        this.deactivate();
        super.destroy();
    }

}

export {DistanceMeasurementsControl};