import {math} from "../math/math.js";

/**
 * @desc Saves and restores the state of a {@link Scene}'s {@link Camera}.
 *
 * ## Usage
 *
 * In the example below, we'll create a {@link Viewer} and use an {@link XKTLoaderPlugin} to load an ````.xkt```` model. When the model has loaded, we'll save a snapshot of the {@link Camera} state in an CameraMemento. Then we'll move the Camera, and then we'll restore its original state again from the CameraMemento.
 *
 * ````javascript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {CameraMemento} from "../src/scene/mementos/CameraMemento.js";
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
 * // Set camera
 * viewer.camera.eye = [-2.56, 8.38, 8.27];
 * viewer.camera.look = [13.44, 3.31, -14.83];
 * viewer.camera.up = [0.10, 0.98, -0.14];
 *
 * model.on("loaded", () => {
 *
 *      // Model has loaded
 *
 *      // Save memento of camera state
 *      const cameraMemento = new CameraMemento();
 *
 *      cameraMemento.saveCamera(viewer.scene);
 *
 *      // Move the camera
 *      viewer.camera.eye = [45.3, 2.00, 5.13];
 *      viewer.camera.look = [0.0, 5.5, 10.0];
 *      viewer.camera.up = [0.10, 0.98, -0.14];
 *
 *      // Restore the camera state again
 *      objectsMemento.restoreCamera(viewer.scene);
 * });
 * ````
 */
class CameraMemento {

    /**
     * Creates a CameraState.
     *
     * @param {Scene} [scene] When given, immediately saves the state of the given {@link Scene}'s {@link Camera}.
     */
    constructor(scene) {

        /** @private */
        this._eye = math.vec3();

        /** @private */
        this._look = math.vec3();

        /** @private */
        this._up = math.vec3();

        /** @private */
        this._projection = {};

        if (scene) {
            this.saveCamera(scene);
        }
    }

    /**
     * Saves the state of the given {@link Scene}'s {@link Camera}.
     *
     * @param {Scene} scene The scene that contains the {@link Camera}.
     */
    saveCamera(scene) {

        const camera = scene.camera;
        const project = camera.project;

        this._eye.set(camera.eye);
        this._look.set(camera.look);
        this._up.set(camera.up);

        switch (camera.projection) {

            case "perspective":
                this._projection = {
                    projection: "perspective",
                    fov: project.fov,
                    fovAxis: project.fovAxis,
                    near: project.near,
                    far: project.far
                };
                break;

            case "ortho":
                this._projection = {
                    projection: "ortho",
                    scale: project.scale,
                    near: project.near,
                    far: project.far
                };
                break;

            case "frustum":
                this._projection = {
                    projection: "frustum",
                    left: project.left,
                    right: project.right,
                    top: project.top,
                    bottom: project.bottom,
                    near: project.near,
                    far: project.far
                };
                break;

            case "custom":
                this._projection = {
                    projection: "custom",
                    matrix: project.matrix.slice()
                };
                break;
        }
    }

    /**
     * Restores a {@link Scene}'s {@link Camera} to the state previously captured with {@link CameraMemento#saveCamera}.
     *
     * @param {Scene} scene The scene.
     * @param {Function} [done] When this callback is given, will fly the {@link Camera} to the saved state then fire the callback. Otherwise will just jump the Camera to the saved state.
     */
    restoreCamera(scene, done) {

        const camera = scene.camera;
        const savedProjection = this._projection;

        function restoreProjection() {

            switch (savedProjection.type) {

                case "perspective":
                    camera.perspective.fov = savedProjection.fov;
                    camera.perspective.fovAxis = savedProjection.fovAxis;
                    camera.perspective.near = savedProjection.near;
                    camera.perspective.far = savedProjection.far;
                    break;

                case "ortho":
                    camera.ortho.scale = savedProjection.scale;
                    camera.ortho.near = savedProjection.near;
                    camera.ortho.far = savedProjection.far;
                    break;

                case "frustum":
                    camera.frustum.left = savedProjection.left;
                    camera.frustum.right = savedProjection.right;
                    camera.frustum.top = savedProjection.top;
                    camera.frustum.bottom = savedProjection.bottom;
                    camera.frustum.near = savedProjection.near;
                    camera.frustum.far = savedProjection.far;
                    break;

                case "custom":
                    camera.customProjection.matrix = savedProjection.matrix;
                    break;
            }
        }

        if (done) {
            scene.viewer.cameraFlight.flyTo({
                eye: this._eye,
                look: this._look,
                up: this._up,
                orthoScale: savedProjection.scale,
                projection: savedProjection.projection
            }, () => {
                restoreProjection();
                done();
            });
        } else {
            camera.eye = this._eye;
            camera.look = this._look;
            camera.up = this._up;
            restoreProjection();
            camera.projection = savedProjection.projection;
        }
    }
}

export {CameraMemento};