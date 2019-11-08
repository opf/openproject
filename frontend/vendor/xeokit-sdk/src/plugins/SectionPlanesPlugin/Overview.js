import {math} from "../../viewer/scene/math/math.js";
import {Scene} from "../../viewer/scene/scene/Scene.js";
import {DirLight} from "./../../viewer/scene/lights/DirLight.js";
import {Plane} from "./Plane.js";

/**
 * @desc An interactive 3D overview for navigating the {@link SectionPlane}s created by its {@link SectionPlanesPlugin}.
 *
 * * Located at {@link SectionPlanesPlugin#overview}.
 * * Renders the overview on a separate canvas at a corner of the {@link Viewer}'s {@link Scene} {@link Canvas}.
 * * The overview shows a 3D plane object for each {@link SectionPlane} in the {@link Scene}.
 * * Click a plane object in the overview to toggle the visibility of a 3D gizmo to edit the position and orientation of its {@link SectionPlane}.
 *
 * @private
 */
class Overview {

    /**
     * @private
     */
    constructor(plugin, cfg) {

        if (!cfg.onHoverEnterPlane || !cfg.onHoverLeavePlane || !cfg.onClickedNothing || !cfg.onClickedPlane) {
            throw "Missing config(s): onHoverEnterPlane, onHoverLeavePlane, onClickedNothing || onClickedPlane";
        }

        /**
         * The {@link SectionPlanesPlugin} that owns this SectionPlanesOverview.
         *
         * @type {SectionPlanesPlugin}
         */
        this.plugin = plugin;

        this._viewer = plugin.viewer;

        this._onHoverEnterPlane = cfg.onHoverEnterPlane;
        this._onHoverLeavePlane = cfg.onHoverLeavePlane;
        this._onClickedNothing = cfg.onClickedNothing;
        this._onClickedPlane = cfg.onClickedPlane;
        this._visible = true;

        this._planes = {};

        //--------------------------------------------------------------------------------------------------------------
        // Init canvas
        //--------------------------------------------------------------------------------------------------------------

        this._canvas = cfg.overviewCanvas;

        //--------------------------------------------------------------------------------------------------------------
        // Init scene
        //--------------------------------------------------------------------------------------------------------------

        this._scene = new Scene({
            canvasId: this._canvas.id,
            transparent: true
        });
        this._scene.clearLights();
        new DirLight(this._scene, {
            dir: [0.4, -0.4, 0.8],
            color: [0.8, 1.0, 1.0],
            intensity: 1.0,
            space: "view"
        });
        new DirLight(this._scene, {
            dir: [-0.8, -0.3, -0.4],
            color: [0.8, 0.8, 0.8],
            intensity: 1.0,
            space: "view"
        });
        new DirLight(this._scene, {
            dir: [0.8, -0.6, -0.8],
            color: [1.0, 1.0, 1.0],
            intensity: 1.0,
            space: "view"
        });

        this._scene.camera;
        this._scene.camera.perspective.fov = 70;

        this._zUp = false;

        //--------------------------------------------------------------------------------------------------------------
        // Synchronize overview scene camera with viewer camera
        //--------------------------------------------------------------------------------------------------------------

        {
            const camera = this._scene.camera;
            const matrix = math.rotationMat4c(-90 * math.DEGTORAD, 1, 0, 0);
            const eyeLookVec = math.vec3();
            const eyeLookVecOverview = math.vec3();
            const upOverview = math.vec3();

            this._synchCamera = () => {
                const eye = this._viewer.camera.eye;
                const look = this._viewer.camera.look;
                const up = this._viewer.camera.up;
                math.mulVec3Scalar(math.normalizeVec3(math.subVec3(eye, look, eyeLookVec)), 7);
                if (this._zUp) { // +Z up
                    math.transformVec3(matrix, eyeLookVec, eyeLookVecOverview);
                    math.transformVec3(matrix, up, upOverview);
                    camera.look = [0, 0, 0];
                    camera.eye = math.transformVec3(matrix, eyeLookVec, eyeLookVecOverview);
                    camera.up = math.transformPoint3(matrix, up, upOverview);
                } else { // +Y up
                    camera.look = [0, 0, 0];
                    camera.eye = eyeLookVec;
                    camera.up = up;
                }
            };
        }

        this._onViewerCameraMatrix = this._viewer.camera.on("matrix", this._synchCamera);

        this._onViewerCameraWorldAxis = this._viewer.camera.on("worldAxis", this._synchCamera);

        this._onViewerCameraFOV = this._viewer.camera.perspective.on("fov", (fov) => {
            this._scene.camera.perspective.fov = fov;
        });

        this._onViewerCameraProjection = this._viewer.camera.on("projection", (projection) => {
            this._scene.camera.projection = projection;
        });

        //--------------------------------------------------------------------------------------------------------------
        // Bind overview canvas events
        //--------------------------------------------------------------------------------------------------------------

        {
            var hoveredEntity = null;

            this._onInputMouseMove = this._scene.input.on("mousemove", (coords) => {
                const hit = this._scene.pick({
                    canvasPos: coords
                });
                if (hit) {
                    if (!hoveredEntity || hit.entity.id !== hoveredEntity.id) {
                        if (hoveredEntity) {
                            const plane = this._planes[hoveredEntity.id];
                            if (plane) {
                                this._onHoverLeavePlane(hoveredEntity.id);
                            }
                        }
                        hoveredEntity = hit.entity;
                        const plane = this._planes[hoveredEntity.id];
                        if (plane) {
                            this._onHoverEnterPlane(hoveredEntity.id);
                        }
                    }
                } else {
                    if (hoveredEntity) {
                        this._onHoverLeavePlane(hoveredEntity.id);
                        hoveredEntity = null;
                    }
                }
            });

            this._scene.canvas.canvas.addEventListener("mouseup", this._onCanvasMouseUp = () => {
                if (hoveredEntity) {
                    const plane = this._planes[hoveredEntity.id];
                    if (plane) {
                        this._onClickedPlane(hoveredEntity.id);
                    }
                } else {
                    this._onClickedNothing();
                }
            });

            this._scene.canvas.canvas.addEventListener("mouseout", this._onCanvasMouseOut = () => {
                if (hoveredEntity) {
                    this._onHoverLeavePlane(hoveredEntity.id);
                    hoveredEntity = null;
                }
            });
        }

        //--------------------------------------------------------------------------------------------------------------
        // Configure overview
        //--------------------------------------------------------------------------------------------------------------

        this.setVisible(cfg.overviewVisible);
    }

    /** Called by SectionPlanesPlugin#createSectionPlane()
     * @private
     */
    addSectionPlane(sectionPlane) {
        this._planes[sectionPlane.id] = new Plane(this, this._scene, sectionPlane);
    }

    /**  @private
     */
    setPlaneHighlighted(id, highlighted) {
        const plane = this._planes[id];
        if (plane) {
            plane.setHighlighted(highlighted);
        }
    }

    /**  @private
     */
    setPlaneSelected(id, selected) {
        const plane = this._planes[id];
        if (plane) {
            plane.setSelected(selected);
        }
    }

    /** @private
     */
    removeSectionPlane(sectionPlane) {
        const plane = this._planes[sectionPlane.id];
        if (plane) {
            plane.destroy();
            delete this._planes[sectionPlane.id];
        }
    }

    /**
     * Sets if this SectionPlanesOverview is visible.
     *
     * @param {Boolean} visible Whether or not this SectionPlanesOverview is visible.
     */
    setVisible(visible = true) {
        this._visible = visible;
        this._canvas.style.visibility = visible ? "visible" : "hidden";
    }

    /**
     * Gets if this SectionPlanesOverview is visible.
     *
     * @return {Boolean} True when this SectionPlanesOverview is visible.
     */
    getVisible() {
        return this._visible;
    }

    /**  @private
     */
    destroy() {
        this._viewer.camera.off(this._onViewerCameraMatrix);
        this._viewer.camera.off(this._onViewerCameraWorldAxis);
        this._viewer.camera.perspective.off(this._onViewerCameraFOV);
        this._viewer.camera.off(this._onViewerCameraProjection);

        this._scene.input.off(this._onInputMouseMove);
        this._scene.canvas.canvas.removeEventListener("mouseup", this._onCanvasMouseUp);
        this._scene.canvas.canvas.removeEventListener("mouseout", this._onCanvasMouseOut);
        this._scene.destroy();
    }
}

export {Overview};

