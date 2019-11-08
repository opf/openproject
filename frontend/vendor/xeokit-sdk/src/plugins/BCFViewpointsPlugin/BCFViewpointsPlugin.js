import {Plugin} from "../../viewer/Plugin.js";
import {SectionPlane} from "../../viewer/scene/sectionPlane/SectionPlane.js";
import {math} from "../../viewer/scene/math/math.js";

const tempVec3 = math.vec3();

/**
 * {@link Viewer} plugin that saves and loads BCF viewpoints as JSON objects.
 *
 * BCF is a format for managing issues on a BIM project. This plugin's viewpoints conform to
 * the <a href="https://github.com/buildingSMART/BCF-API">BCF Version 2.1</a> specification.
 *
 * ## Saving a BCF Viewpoint
 *
 * In the example below we'll create a {@link Viewer}, load a glTF model into it using a {@link GLTFLoaderPlugin},
 * slice the model in half using a {@link SectionPlanesPlugin}, then use a {@link BCFViewpointsPlugin#getViewpoint}
 * to save a viewpoint to JSON, which we'll log to the JavaScript developer console.
 *
 * [[Run this example](http://xeokit.github.io/xeokit-sdk/examples/#BCF_SaveViewpoint)]
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 * import {SectionPlanesPlugin} from "../src/plugins/SectionPlanesPlugin/SectionPlanesPlugin.js";
 * import {BCFViewpointsPlugin} from "../src/plugins/BCFViewpointsPlugin/BCFViewpointsPlugin.js";
 *
 * // Create a Viewer
 * const viewer = new Viewer({
 *      canvasId: "myCanvas",
 *      transparent: true
 * });
 *
 * // Add a GLTFLoaderPlugin
 * const gltfLoader = new GLTFLoaderPlugin(viewer);
 *
 * // Add a SectionPlanesPlugin
 * const sectionPlanes = new SectionPlanesPlugin(viewer);
 *
 * // Add a BCFViewpointsPlugin
 * const bcfViewpoints = new BCFViewpointsPlugin(viewer);
 *
 * // Load a glTF model
 * const modelNode = gltfLoader.load({
 *      id: "myModel",
 *      src: "./models/gltf/schependomlaan/scene.gltf",
 *      metaModelSrc: "./metaModels/schependomlaan/metaModel.json", // Creates a MetaObject instances in scene.metaScene.metaObjects
 *      lambertMaterial: true,
 *      edges: true // Emphasise edges
 * });
 *
 * // Slice it in half
 * sectionPlanes.createSectionPlane({
 *      id: "myClip",
 *      pos: [0, 0, 0],
 *      dir: [0.5, 0.0, 0.5]
 * });
 *
 * // When model is loaded, set camera, select some objects and capture a BCF viewpoint to the console
 * modelNode.on("loaded", () => {
 *
 *      const scene = viewer.scene;
 *      const camera = scene.camera;
 *
 *      camera.eye = [-2.37, 18.97, -26.12];
 *      camera.look = [10.97, 5.82, -11.22];
 *      camera.up = [0.36, 0.83, 0.40];
 *
 *      scene.setObjectsSelected([
 *          "3b2U496P5Ebhz5FROhTwFH",
 *          "2MGtJUm9nD$Re1_MDIv0g2",
 *          "3IbuwYOm5EV9Q6cXmwVWqd",
 *          "3lhisrBxL8xgLCRdxNG$2v",
 *          "1uDn0xT8LBkP15zQc9MVDW"
 *      ], true);
 *
 *      const viewpoint = bcfViewpoints.getViewpoint();
 *      const viewpointStr = JSON.stringify(viewpoint, null, 4);
 *
 *      console.log(viewpointStr);
 * });
 * ````
 *
 * ## Saving View Setup Hints
 *
 * BCFViewpointsPlugin can optionally save hints in the viewpoint, which indicate how to set up the view when
 * loading it again.
 *
 * Here's the {@link BCFViewpointsPlugin#getViewpoint} call again, this time saving some hints:
 *
 * ````javascript
 * const viewpoint = bcfViewpoints.getViewpoint({ // Options
 *     spacesVisible: true, // Force IfcSpace types visible in the viewpoint (default is false)
 *     spaceBoundariesVisible: false, // Show IfcSpace boundaries in the viewpoint (default is false)
 *     openingsVisible: true // Force IfcOpening types visible in the viewpoint (default is false)
 * });
 * ````
 *
 * ## Loading a BCF Viewpoint
 *
 * Assuming that we have our BCF viewpoint in a JSON object, let's now restore it with {@link BCFViewpointsPlugin#setViewpoint}:
 *
 * ````javascript
 * bcfViewpoints.setViewpoint(viewpoint);
 * ````
 *
 * ## Handling BCF Incompatibility with xeokit's Camera
 *
 * xeokit's {@link Camera#look} is the current 3D *point-of-interest* (POI).
 *
 * A BCF viewpoint, however, has a direction vector instead of a POI, and so {@link BCFViewpointsPlugin#getViewpoint} saves
 * xeokit's POI as a normalized vector from {@link Camera#eye} to {@link Camera#look}, which unfortunately loses
 * that positional information. Loading the viewpoint with {@link BCFViewpointsPlugin#setViewpoint} will restore {@link Camera#look} to
 * the viewpoint's camera position, offset by the normalized vector.
 *
 * As shown below, providing a ````rayCast```` option to ````setViewpoint```` will set {@link Camera#look} to the closest
 * surface intersection on the direction vector. Internally, ````setViewpoint```` supports this option by firing a ray
 * along the vector, and if that hits an {@link Entity}, sets {@link Camera#look} to ray's intersection point with the
 * Entity's surface.
 *
 * ````javascript
 * bcfViewpoints.setViewpoint(viewpoint, {
 *      rayCast: true // <<--------------- Attempt to set Camera#look to surface intersection point (default)
 * });
 * ````
 *
 * @class BCFViewpointsPlugin
 */
class BCFViewpointsPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="BCFViewpoints"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {String} [cfg.originatingSystem] Identifies the originating system for BCF records.
     * @param {String} [cfg.authoringTool] Identifies the authoring tool for BCF records.
     */
    constructor(viewer, cfg = {}) {

        super("BCFViewpoints", viewer, cfg);

        /**
         * Identifies the originating system to include in BCF viewpoints saved by this plugin.
         * @property originatingSystem
         * @type {string}
         */
        this.originatingSystem = cfg.originatingSystem || "xeokit";

        /**
         * Identifies the authoring tool to include in BCF viewpoints saved by this plugin.
         * @property authoringTool
         * @type {string}
         */
        this.authoringTool = cfg.authoringTool || "xeokit";
    }

    /**
     * Saves viewer state to a BCF viewpoint.
     *
     * Note that xeokit's {@link Camera#look} is the **point-of-interest**, whereas the BCF ````camera_direction```` is a
     * direction vector. Therefore, we save ````camera_direction```` as the vector from {@link Camera#eye} to {@link Camera#look}.
     *
     * @param {*} [options] Options for getting the viewpoint.
     * @param {Boolean} [options.spacesVisible=false] Indicates whether ````IfcSpace```` types should be forced visible in the viewpoint.
     * @param {Boolean} [options.openingsVisible=false] Indicates whether ````IfcOpening```` types should be forced visible in the viewpoint.
     * @param {Boolean} [options.spaceBoundariesVisible=false] Indicates whether the boundaries of ````IfcSpace```` types should be visible in the viewpoint.
     * @returns {*} BCF JSON viewpoint object
     * @example
     *
     * const viewer = new Viewer();
     *
     * const bcfPlugin = new BCFPlugin(viewer, {
     *     //...
     * });
     *
     * const viewpoint = bcfPlugin.getViewpoint({ // Options - see constructor
     *     spacesVisible: false,          // Default
     *     spaceBoundariesVisible: false, // Default
     *     openingsVisible: false         // Default
     * });
     *
     * // viewpoint will resemble the following:
     *
     * {
     *     perspective_camera: {
     *         camera_view_point: {
     *             x: 0.0,
     *             y: 0.0,
     *             z: 0.0
     *         },
     *         camera_direction: {
     *             x: 1.0,
     *             y: 1.0,
     *             z: 2.0
     *         },
     *         camera_up_vector: {
     *             x: 0.0,
     *             y: 0.0,
     *             z: 1.0
     *         },
     *         field_of_view: 90.0
     *     },
     *     lines: [],
     *     clipping_planes: [{
     *         location: {
     *             x: 0.5,
     *             y: 0.5,
     *             z: 0.5
     *         },
     *         direction: {
     *             x: 1.0,
     *             y: 0.0,
     *             z: 0.0
     *         }
     *     }],
     *     bitmaps: [],
     *     snapshot: {
     *         snapshot_type: png,
     *         snapshot_data: "data:image/png;base64,......"
     *     },
     *     components: {
     *         visibility: {
     *             default_visibility: false,
     *             exceptions: [{
     *                 ifc_guid: 4$cshxZO9AJBebsni$z9Yk,
     *                 originating_system: xeokit.io,
     *                 authoring_tool_id: xeokit/v1.0
     *             }]
     *        },
     *         selection: [{
     *            ifc_guid: "4$cshxZO9AJBebsni$z9Yk",
     *         }]
     *     }
     * }
     */
    getViewpoint(options={}) {

        const scene = this.viewer.scene;
        const camera = scene.camera;

        let bcfViewpoint = {};

        // Camera

        const lookDirection = math.normalizeVec3(math.subVec3(camera.look, camera.eye, math.vec3()));

        bcfViewpoint.perspective_camera = {
            camera_view_point: xyzArrayToObject(camera.eye),
            camera_direction: xyzArrayToObject(lookDirection),
            camera_up_vector: xyzArrayToObject(camera.up),
            field_of_view: camera.perspective.fov,
        };

        bcfViewpoint.orthogonal_camera = {
            camera_view_point: xyzArrayToObject(camera.eye),
            camera_direction: xyzArrayToObject(lookDirection),
            camera_up_vector: xyzArrayToObject(camera.up),
            view_to_world_scale: camera.ortho.scale,
        };

        bcfViewpoint.lines = [];
        bcfViewpoint.bitmaps = [];

        // Clipping planes

        bcfViewpoint.clipping_planes = [];
        const sectionPlanes = scene.sectionPlanes;
        for (let id in sectionPlanes) {
            if (sectionPlanes.hasOwnProperty(id)) {
                let sectionPlane = sectionPlanes[id];
                bcfViewpoint.clipping_planes.push({
                    location: xyzArrayToObject(sectionPlane.pos),
                    direction: xyzArrayToObject(sectionPlane.dir)
                });
            }
        }

        // Entity states

        bcfViewpoint.components = {
            visibility: {
                view_setup_hints: {
                    spaces_visible: !!options.spacesVisible,
                    space_boundaries_visible: !!options.spaceBoundariesVisible,
                    openings_visible: !!options.openingsVisible
                }
            }
        };

        const objectIds = scene.objectIds;
        const visibleObjects = scene.visibleObjects;
        const visibleObjectIds = scene.visibleObjectIds;
        const invisibleObjectIds = objectIds.filter(id => !visibleObjects[id]);
        const selectedObjectIds = scene.selectedObjectIds;

        if (visibleObjectIds.length < invisibleObjectIds.length) {
            bcfViewpoint.components.visibility.exceptions = visibleObjectIds.map(el => this._objectIdToComponent(el));
            bcfViewpoint.components.visibility.default_visibility = false;
        } else {
            bcfViewpoint.components.visibility.exceptions = invisibleObjectIds.map(el => this._objectIdToComponent(el));
            bcfViewpoint.components.visibility.default_visibility = true;
        }

        bcfViewpoint.components.selection = selectedObjectIds.map(el => this._objectIdToComponent(el));

        bcfViewpoint.snapshot = {
            snapshot_type: "png",
            snapshot_data: this.viewer.getSnapshot({format: "png"})
        };

        return bcfViewpoint;
    }

    _objectIdToComponent(objectId) {
        return {
            ifc_guid: objectId,
            originating_system: this.originatingSystem || "xeokit.io",
            authoring_tool_id: this.authoringTool || "xeokit.io"
        };
    }

    /**
     * Sets viewer state to the given BCF viewpoint.
     *
     * Note that xeokit's {@link Camera#look} is the **point-of-interest**, whereas the BCF ````camera_direction```` is a
     * direction vector. Therefore, when loading a BCF viewpoint, we set {@link Camera#look} to the absolute position
     * obtained by offsetting the BCF ````camera_view_point````  along ````camera_direction````.
     *
     * When loading a viewpoint, we also have the option to find {@link Camera#look} as the closest point of intersection
     * (on the surface of any visible and pickable {@link Entity}) with a 3D ray fired from ````camera_view_point```` in
     * the direction of ````camera_direction````.
     *
     * @param {*} bcfViewpoint  BCF JSON viewpoint object or "reset" / "RESET" to reset the viewer, which clears SectionPlanes,
     * shows default visible entities and restores camera to initial default position.
     * @param {*} [options] Options for setting the viewpoint.
     * @param {Boolean} [options.rayCast=true] When ````true```` (default), will attempt to set {@link Camera#look} to the closest
     * point of surface intersection with a ray fired from the BCF ````camera_view_point```` in the direction of ````camera_direction````.
     */
    setViewpoint(bcfViewpoint, options = {}) {

        if (!bcfViewpoint) {
            return;
        }

        const viewer = this.viewer;
        const scene = viewer.scene;
        const camera = scene.camera;
        const rayCast = (options.rayCast !== false);

        scene.clearSectionPlanes();

        if (bcfViewpoint.clipping_planes) {
            bcfViewpoint.clipping_planes.forEach(function (e) {
                new SectionPlane(scene, {
                    pos: xyzObjectToArray(e.location, tempVec3),
                    dir: xyzObjectToArray(e.direction, tempVec3)
                });
            });
        }

        if (bcfViewpoint.components) {

            if (!bcfViewpoint.components.visibility.default_visibility) {
                scene.setObjectsVisible(scene.objectIds, false);
                bcfViewpoint.components.visibility.exceptions.forEach(x => scene.setObjectsVisible(x.ifc_guid, true));
            } else {
                scene.setObjectsVisible(scene.objectIds, true);
                bcfViewpoint.components.visibility.exceptions.forEach(x => scene.setObjectsVisible(x.ifc_guid, false));
            }

            const view_setup_hints = bcfViewpoint.components.visibility.view_setup_hints;
            if (view_setup_hints) {
                if (view_setup_hints.spaces_visible !== undefined) {
                    scene.setObjectsVisible(viewer.metaScene.getObjectIDsByType("IfcSpace"), !!view_setup_hints.spaces_visible);
                }
                if (view_setup_hints.openings_visible !== undefined) {
                    scene.setObjectsVisible(viewer.metaScene.getObjectIDsByType("IfcOpening"), !!view_setup_hints.openings_visible);
                }
                if (view_setup_hints.space_boundaries_visible !== undefined) {
                    // TODO: Ability to show boundaries
                }
            }
        }

        if (bcfViewpoint.components.selection) {
            scene.setObjectsSelected(scene.selectedObjectIds, false);
            Object.keys(scene.models).forEach(() => {
                bcfViewpoint.components.selection.forEach(x => scene.setObjectsSelected(x.ifc_guid, true));
            });
        }

        if (bcfViewpoint.perspective_camera || bcfViewpoint.orthogonal_camera) {

            let eye;
            let look;
            let up;

            if (bcfViewpoint.perspective_camera) {

                eye = xyzObjectToArray(bcfViewpoint.perspective_camera.camera_view_point, tempVec3);
                look = xyzObjectToArray(bcfViewpoint.perspective_camera.camera_direction, tempVec3);
                up = xyzObjectToArray(bcfViewpoint.perspective_camera.camera_up_vector, tempVec3);

                camera.perspective.fov = bcfViewpoint.perspective_camera.field_of_view;
            }

            if (bcfViewpoint.orthogonal_camera) {

                eye = xyzObjectToArray(bcfViewpoint.orthogonal_camera.camera_view_point, tempVec3);
                look = xyzObjectToArray(bcfViewpoint.orthogonal_camera.camera_direction, tempVec3);
                up = xyzObjectToArray(bcfViewpoint.orthogonal_camera.camera_up_vector, tempVec3);

                camera.ortho.scale = bcfViewpoint.orthogonal_camera.field_of_view;
            }

            if (rayCast) {

                const hit = scene.pick({
                    pickSurface: true,  // <<------ This causes picking to find the intersection point on the entity
                    origin: eye,
                    direction: look
                });

                camera.eye = eye;
                camera.look = (hit ? hit.worldPos : math.addVec3(eye, look, tempVec3));
                camera.up = up;

            } else {

                camera.eye = eye;
                camera.look = math.addVec3(eye, look, tempVec3);
                camera.up = up;
            }
        }
    }

    /**
     * Destroys this BCFViewpointsPlugin.
     */
    destroy() {
        super.destroy();
    }
}

function xyzArrayToObject(arr) {
    return {"x": arr[0], "y": arr[1], "z": arr[2]};
}

function xyzObjectToArray(xyz, arry) {
    arry = new Float32Array(3);
    arry[0] = xyz.x;
    arry[1] = xyz.y;
    arry[2] = xyz.z;
    return arry;
}

export {BCFViewpointsPlugin}
