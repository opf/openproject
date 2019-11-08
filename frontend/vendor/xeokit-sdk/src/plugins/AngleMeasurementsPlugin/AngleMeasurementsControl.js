import {Component} from "../../viewer/scene/Component.js";
import {math} from "../../viewer/scene/math/math.js";

const HOVERING = 0;
const FINDING_ORIGIN = 1;
const FINDING_CORNER = 2;
const FINDING_TARGET = 3;

/**
 * Creates {@link AngleMeasurement}s from mouse and touch input.
 *
 * Belongs to a {@link AngleMeasurementsPlugin}. Located at {@link AngleMeasurementsPlugin#control}.
 *
 * Once the AngleMeasurementControl is activated, the first click on any {@link Entity} begins constructing a {@link AngleMeasurement}, fixing its origin to that Entity. The next click on any Entity will complete the AngleMeasurement, fixing its target to that second Entity. The AngleMeasurementControl will then wait for the next click on any Entity, to begin constructing another AngleMeasurement, and so on, until deactivated.
 *
 * See {@link AngleMeasurementsPlugin} for more info.
 */
class AngleMeasurementsControl extends Component {

    /**
     * @private
     */
    constructor(plugin) {

        super(plugin.viewer.scene);

        /**
         * The {@link AngleMeasurementsPlugin} that owns this AngleMeasurementsControl.
         * @type {AngleMeasurementsPlugin}
         */
        this.plugin = plugin;

        this._active = false;
        this._state = HOVERING;
        this._currentAngleMeasurement = null;
        this._previousAngleMeasurement = null;
        this._onhoverSurface = null;
        this._onPickedSurface = null;
        this._onHoverNothing = null;
        this._onPickedNothing = null;
    }

    /** Gets if this AngleMeasurementsControl is currently active, where it is responding to input.
     *
     * @returns {boolean}
     */
    get active() {
        return this._active;
    }

    /**
     * Activates this AngleMeasurementsControl, ready to respond to input.
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

            if (this._currentAngleMeasurement) {
                switch (this._state) {
                    case FINDING_CORNER:
                        this._currentAngleMeasurement.originWireVisible = true;
                        this._currentAngleMeasurement.targetWireVisible = false;
                        this._currentAngleMeasurement.cornerVisible = true;
                        this._currentAngleMeasurement.angleVisible = false;
                        this._currentAngleMeasurement.corner.entity = e.entity;
                        this._currentAngleMeasurement.corner.worldPos = e.worldPos;
                        document.body.style.cursor = "pointer";
                        break;
                    case FINDING_TARGET:
                        this._currentAngleMeasurement.targetWireVisible = true;
                        this._currentAngleMeasurement.targetVisible = true;
                        this._currentAngleMeasurement.angleVisible = true;
                        this._currentAngleMeasurement.target.entity = e.entity;
                        this._currentAngleMeasurement.target.worldPos = e.worldPos;
                        document.body.style.cursor = "pointer";
                        break;
                }
            }
        });

        var lastX;
        var lastY;
        const tolerance = 2;

        this._onInputMouseDown = this.plugin.viewer.scene.input.on("mousedown", (coords) => {
            if (!over) {
                return;
            }
            lastX = coords[0];
            lastY = coords[1];
        });

        this._onInputMouseUp = this.plugin.viewer.scene.input.on("mouseup", (coords) => {

            if (coords[0] > lastX + tolerance || coords[0] < lastX - tolerance || coords[1] > lastY + tolerance || coords[1] < lastY - tolerance) {
                return;
            }

            switch (this._state) {

                case HOVERING:
                    if (this._previousAngleMeasurement) {
                        this._previousAngleMeasurement.originVisible = true;
                        this._previousAngleMeasurement.cornerVisible = true;
                        this._previousAngleMeasurement.targetVisible = true;
                    }
                    if (over) {
                        this._currentAngleMeasurement = this.plugin.createMeasurement({
                            id: math.createUUID(),
                            origin: {
                                entity: entity,
                                worldPos: worldPos
                            },
                            corner: {
                                entity: entity,
                                worldPos: worldPos
                            },
                            target: {
                                entity: entity,
                                worldPos: worldPos
                            }
                        });
                        this._currentAngleMeasurement.originVisible = true;
                        this._currentAngleMeasurement.originWireVisible = true;
                        this._currentAngleMeasurement.cornerVisible = false;
                        this._currentAngleMeasurement.targetWireVisible = false;
                        this._currentAngleMeasurement.targetVisible = false;
                        this._currentAngleMeasurement.angleVisible = false;
                        this._previousAngleMeasurement = this._currentAngleMeasurement;
                        this._state = FINDING_CORNER;
                    }
                    break;

                case FINDING_CORNER:
                    if (over) {
                        this._currentAngleMeasurement.targetWireVisible = false;
                        this._currentAngleMeasurement.targetVisible = true;
                        this._currentAngleMeasurement.angleVisible = true;
                        this._state = FINDING_TARGET;
                    } else {
                        if (this._currentAngleMeasurement) {
                            this._currentAngleMeasurement.destroy();
                            this._currentAngleMeasurement = null;
                            this._previousAngleMeasurement = null;
                            this._state = HOVERING
                        }
                    }
                    break;

                case FINDING_TARGET:
                    if (over) {
                        this._currentAngleMeasurement.targetVisible = true;
                        this._currentAngleMeasurement.angleVisible = true;
                        this._currentAngleMeasurement = null;
                        this._previousAngleMeasurement = null;
                        this._state = HOVERING;
                    } else {
                        if (this._currentAngleMeasurement) {
                            this._currentAngleMeasurement.destroy();
                            this._currentAngleMeasurement = null;
                            this._previousAngleMeasurement = null;
                            this._state = HOVERING;
                        }
                    }
                    break;
            }
        });

        this._onHoverNothing = cameraControl.on("hoverOff", e => {
            over = false;
            if (this._currentAngleMeasurement) {
                switch (this._state) {
                    case HOVERING:
                    case FINDING_ORIGIN:
                        this._currentAngleMeasurement.originVisible = false;
                        break;
                    case FINDING_CORNER:
                        this._currentAngleMeasurement.cornerVisible = false;
                        this._currentAngleMeasurement.originWireVisible = false;
                        this._currentAngleMeasurement.targetVisible = false;
                        this._currentAngleMeasurement.targetWireVisible = false;
                        this._currentAngleMeasurement.angleVisible = false;
                        break;
                    case FINDING_TARGET:
                        this._currentAngleMeasurement.targetVisible = false;
                        this._currentAngleMeasurement.targetWireVisible = false;
                        this._currentAngleMeasurement.angleVisible = false;
                        break;

                }
                document.body.style.cursor = "default";
            }
        });

        this._active = true;
    }

    /**
     * Deactivates this AngleMeasurementsControl, making it unresponsive to input.
     *
     * Destroys any {@link AngleMeasurement} under construction.
     */
    deactivate() {

        if (!this._active) {
            return;
        }

        this.reset();

        const cameraControl = this.plugin.viewer.cameraControl;
        const input = this.plugin.viewer.scene.input;

        input.off(this._onInputMouseDown);
        input.off(this._onInputMouseUp);

        cameraControl.off(this._onhoverSurface);
        cameraControl.off(this._onPickedSurface);
        cameraControl.off(this._onHoverNothing);
        cameraControl.off(this._onPickedNothing);

        this._currentAngleMeasurement = null;

        this._active = false;
    }

    /**
     * Resets this AngleMeasurementsControl.
     *
     * Destroys any {@link AngleMeasurement} under construction.
     *
     * Does nothing if the AngleMeasurementsControl is not active.
     */
    reset() {
        
        if (!this._active) {
            return;
        }
        
        if (this._currentAngleMeasurement) {
            this._currentAngleMeasurement.destroy();
            this._currentAngleMeasurement = null;
        }
        
        this._previousAngleMeasurement = null;
        
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

export {AngleMeasurementsControl};