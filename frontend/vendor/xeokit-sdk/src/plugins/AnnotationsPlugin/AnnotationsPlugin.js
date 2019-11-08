import {Plugin} from "../../viewer/Plugin.js";
import {Annotation} from "./Annotation.js";
import {utils} from "../../viewer/scene/utils.js";
import {math} from "../../viewer/scene/math/math.js";

const tempVec3a = math.vec3();
const tempVec3b = math.vec3();
const tempVec3c = math.vec3();

/**
 * {@link Viewer} plugin that creates {@link Annotation}s.
 *
 * [<img src="https://user-images.githubusercontent.com/83100/58403089-26589280-8062-11e9-8652-aed61a4e8c64.gif">](https://xeokit.github.io/xeokit-sdk/examples/#annotations_clickFlyToPosition)
 *
 * * [[Example 1: Create annotations with mouse](https://xeokit.github.io/xeokit-sdk/examples/#annotations_createWithMouse)]
 * * [[Example 2: Click annotations to toggle labels](https://xeokit.github.io/xeokit-sdk/examples/#annotations_clickShowLabels)]
 * * [[Example 3: Hover annotations to show labels](https://xeokit.github.io/xeokit-sdk/examples/#annotations_hoverShowLabels)]
 * * [[Example 4: Click annotations to fly to viewpoint](https://xeokit.github.io/xeokit-sdk/examples/#annotations_clickFlyToPosition)]
 * * [[Example 5: Create Annotations with externally-created elements](https://xeokit.github.io/xeokit-sdk/examples/#annotations_externalElements)]
 *
 * ## Overview
 *
 * * An {@link Annotation} is a 3D position with a label attached.
 * * Annotations render themselves with HTML elements that float over the canvas; customize the appearance of
 * individual Annotations using HTML template; configure default appearance by setting templates on the AnnotationsPlugin.
 * * Dynamically insert data values into each Annotation's HTML templates; configure default values on the AnnotationsPlugin.
 * * Optionally configure Annotation with externally-created DOM elements for markers and labels; these override templates and data values.
 * * Optionally configure Annotations to hide themselves whenever occluded by {@link Entity}s.
 * * Optionally configure each Annotation with a position we can jump or fly the {@link Camera} to.
 *
 * ## Example 1: Loading a model and creating an annotation
 *
 * In the example below, we'll use a {@link GLTFLoaderPlugin} to load a model, and an AnnotationsPlugin
 * to create an {@link Annotation} on it.
 *
 * We'll configure the AnnotationsPlugin with default HTML templates for each Annotation's position (its "marker") and
 * label, along with some default data values to insert into them.
 *
 * When we create our Annotation, we'll give it some specific data values to insert into the templates, overriding some of
 * the defaults we configured on the plugin. Note the correspondence between the placeholders in the templates
 * and the keys in the values map.
 *
 * We'll also configure the Annotation to hide itself whenever it's position is occluded by any {@link Entity}s (this is default behavior). The
 * {@link Scene} periodically occlusion-tests all Annotations on every 20th "tick" (which represents a rendered frame). We
 * can adjust that frequency via property {@link Scene#ticksPerOcclusionTest}.
 *
 * Finally, we'll query the Annotation's position occlusion/visibility status, and subscribe to change events on those properties.
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#annotations_clickShowLabels)]
 *
 * ````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {GLTFLoaderPlugin} from "../src/plugins/GLTFLoaderPlugin/GLTFLoaderPlugin.js";
 * import {AnnotationsPlugin} from "../src/plugins/AnnotationsPlugin/AnnotationsPlugin.js";
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
 * const gltfLoader = new GLTFLoaderPlugin(viewer);
 *
 * const annotations = new AnnotationsPlugin(viewer, {
 *
 *      // Default HTML template for marker position
 *      markerHTML: "<div class='annotation-marker' style='background-color: {{markerBGColor}};'>{{glyph}}</div>",
 *
 *      // Default HTML template for label
 *      labelHTML: "<div class='annotation-label' style='background-color: {{labelBGColor}};'>" +
 *      "<div class='annotation-title'>{{title}}</div><div class='annotation-desc'>{{description}}</div></div>",
 *
 *      // Default values to insert into the marker and label templates
 *      values: {
 *          markerBGColor: "red",
 *          labelBGColor: "red",
 *          glyph: "X",
 *          title: "Untitled",
 *          description: "No description"
 *      }
 * });
 *
 * const model = gltfLoader.load({
 *      src: "./models/gltf/duplex/scene.gltf"
 * });
 *
 * model.on("loaded", () => {
 *
 *      const entity = viewer.scene.meshes[""];
 *
 *      // Create an annotation
 *      const myAnnotation1 = annotations.createAnnotation({
 *
 *          id: "myAnnotation",
 *
 *          entity: viewer.scene.objects["2O2Fr$t4X7Zf8NOew3FLOH"], // Optional, associate with an Entity
 *
 *          worldPos: [0, 0, 0],        // 3D World-space position
 *
 *          occludable: true,           // Optional, default, makes Annotation invisible when occluded by Entities
 *          markerShown: true,          // Optional, default is true, makes position visible (when not occluded)
 *          labelShown: true            // Optional, default is false, makes label visible (when not occluded)
 *
 *          values: {                   // Optional, overrides AnnotationPlugin's defaults
 *              glyph: "A",
 *              title: "My Annotation",
 *              description: "This is my annotation."
 *          }
 *      });
 *
 *      // Listen for change of the Annotation's 3D World-space position
 *
 *      myAnnotation1.on("worldPos", function(worldPos) {
 *          //...
 *      });
 *
 *      // Listen for change of the Annotation's 3D View-space position, which happens
 *      // when either worldPos was updated or the Camera was moved
 *
 *      myAnnotation1.on("viewPos", function(viewPos) {
 *          //...
 *      });
 *
 *      // Listen for change of the Annotation's 2D Canvas-space position, which happens
 *      // when worldPos or viewPos was updated, or Camera's projection was updated
 *
 *      myAnnotation1.on("canvasPos", function(canvasPos) {
 *          //...
 *      });
 *
 *      // Listen for change of Annotation visibility. The Annotation becomes invisible when it falls outside the canvas,
 *      // or its position is occluded by some Entity. Note that, when not occluded, the position is only
 *      // shown when Annotation#markerShown is true, and the label is only shown when Annotation#labelShown is true.
 *
 *      myAnnotation1.on("visible", function(visible) { // Marker visibility has changed
 *          if (visible) {
 *              this.log("Annotation is visible");
 *          } else {
 *              this.log("Annotation is invisible");
 *          }
 *      });
 *
 *      // Listen for destruction of the Annotation
 *
 *      myAnnotation1.on("destroyed", () => {
 *          //...
 *      });
 * });
 * ````
 *
 * Let's query our {@link Annotation}'s current position in the World, View and Canvas coordinate systems:
 *
 * ````javascript
 * const worldPos  = myAnnotation.worldPos;  // [x,y,z]
 * const viewPos   = myAnnotation.viewPos;   // [x,y,z]
 * const canvasPos = myAnnotation.canvasPos; // [x,y]
 * ````
 *
 * We can query it's current visibility, which is ````false```` when its position is occluded by some {@link Entity}:
 *
 * ````
 * const visible = myAnnotation1.visible;
 * ````
 *
 * To listen for change events on our Annotation's position and visibility:
 *
 * ````javascript
 * // World-space position changes when we assign a new value to Annotation#worldPos
 * myAnnotation1.on("worldPos", (worldPos) => {
 *     //...
 * });
 *
 * // View-space position changes when either worldPos was updated or the Camera was moved
 * myAnnotation1.on("viewPos", (viewPos) => {
 *     //...
 * });
 *
 * // Canvas-space position changes when worldPos or viewPos was updated, or Camera's projection was updated
 * myAnnotation1.on("canvasPos", (canvasPos) => {
 *     //...
 * });
 *
 * // Annotation is invisible when its position falls off the canvas or is occluded by some Entity
 * myAnnotation1.on("visible", (visible) => {
 *     //...
 * });
 * ````
 *
 * Finally, let's dynamically update the values for a couple of placeholders in our Annotation's label:
 *
 * ```` javascript
 * myAnnotation1.setValues({
 *      title: "Here's a new title",
 *      description: "Here's a new description"
 * });
 * ````
 *
 *
 * ## Example 2: Creating an Annotation with a unique appearance
 *
 * Now let's create a second {@link Annotation}, this time with its own custom HTML label template, which includes
 * an image. In the Annotation's values, we'll also provide a new title and description, custom colors for the marker
 * and label, plus a URL for the image in the label template. To render its marker, the Annotation will fall back
 * on the AnnotationPlugin's default marker template.
 *
 * ````javascript
 * const myAnnotation2 = annotations.createAnnotation({
 *
 *      id: "myAnnotation2",
 *
 *      worldPos: [-0.163, 1.810, 7.977],
 *
 *      occludable: true,
 *      markerShown: true,
 *      labelShown: true,
 *
 *      // Custom label template is the same as the Annotation's, with the addition of an image element
 *      labelHTML: "<div class='annotation-label' style='background-color: {{labelBGColor}};'>\
 *          <div class='annotation-title'>{{title}}</div>\
 *          <div class='annotation-desc'>{{description}}</div>\
 *          <br><img alt='myImage' width='150px' height='100px' src='{{imageSrc}}'>\
 *          </div>",
 *
 *      // Custom template values override all the AnnotationPlugin's defaults, and includes an additional value
 *      // for the image element's URL
 *      values: {
 *          glyph: "A3",
 *          title: "The West wall",
 *          description: "Annotations can contain<br>custom HTML like this<br>image:",
 *          markerBGColor: "green",
 *          labelBGColor: "green",
 *          imageSrc: "https://xeokit.io/img/docs/BIMServerLoaderPlugin/schependomlaan.png"
 *      }
 * });
 * ````
 *
 * ## Example 3: Creating an Annotation with a camera position
 *
 * We can optionally configure each {@link Annotation} with a position to fly or jump the {@link Camera} to.
 *
 * Let's create another Annotation, this time providing it with ````eye````, ````look```` and ````up```` properties
 * indicating a viewpoint on whatever it's annotating:
 *
 * ````javascript
 * const myAnnotation3 = annotations.createAnnotation({
 *
 *      id: "myAnnotation3",
 *
 *      worldPos: [-0.163, 3.810, 7.977],
 *
 *      eye: [0,0,-10],
 *      look: [-0.163, 3.810, 7.977],
 *      up: [0,1,0];
 *
 *      occludable: true,
 *      markerShown: true,
 *      labelShown: true,
 *
 *      labelHTML: "<div class='annotation-label' style='background-color: {{labelBGColor}};'>\
 *          <div class='annotation-title'>{{title}}</div>\
 *          <div class='annotation-desc'>{{description}}</div>\
 *          <br><img alt='myImage' width='150px' height='100px' src='{{imageSrc}}'>\
 *          </div>",
 *
 *      values: {
 *          glyph: "A3",
 *          title: "The West wall",
 *          description: "Annotations can contain<br>custom HTML like this<br>image:",
 *          markerBGColor: "green",
 *          labelBGColor: "green",
 *          imageSrc: "https://xeokit.io/img/docs/BIMServerLoaderPlugin/schependomlaan.png"
 *      }
 * });
 * ````
 *
 * Now we can fly the {@link Camera} to the Annotation's viewpoint, like this:
 *
 * ````javascript
 * viewer.cameraFlight.flyTo(myAnnotation3);
 * ````
 *
 * Or jump the Camera, like this:
 *
 * ````javascript
 * viewer.cameraFlight.jumpTo(myAnnotation3);
 * ````
 *
 * ## Example 4: Creating an Annotation using externally-created DOM elements
 *
 * Now let's create another {@link Annotation}, this time providing it with pre-existing DOM elements for its marker
 * and label. Note that AnnotationsPlugin will ignore any ````markerHTML````, ````labelHTML````
 * or ````values```` properties when provide  ````markerElementId```` or ````labelElementId````.
 *
 * ````javascript
 * const myAnnotation2 = annotations.createAnnotation({
 *
 *      id: "myAnnotation2",
 *
 *      worldPos: [-0.163, 1.810, 7.977],
 *
 *      occludable: true,
 *      markerShown: true,
 *      labelShown: true,
 *
 *      markerElementId: "myMarkerElement",
 *      labelElementId: "myLabelElement"
 * });
 * ````
 *
 * ## Example 5: Creating annotations by clicking on objects
 *
 * AnnotationsPlugin makes it easy to create {@link Annotation}s on the surfaces of {@link Entity}s as we click on them.
 *
 * The {@link AnnotationsPlugin#createAnnotation} method can accept a {@link PickResult} returned
 * by {@link Scene#pick}, from which it initializes the {@link Annotation}'s {@link Annotation#worldPos} and
 * {@link Annotation#entity}. Note that this only works when {@link Scene#pick} was configured to perform a 3D
 * surface-intersection pick (see {@link Scene#pick} for more info).
 *
 * Let's now extend our example to create an Annotation wherever we click on the surface of of our model:
 *
 * [[Run example](https://xeokit.github.io/xeokit-sdk/examples/#annotations_createWithMouse)]
 *
 * ````javascript
 * var i = 1; // Used to create unique Annotation IDs
 *
 * viewer.scene.input.on("mouseclicked", (coords) => {
 *
 *     var pickRecord = viewer.scene.pick({
 *         canvasPos: coords,
 *         pickSurface: true  // <<------ This causes picking to find the intersection point on the entity
 *     });
 *
 *     if (pickRecord) {
 *
 *         const annotation = annotations.createAnnotation({
 *              id: "myAnnotationOnClick" + i,
 *              pickRecord: pickRecord,
 *              occludable: true,           // Optional, default is true
 *              markerShown: true,          // Optional, default is true
 *              labelShown: true,           // Optional, default is true
 *              values: {                   // HTML template values
 *                  glyph: "A" + i,
 *                  title: "My annotation " + i,
 *                  description: "My description " + i
 *              },
           });
 *
 *         i++;
 *      }
 * });
 * ````
 */
class AnnotationsPlugin extends Plugin {

    /**
     * @constructor
     * @param {Viewer} viewer The Viewer.
     * @param {Object} cfg  Plugin configuration.
     * @param {String} [cfg.id="Annotations"] Optional ID for this plugin, so that we can find it within {@link Viewer#plugins}.
     * @param {String} [cfg.markerHTML] HTML text template for Annotation markers. Defaults to ````<div></div>````. Ignored on {@link Annotation}s configured with a ````markerElementId````.
     * @param {String} [cfg.labelHTML] HTML text template for Annotation labels. Defaults to ````<div></div>````.  Ignored on {@link Annotation}s configured with a ````labelElementId````.
     * @param {HTMLElement} [cfg.container] Container DOM element for markers and labels. Defaults to ````document.body````.
     * @param  {{String:(String|Number)}} [cfg.values={}] Map of default values to insert into the HTML templates for the marker and label.
     */
    constructor(viewer, cfg) {

        super("Annotations", viewer);

        this._labelHTML = cfg.labelHTML || "<div></div>";
        this._markerHTML = cfg.markerHTML || "<div></div>";
        this._container = cfg.container || document.body;
        this._values = cfg.values || {};

        /**
         * The {@link Annotation}s created by {@link AnnotationsPlugin#createAnnotation}, each mapped to its {@link Annotation#id}.
         * @type {{String:Annotation}}
         */
        this.annotations = {};
    }

    /**
     * @private
     */
    send(name, value) {
        switch (name) {
            case "clearAnnotations":
                this.clear();
                break;
        }
    }

    /**
     * Creates an {@link Annotation}.
     *
     * The Annotation is then registered by {@link Annotation#id} in {@link AnnotationsPlugin#annotations}.
     *
     * @param {Object} params Annotation configuration.
     * @param {String} params.id Unique ID to assign to {@link Annotation#id}. The Annotation will be registered by this in {@link AnnotationsPlugin#annotations} and {@link Scene.components}. Must be unique among all components in the {@link Viewer}.
     * @param {String} [params.markerElementId] ID of pre-existing DOM element to render the marker. This overrides ````markerHTML```` and does not support ````values```` (data is baked into the label DOM element).
     * @param {String} [params.labelElementId] ID of pre-existing DOM element to render the label. This overrides ````labelHTML```` and does not support ````values```` (data is baked into the label DOM element).
     * @param {String} [params.markerHTML] HTML text template for the Annotation marker. Defaults to the marker HTML given to the AnnotationsPlugin constructor. Ignored if you provide ````markerElementId````.
     * @param {String} [params.labelHTML] HTML text template for the Annotation label. Defaults to the label HTML given to the AnnotationsPlugin constructor. Ignored if you provide ````labelElementId````.
     * @param {Number[]} [params.worldPos=[0,0,0]] World-space position of the Annotation marker, assigned to {@link Annotation#worldPos}.
     * @param {Entity} [params.entity] Optional {@link Entity} to associate the Annotation with. Causes {@link Annotation#visible} to be ````false```` whenever {@link Entity#visible} is also ````false````.
     * @param {PickResult} [params.pickResult] Sets the Annotation's World-space position and direction vector from the given {@link PickResult}'s {@link PickResult#worldPos} and {@link PickResult#worldNormal}, and the Annotation's Entity from {@link PickResult#entity}. Causes ````worldPos```` and ````entity```` parameters to be ignored, if they are also given.
     * @param {Boolean} [params.occludable=false] Indicates whether or not the {@link Annotation} marker and label are hidden whenever the marker occluded by {@link Entity}s in the {@link Scene}. The
     * {@link Scene} periodically occlusion-tests all Annotations on every 20th "tick" (which represents a rendered frame). We can adjust that frequency via property {@link Scene#ticksPerOcclusionTest}.
     * @param  {{String:(String|Number)}} [params.values={}] Map of values to insert into the HTML templates for the marker and label. These will be inserted in addition to any values given to the AnnotationsPlugin constructor.
     * @param {Boolean} [params.markerShown=true] Whether to initially show the {@link Annotation} marker.
     * @param {Boolean} [params.labelShown=false] Whether to initially show the {@link Annotation} label.
     * @param {Number[]} [params.eye] Optional World-space position for {@link Camera#eye}, used when this Annotation is associated with a {@link Camera} position.
     * @param {Number[]} [params.look] Optional World-space position for {@link Camera#look}, used when this Annotation is associated with a {@link Camera} position.
     * @param {Number[]} [params.up] Optional World-space position for {@link Camera#up}, used when this Annotation is associated with a {@link Camera} position.
     * @param {String} [params.projection] Optional projection type for {@link Camera#projection}, used when this Annotation is associated with a {@link Camera} position.
     * @returns {Annotation} The new {@link Annotation}.
     */
    createAnnotation(params) {
        if (this.viewer.scene.components[params.id]) {
            this.error("Viewer component with this ID already exists: " + params.id);
            delete params.id;
        }
        var worldPos;
        var entity;
        params.pickResult = params.pickResult || params.pickRecord;
        if (params.pickResult) {
            const pickResult = params.pickResult;
            if (!pickResult.worldPos || !pickResult.worldNormal) {
                this.error("Param 'pickResult' does not have both worldPos and worldNormal");
            } else {
                const normalizedWorldNormal = math.normalizeVec3(pickResult.worldNormal, tempVec3a);
                const offsetVec = math.mulVec3Scalar(normalizedWorldNormal, 0.2, tempVec3b);
                const offsetWorldPos = math.addVec3(pickResult.worldPos, offsetVec, tempVec3c);
                worldPos = offsetWorldPos;
                entity = pickResult.entity;
            }
        } else {
            worldPos = params.worldPos;
            entity = params.entity;
        }

        var markerElement = null;
        if (params.markerElementId) {
            markerElement = document.getElementById(params.markerElementId);
            if (!markerElement) {
                this.error("Can't find DOM element for 'markerElementId' value '" + params.markerElementId + "' - defaulting to internally-generated empty DIV");
            }
        }

        var labelElement = null;
        if (params.labelElementId) {
            labelElement = document.getElementById(params.labelElementId);
            if (!labelElement) {
                this.error("Can't find DOM element for 'labelElementId' value '" + params.labelElementId + "' - defaulting to internally-generated empty DIV");
            }
        }

        const annotation = new Annotation(this.viewer.scene, {
            id: params.id,
            plugin: this,
            entity: entity,
            worldPos: worldPos,
            container: this._container,
            markerElement: markerElement,
            labelElement: labelElement,
            markerHTML: params.markerHTML || this._markerHTML,
            labelHTML: params.labelHTML || this._labelHTML,
            occludable: params.occludable,
            values: utils.apply(params.values, utils.apply(this._values, {})),
            markerShown: params.markerShown,
            labelShown: params.labelShown,
            eye: params.eye,
            look: params.look,
            up: params.up,
            projection: params.projection
        });
        this.annotations[annotation.id] = annotation;
        annotation.on("destroyed", () => {
            delete this.annotations[annotation.id];
        });
        return annotation;
    }

    /**
     * Destroys an {@link Annotation}.
     *
     * @param {String} id ID of Annotation to destroy.
     */
    destroyAnnotation(id) {
        var annotation = this.annotations[id];
        if (!annotation) {
            this.log("Annotation not found: " + id);
            return;
        }
        annotation.destroy();
    }

    /**
     * Destroys all {@link Annotation}s.
     */
    clear() {
        const ids = Object.keys(this.annotations);
        for (var i = 0, len = ids.length; i < len; i++) {
            this.destroyAnnotation(ids[i]);
        }
    }

    /**
     * Destroys this AnnotationsPlugin.
     *
     * Destroys all {@link Annotation}s first.
     */
    destroy() {
        this.clear();
        super.destroy();
    }
}

export {AnnotationsPlugin}
