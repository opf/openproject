import {Plugin} from "../../viewer/Plugin.js";
import {Scene} from "../../viewer/scene/scene/Scene.js";
import {AmbientLight} from "../../viewer/scene/lights/AmbientLight.js";
import {DirLight} from "../../viewer/scene/lights/DirLight.js";
import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {buildCylinderGeometry} from "../../viewer/scene/geometry/builders/buildCylinderGeometry.js";
import {buildSphereGeometry} from "../../viewer/scene/geometry/builders/buildSphereGeometry.js";
import {buildVectorTextGeometry} from "../../viewer/scene/geometry/builders/buildVectorTextGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {math} from "../../viewer/scene/math/math.js";

/**
 * {@link Viewer} plugin that shows the axii of the World-space coordinate system.
 *
 * ## Usage
 *
 * [[Run this example](https://xeokit.github.io/xeokit-sdk/examples/#gizmos_AxisGizmoPlugin)]
 *
 * ````JavaScript````
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 * import {AxisGizmoPlugin} from "../src/plugins/AxisGizmoPlugin/AxisGizmoPlugin.js";
 *
 * const viewer = new Viewer({
 *     canvasId: "myCanvas"
 * });
 *
 * const gltfLoader = new GLTFLoaderPlugin(viewer);
 *
 * new AxisGizmoPlugin(viewer, {size: [250, 250]});
 *
 * const model = gltfLoader.load({
 *     id: "myModel",
 *     src: "./models/gltf/schependomlaan/scene.gltf",
 *     metaModelSrc: "./metaModels/schependomlaan/metaModel.json",
 *     edges: true
 * });
 *
 * const scene = viewer.scene;
 * const camera = scene.camera;
 *
 * camera.orbitPitch(20);
 *
 * model.on("loaded", () => {
 *     viewer.cameraFlight.jumpTo(modelNode);
 *     scene.on("tick", () => {
 *        camera.orbitYaw(0.4);
 *     })
 * });
 * ````
 */
class AxisGizmoPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="AxisGizmo"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {Number[]} [cfg.size=[250,250]] Initial size in pixels.
     */
    constructor(viewer, cfg) {

        cfg = cfg || {};

        super("AxisGizmo", viewer, cfg);

        var camera = viewer.scene.camera;

        var size = cfg.size || [250, 250];

        var canvas = camera.scene.canvas;

        // Create canvas for this gizmo

        var canvasId = "xeokit-axisHelper-canvas-" + math.createUUID();
        var body = document.getElementsByTagName("body")[0];
        var div = document.createElement('div');
        var style = div.style;
        style.height = size[0] + "px";
        style.width = size[1] + "px";
        style.padding = "0";
        style.margin = "0";
        style.float = "left";
        style.left = "410px";
        style.bottom = "350px";
        style.position = "absolute";
        style["z-index"] = "1000000";
        // style["background-color"] = "rgba(0,0,0,0.3)";
        div.innerHTML += '<canvas id="' + canvasId + '" style="width: ' + size[0] + 'px; height: ' + size[1] + 'px; float: left; margin: 0; padding: 0;"></canvas>';
        body.appendChild(div);

        canvas.on("boundary",
            function (boundary) {
                style.left = boundary[0] + 10 + "px";
                style.bottom = (boundary[0] + 20) + "px";
            });

        // The scene containing this helper
        var scene = new Scene({
            canvasId: canvasId,
            transparent: true
        });

        // Custom lights
        scene.clearLights();

        new AmbientLight(scene, {
            color: [0.45, 0.45, 0.5],
            intensity: 0.9
        });

        new DirLight(scene, {
            dir: [-0.5, 0.5, -0.6],
            color: [0.8, 0.8, 0.7],
            intensity: 1.0,
            space: "view"
        });

        new DirLight(scene, {
            dir: [0.5, -0.5, -0.6],
            color: [0.8, 0.8, 0.8],
            intensity: 1.0,
            space: "view"
        });

        // Rotate helper in synch with target camera

        var helperCamera = scene.camera;

        camera.on("matrix", function () {

            var eye = camera.eye;
            var look = camera.look;
            var up = camera.up;

            var eyeLook = math.mulVec3Scalar(math.normalizeVec3(math.subVec3(eye, look, [])), 22);

            helperCamera.look = [0, 0, 0];
            helperCamera.eye = eyeLook;
            helperCamera.up = up;
        });

        // ----------------- Components that are shared among more than one mesh ---------------

        var arrowHead = new ReadableGeometry(scene, buildCylinderGeometry({
            radiusTop: 0.01,
            radiusBottom: 0.6,
            height: 1.7,
            radialSegments: 20,
            heightSegments: 1,
            openEnded: false
        }));

        var arrowShaft = new ReadableGeometry(scene, buildCylinderGeometry({
            radiusTop: 0.2,
            radiusBottom: 0.2,
            height: 4.5,
            radialSegments: 20,
            heightSegments: 1,
            openEnded: false
        }));

        var xAxisMaterial = new PhongMaterial(scene, { // Red by convention
            diffuse: [1, 0.3, 0.3],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });

        var xAxisLabelMaterial = new PhongMaterial(scene, { // Red by convention
            emissive: [1, 0.3, 0.3],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });

        var yAxisMaterial = new PhongMaterial(scene, { // Green by convention
            diffuse: [0.3, 1, 0.3],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });

        var yAxisLabelMaterial = new PhongMaterial(scene, { // Green by convention
            emissive: [0.3, 1, 0.3],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });


        var zAxisMaterial = new PhongMaterial(scene, { // Blue by convention
            diffuse: [0.3, 0.3, 1],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });

        var zAxisLabelMaterial = new PhongMaterial(scene, {
            emissive: [0.3, 0.3, 1],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });

        var ballMaterial = new PhongMaterial(scene, {
            diffuse: [0.5, 0.5, 0.5],
            ambient: [0.0, 0.0, 0.0],
            specular: [.6, .6, .3],
            shininess: 80,
            lineWidth: 2
        });


        // ----------------- Meshes ------------------------------

        this._meshes = [

            // Sphere behind gnomon

            new Mesh(scene, {
                geometry: new ReadableGeometry(scene, buildSphereGeometry({
                    radius: 9.0,
                    heightSegments: 60,
                    widthSegments: 60
                })),
                material: new PhongMaterial(scene, {
                    diffuse: [0.0, 0.0, 0.0],
                    emissive: [0.1, 0.1, 0.1],
                    ambient: [0.1, 0.1, 0.2],
                    specular: [0, 0, 0],
                    alpha: 0.4,
                    alphaMode: "blend",
                    frontface: "cw"
                }),
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false
            }),

            // Ball at center of axis

            new Mesh(scene, {  // Arrow
                geometry: new ReadableGeometry(scene, buildSphereGeometry({
                    radius: 1.0
                })),
                material: ballMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false
            }),

            // X-axis arrow, shaft and label

            new Mesh(scene, {  // Arrow
                geometry: arrowHead,
                material: xAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [-5, 0, 0],
                rotation: [0, 0, 90]
            }),

            new Mesh(scene, {  // Shaft
                geometry: arrowShaft,
                material: xAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [-2, 0, 0],
                rotation: [0, 0, 90]
            }),

            new Mesh(scene, {  // Label
                geometry: new ReadableGeometry(scene, buildVectorTextGeometry({text: "X", size: 1.5})),
                material: xAxisLabelMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [-7, 0, 0],
                billboard: "spherical"
            }),

            // Y-axis arrow, shaft and label

            new Mesh(scene, {  // Arrow
                geometry: arrowHead,
                material: yAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 5, 0]
            }),

            new Mesh(scene, {  // Shaft
                geometry: arrowShaft,
                material: yAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 2, 0]
            }),

            new Mesh(scene, {  // Label
                geometry: new ReadableGeometry(scene, buildVectorTextGeometry({text: "Y", size: 1.5})),
                material: yAxisLabelMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 7, 0],
                billboard: "spherical"
            }),

            // Z-axis arrow, shaft and label

            new Mesh(scene, {  // Arrow
                geometry: arrowHead,
                material: zAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 0, 5],
                rotation: [90, 0, 0]
            }),

            new Mesh(scene, {  // Shaft
                geometry: arrowShaft,
                material: zAxisMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 0, 2],
                rotation: [90, 0, 0]
            }),

            new Mesh(scene, {  // Label
                geometry: new ReadableGeometry(scene, buildVectorTextGeometry({text: "Z", size: 1.5})),
                material: zAxisLabelMaterial,
                pickable: false,
                collidable: false,
                visible: cfg.visible !== false,
                position: [0, 0, 7],
                billboard: "spherical"
            })
        ];
    }

    /** Shows or hides this helper
     *
     * @param visible
     */
    setVisible(visible) {
        for (var i = 0; i < this._meshes.length; i++) {
            this._meshes[i].visible = visible;
        }
    }

    /**
     * Destroys this AxisGizmoPlugin.
     */
    destroy() {
        super.destroy();
    }
}

export {AxisGizmoPlugin}