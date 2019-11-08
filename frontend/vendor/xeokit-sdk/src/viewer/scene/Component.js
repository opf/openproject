import {core} from "./core.js";
import {utils} from './utils.js';
import {Map} from "./utils/Map.js";

/**
 * @desc Base class for all xeokit components.
 *
 * ## Component IDs
 *
 * Every Component has an ID that's unique within the parent {@link Scene}. xeokit generates
 * the IDs automatically by default, however you can also specify them yourself. In the example below, we're creating a
 * scene comprised of {@link Scene}, {@link Material}, {@link ReadableGeometry} and
 * {@link Mesh} components, while letting xeokit generate its own ID for
 * the {@link ReadableGeometry}:
 *
 *````JavaScript
 * import {Viewer} from "../src/viewer/Viewer.js";
 * import {Mesh} from "../src/scene/mesh/Mesh.js";
 * import {buildTorusGeometry} from "../src/scene/geometry/builders/buildTorusGeometry.js";
 * import {ReadableGeometry} from "../src/scene/geometry/ReadableGeometry.js";
 * import {PhongMaterial} from "../src/scene/materials/PhongMaterial.js";
 * import {Texture} from "../src/scene/materials/Texture.js";
 * import {Fresnel} from "../src/scene/materials/Fresnel.js";
 *
 * const viewer = new Viewer({
 *        canvasId: "myCanvas"
 *    });
 *
 * viewer.scene.camera.eye = [0, 0, 5];
 * viewer.scene.camera.look = [0, 0, 0];
 * viewer.scene.camera.up = [0, 1, 0];
 *
 * new Mesh(viewer.scene, {
 *      geometry: new ReadableGeometry(viewer.scene, buildTorusGeometry({
 *          center: [0, 0, 0],
 *          radius: 1.5,
 *          tube: 0.5,
 *          radialSegments: 32,
 *          tubeSegments: 24,
 *          arc: Math.PI * 2.0
 *      }),
 *      material: new PhongMaterial(viewer.scene, {
 *          id: "myMaterial",
 *          ambient: [0.9, 0.3, 0.9],
 *          shininess: 30,
 *          diffuseMap: new Texture(viewer.scene, {
 *              src: "textures/diffuse/uvGrid2.jpg"
 *          }),
 *          specularFresnel: new Fresnel(viewer.scene, {
 *              leftColor: [1.0, 1.0, 1.0],
 *              rightColor: [0.0, 0.0, 0.0],
 *              power: 4
 *          })
 *     })
 * });
 *````
 *
 * We can then find those components like this:
 *
 * // Find the Material
 * var material = viewer.scene.components["myMaterial"];
 *
 * // Find all PhongMaterials in the Scene
 * var phongMaterials = viewer.scene.types["PhongMaterial"];
 *
 * // Find our Material within the PhongMaterials
 * var materialAgain = phongMaterials["myMaterial"];
 * ````
 *
 * ## Logging
 *
 * Components have methods to log ID-prefixed messages to the JavaScript console:
 *
 * ````javascript
 * material.log("Everything is fine, situation normal.");
 * material.warn("Wait, whats that red light?");
 * material.error("Aw, snap!");
 * ````
 *
 * The logged messages will look like this in the console:
 *
 * ````text
 * [LOG]   myMaterial: Everything is fine, situation normal.
 * [WARN]  myMaterial: Wait, whats that red light..
 * [ERROR] myMaterial: Aw, snap!
 * ````
 *
 * ## Destruction
 *
 * Get notification of destruction of Components:
 *
 * ````javascript
 * material.once("destroyed", function() {
 *     this.log("Component was destroyed: " + this.id);
 * });
 * ````
 *
 * Or get notification of destruction of any Component within its {@link Scene}:
 *
 * ````javascript
 * scene.on("componentDestroyed", function(component) {
 *     this.log("Component was destroyed: " + component.id);
 * });
 * ````
 *
 * Then destroy a component like this:
 *
 * ````javascript
 * material.destroy();
 * ````
 */
class Component {

    /**
     @private
     */
    get type() {
        return "Component";
    }

    /**
     * @private
     */
    get isComponent() {
        return true;
    }

    constructor(owner = null, cfg = {}) {

        /**
         * The parent {@link Scene} that contains this Component.
         *
         * @property scene
         * @type {Scene}
         * @final
         */
        this.scene = null;

        if (this.type === "Scene") {
            this.scene = this;
            /**
             * The viewer that contains this Scene.
             * @property viewer
             * @type {Viewer}
             */
            this.viewer = cfg.viewer;
        } else {
            if (owner.type === "Scene") {
                this.scene = owner;
            } else if (owner instanceof Component) {
                this.scene = owner.scene;
            } else {
                throw "Invalid param: owner must be a Component"
            }
            this._owner = owner;
            this._renderer = this.scene._renderer;
        }

        this._dontClear = !!cfg.dontClear; // Prevent Scene#clear from destroying this component

        this._renderer = this.scene._renderer;

        /**
         Arbitrary, user-defined metadata on this component.

         @property metadata
         @type Object
         */
        this.meta = cfg.meta || {};

        /**
         * ID of this Component, unique within the {@link Scene}.
         *
         * Components are mapped by this ID in {@link Scene#components}.
         *
         * @property id
         * @type {String|Number}
         */
        this.id = cfg.id; // Auto-generated by Scene by default

        /**
         True as soon as this Component has been destroyed

         @property destroyed
         @type {Boolean}
         */
        this.destroyed = false;

        this._attached = {}; // Attached components with names.
        this._attachments = null; // Attached components keyed to IDs - lazy-instantiated
        this._subIdMap = null; // Subscription subId pool
        this._subIdEvents = null; // Subscription subIds mapped to event names
        this._eventSubs = null; // Event names mapped to subscribers
        this._events = null; // Maps names to events
        this._eventCallDepth = 0; // Helps us catch stack overflows from recursive events
        this._ownedComponents = null; // // Components created with #create - lazy-instantiated

        if (this !== this.scene) { // Don't add scene to itself
            this.scene._addComponent(this); // Assigns this component an automatic ID if not yet assigned
        }

        this._updateScheduled = false; // True when #_update will be called on next tick

        if (owner) {
            owner._own(this);
        }
    }

    // /**
    //  * Unique ID for this Component within its {@link Scene}.
    //  *
    //  * @property
    //  * @type {String}
    //  */
    // get id() {
    //     return this._id;
    // }

    /**
     Indicates that we need to redraw the scene.

     This is called by certain subclasses after they have made some sort of state update that requires the
     renderer to perform a redraw.

     For example: a {@link Mesh} calls this on itself whenever you update its
     {@link Mesh#layer} property, which manually controls its render order in
     relation to other Meshes.

     If this component has a ````castsShadow```` property that's set ````true````, then this will also indicate
     that the renderer needs to redraw shadow map associated with this component. Components like
     {@link DirLight} have that property set when they produce light that creates shadows, while
     components like {@link Mesh"}}layer{{/crossLink}} have that property set when they cast shadows.

     @protected
     */
    glRedraw() {
        this._renderer.imageDirty();
        if (this.castsShadow) { // Light source or object
            this._renderer.shadowsDirty();
        }
    }

    /**
     Indicates that we need to re-sort the renderer's state-ordered drawables list.

     For efficiency, the renderer keeps its list of drawables ordered so that runs of the same state updates can be
     combined.  This method is called by certain subclasses after they have made some sort of state update that would
     require re-ordering of the drawables list.

     For example: a {@link DirLight} calls this on itself whenever you update {@link DirLight#dir}.

     @protected
     */
    glResort() {
        this._renderer.needStateSort();
    }

    /**
     * The {@link Component} that owns the lifecycle of this Component, if any.
     *
     * When that component is destroyed, this component will be automatically destroyed also.
     *
     * Will be null if this Component has no owner.
     *
     * @property owner
     * @type {Component}
     */
    get owner() {
        return this._owner;
    }

    /**
     * Tests if this component is of the given type, or is a subclass of the given type.
     * @type {Boolean}
     */
    isType(type) {
        return this.type === type;
    }

    /**
     * Fires an event on this component.
     *
     * Notifies existing subscribers to the event, optionally retains the event to give to
     * any subsequent notifications on the event as they are made.
     *
     * @param {String} event The event type name
     * @param {Object} value The event parameters
     * @param {Boolean} [forget=false] When true, does not retain for subsequent subscribers
     */
    fire(event, value, forget) {
        if (!this._events) {
            this._events = {};
        }
        if (!this._eventSubs) {
            this._eventSubs = {};
        }
        if (forget !== true) {
            this._events[event] = value || true; // Save notification
        }
        const subs = this._eventSubs[event];
        let sub;
        if (subs) { // Notify subscriptions
            for (const subId in subs) {
                if (subs.hasOwnProperty(subId)) {
                    sub = subs[subId];
                    this._eventCallDepth++;
                    if (this._eventCallDepth < 300) {
                        sub.callback.call(sub.scope, value);
                    } else {
                        this.error("fire: potential stack overflow from recursive event '" + event + "' - dropping this event");
                    }
                    this._eventCallDepth--;
                }
            }
        }
    }

    /**
     * Subscribes to an event on this component.
     *
     * The callback is be called with this component as scope.
     *
     * @param {String} event The event
     * @param {Function} callback Called fired on the event
     * @param {Object} [scope=this] Scope for the callback
     * @return {String} Handle to the subscription, which may be used to unsubscribe with {@link #off}.
     */
    on(event, callback, scope) {
        if (!this._events) {
            this._events = {};
        }
        if (!this._subIdMap) {
            this._subIdMap = new Map(); // Subscription subId pool
        }
        if (!this._subIdEvents) {
            this._subIdEvents = {};
        }
        if (!this._eventSubs) {
            this._eventSubs = {};
        }
        let subs = this._eventSubs[event];
        if (!subs) {
            subs = {};
            this._eventSubs[event] = subs;
        }
        const subId = this._subIdMap.addItem(); // Create unique subId
        subs[subId] = {
            callback: callback,
            scope: scope || this
        };
        this._subIdEvents[subId] = event;
        const value = this._events[event];
        if (value !== undefined) { // A publication exists, notify callback immediately
            callback.call(scope || this, value);
        }
        return subId;
    }

    /**
     * Cancels an event subscription that was previously made with {@link Component#on} or {@link Component#once}.
     *
     * @param {String} subId Subscription ID
     */
    off(subId) {
        if (subId === undefined || subId === null) {
            return;
        }
        if (!this._subIdEvents) {
            return;
        }
        const event = this._subIdEvents[subId];
        if (event) {
            delete this._subIdEvents[subId];
            const subs = this._eventSubs[event];
            if (subs) {
                delete subs[subId];
            }
            this._subIdMap.removeItem(subId); // Release subId
        }
    }

    /**
     * Subscribes to the next occurrence of the given event, then un-subscribes as soon as the event is subIdd.
     *
     * This is equivalent to calling {@link Component#on}, and then calling {@link Component#off} inside the callback function.
     *
     * @param {String} event Data event to listen to
     * @param {Function} callback Called when fresh data is available at the event
     * @param {Object} [scope=this] Scope for the callback
     */
    once(event, callback, scope) {
        const self = this;
        const subId = this.on(event,
            function (value) {
                self.off(subId);
                callback.call(scope || this, value);
            },
            scope);
    }

    /**
     * Returns true if there are any subscribers to the given event on this component.
     *
     * @param {String} event The event
     * @return {Boolean} True if there are any subscribers to the given event on this component.
     */
    hasSubs(event) {
        return (this._eventSubs && !!this._eventSubs[event]);
    }

    /**
     * Logs a console debugging message for this component.
     *
     * The console message will have this format: *````[LOG] [<component type> <component id>: <message>````*
     *
     * Also fires the message as a "log" event on the parent {@link Scene}.
     *
     * @param {String} message The message to log
     */
    log(message) {
        message = "[LOG]" + this._message(message);
        window.console.log(message);
        this.scene.fire("log", message);
    }

    _message(message) {
        return " [" + this.type + " " + utils.inQuotes(this.id) + "]: " + message;
    }

    /**
     * Logs a warning for this component to the JavaScript console.
     *
     * The console message will have this format: *````[WARN] [<component type> =<component id>: <message>````*
     *
     * Also fires the message as a "warn" event on the parent {@link Scene}.
     *
     * @param {String} message The message to log
     */
    warn(message) {
        message = "[WARN]" + this._message(message);
        window.console.warn(message);
        this.scene.fire("warn", message);
    }

    /**
     * Logs an error for this component to the JavaScript console.
     *
     * The console message will have this format: *````[ERROR] [<component type> =<component id>: <message>````*
     *
     * Also fires the message as an "error" event on the parent {@link Scene}.
     *
     * @param {String} message The message to log
     */
    error(message) {
        message = "[ERROR]" + this._message(message);
        window.console.error(message);
        this.scene.fire("error", message);
    }

    /**
     * Adds a child component to this.
     *
     * When component not given, attaches the scene's default instance for the given name (if any).
     * Publishes the new child component on this component, keyed to the given name.
     *
     * @param {*} params
     * @param {String} params.name component name
     * @param {Component} [params.component] The component
     * @param {String} [params.type] Optional expected type of base type of the child; when supplied, will
     * cause an exception if the given child is not the same type or a subtype of this.
     * @param {Boolean} [params.sceneDefault=false]
     * @param {Boolean} [params.sceneSingleton=false]
     * @param {Function} [params.onAttached] Optional callback called when component attached
     * @param {Function} [params.onAttached.callback] Callback function
     * @param {Function} [params.onAttached.scope] Optional scope for callback
     * @param {Function} [params.onDetached] Optional callback called when component is detached
     * @param {Function} [params.onDetached.callback] Callback function
     * @param {Function} [params.onDetached.scope] Optional scope for callback
     * @param {{String:Function}} [params.on] Callbacks to subscribe to properties on component
     * @param {Boolean} [params.recompiles=true] When true, fires "dirty" events on this component
     * @private
     */
    _attach(params) {

        const name = params.name;

        if (!name) {
            this.error("Component 'name' expected");
            return;
        }

        let component = params.component;
        const sceneDefault = params.sceneDefault;
        const sceneSingleton = params.sceneSingleton;
        const type = params.type;
        const on = params.on;
        const recompiles = params.recompiles !== false;

        // True when child given as config object, where parent manages its instantiation and destruction
        let managingLifecycle = false;

        if (component) {

            if (utils.isNumeric(component) || utils.isString(component)) {

                // Component ID given
                // Both numeric and string IDs are supported

                const id = component;

                component = this.scene.components[id];

                if (!component) {

                    // Quote string IDs in errors

                    this.error("Component not found: " + utils.inQuotes(id));
                    return;
                }
            }
        }

        if (!component) {

            if (sceneSingleton === true) {

                // Using the first instance of the component type we find

                const instances = this.scene.types[type];
                for (const id2 in instances) {
                    if (instances.hasOwnProperty) {
                        component = instances[id2];
                        break;
                    }
                }

                if (!component) {
                    this.error("Scene has no default component for '" + name + "'");
                    return null;
                }

            } else if (sceneDefault === true) {

                // Using a default scene component

                component = this.scene[name];

                if (!component) {
                    this.error("Scene has no default component for '" + name + "'");
                    return null;
                }
            }
        }

        if (component) {

            if (component.scene.id !== this.scene.id) {
                this.error("Not in same scene: " + component.type + " " + utils.inQuotes(component.id));
                return;
            }

            if (type) {

                if (!component.isType(type)) {
                    this.error("Expected a " + type + " type or subtype: " + component.type + " " + utils.inQuotes(component.id));
                    return;
                }
            }
        }

        if (!this._attachments) {
            this._attachments = {};
        }

        const oldComponent = this._attached[name];
        let subs;
        let i;
        let len;

        if (oldComponent) {

            if (component && oldComponent.id === component.id) {

                // Reject attempt to reattach same component
                return;
            }

            const oldAttachment = this._attachments[oldComponent.id];

            // Unsubscribe from events on old component

            subs = oldAttachment.subs;

            for (i = 0, len = subs.length; i < len; i++) {
                oldComponent.off(subs[i]);
            }

            delete this._attached[name];
            delete this._attachments[oldComponent.id];

            const onDetached = oldAttachment.params.onDetached;
            if (onDetached) {
                if (utils.isFunction(onDetached)) {
                    onDetached(oldComponent);
                } else {
                    onDetached.scope ? onDetached.callback.call(onDetached.scope, oldComponent) : onDetached.callback(oldComponent);
                }
            }

            if (oldAttachment.managingLifecycle) {

                // Note that we just unsubscribed from all events fired by the child
                // component, so destroying it won't fire events back at us now.

                oldComponent.destroy();
            }
        }

        if (component) {

            // Set and publish the new component on this component

            const attachment = {
                params: params,
                component: component,
                subs: [],
                managingLifecycle: managingLifecycle
            };

            attachment.subs.push(
                component.once("destroyed",
                    function () {
                        attachment.params.component = null;
                        this._attach(attachment.params);
                    },
                    this));

            if (recompiles) {
                attachment.subs.push(
                    component.on("dirty",
                        function () {
                            this.fire("dirty", this);
                        },
                        this));
            }

            this._attached[name] = component;
            this._attachments[component.id] = attachment;

            // Bind destruct listener to new component to remove it
            // from this component when destroyed

            const onAttached = params.onAttached;
            if (onAttached) {
                if (utils.isFunction(onAttached)) {
                    onAttached(component);
                } else {
                    onAttached.scope ? onAttached.callback.call(onAttached.scope, component) : onAttached.callback(component);
                }
            }

            if (on) {

                let event;
                let subIdr;
                let callback;
                let scope;

                for (event in on) {
                    if (on.hasOwnProperty(event)) {

                        subIdr = on[event];

                        if (utils.isFunction(subIdr)) {
                            callback = subIdr;
                            scope = null;
                        } else {
                            callback = subIdr.callback;
                            scope = subIdr.scope;
                        }

                        if (!callback) {
                            continue;
                        }

                        attachment.subs.push(component.on(event, callback, scope));
                    }
                }
            }
        }

        if (recompiles) {
            this.fire("dirty", this); // FIXME: May trigger spurous mesh recompilations unless able to limit with param?
        }

        this.fire(name, component); // Component can be null

        return component;
    }

    _checkComponent(expectedType, component) {
        if (!component.isComponent) {
            if (utils.isID(component)) {
                const id = component;
                component = this.scene.components[id];
                if (!component) {
                    this.error("Component not found: " + id);
                    return;
                }
            } else {
                this.error("Expected a Component or ID");
                return;
            }
        }
        if (expectedType !== component.type) {
            this.error("Expected a " + expectedType + " Component");
            return;
        }
        if (component.scene.id !== this.scene.id) {
            this.error("Not in same scene: " + component.type);
            return;
        }
        return component;
    }

    _checkComponent2(expectedTypes, component) {
        if (!component.isComponent) {
            if (utils.isID(component)) {
                const id = component;
                component = this.scene.components[id];
                if (!component) {
                    this.error("Component not found: " + id);
                    return;
                }
            } else {
                this.error("Expected a Component or ID");
                return;
            }
        }
        if (component.scene.id !== this.scene.id) {
            this.error("Not in same scene: " + component.type);
            return;
        }
        for (var i = 0, len = expectedTypes.length; i < len; i++) {
            if (expectedTypes[i] === component.type) {
                return component;
            }
        }
        this.error("Expected component types: " + expectedTypes);
        return null;
    }

    _own(component) {
        if (!this._ownedComponents) {
            this._ownedComponents = {};
        }
        if (!this._ownedComponents[component.id]) {
            this._ownedComponents[component.id] = component;
        }
        component.once("destroyed", () => {
            delete this._ownedComponents[component.id];
        }, this);
    }

    /**
     * Protected method, called by sub-classes to queue a call to _update().
     * @protected
     * @param {Number} [priority=1]
     */
    _needUpdate(priority) {
        if (!this._updateScheduled) {
            this._updateScheduled = true;
            if (priority === 0) {
                this._doUpdate();
            } else {
                core.scheduleTask(this._doUpdate, this);
            }
        }
    }

    /**
     * @private
     */
    _doUpdate() {
        if (this._updateScheduled) {
            this._updateScheduled = false;
            if (this._update) {
                this._update();
            }
        }
    }

    /**
     * Protected virtual template method, optionally implemented
     * by sub-classes to perform a scheduled task.
     *
     * @protected
     */
    _update() {
    }

    /**
     * Destroys all {@link Component}s that are owned by this. These are Components that were instantiated with
     * this Component as their first constructor argument.
     */
    clear() {
        if (this._ownedComponents) {
            for (var id in this._ownedComponents) {
                if (this._ownedComponents.hasOwnProperty(id)) {
                    const component = this._ownedComponents[id];
                    component.destroy();
                    delete this._ownedComponents[id];
                }
            }
        }
    }

    /**
     * Destroys this component.
     */
    destroy() {

        if (this.destroyed) {
            return;
        }

        /**
         * Fired when this Component is destroyed.
         * @event destroyed
         */
        this.fire("destroyed", this.destroyed = true); // Must fire before we blow away subscription maps, below

        // Unsubscribe from child components and destroy then

        let id;
        let attachment;
        let component;
        let subs;
        let i;
        let len;

        if (this._attachments) {
            for (id in this._attachments) {
                if (this._attachments.hasOwnProperty(id)) {
                    attachment = this._attachments[id];
                    component = attachment.component;
                    subs = attachment.subs;
                    for (i = 0, len = subs.length; i < len; i++) {
                        component.off(subs[i]);
                    }
                    if (attachment.managingLifecycle) {
                        component.destroy();
                    }
                }
            }
        }

        if (this._ownedComponents) {
            for (id in this._ownedComponents) {
                if (this._ownedComponents.hasOwnProperty(id)) {
                    component = this._ownedComponents[id];
                    component.destroy();
                    delete this._ownedComponents[id];
                }
            }
        }

        this.scene._removeComponent(this);

        // Memory leak avoidance
        this._attached = {};
        this._attachments = null;
        this._subIdMap = null;
        this._subIdEvents = null;
        this._eventSubs = null;
        this._events = null;
        this._eventCallDepth = 0;
        this._ownedComponents = null;
        this._updateScheduled = false;
    }
}

export {Component};