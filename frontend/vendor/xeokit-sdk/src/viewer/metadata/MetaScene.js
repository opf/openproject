import {MetaModel} from "./MetaModel.js";
import {MetaObject} from "./MetaObject.js";

/**
 * @desc Metadata corresponding to a {@link Scene}.
 *
 * * Located in {@link Viewer#metaScene}.
 * * Contains {@link MetaModel}s and {@link MetaObject}s.
 * * [Scene Graphs user guide](https://github.com/xeokit/xeokit-sdk/wiki/Scene-Graphs)
 * * [Scene graph example with metadata](http://xeokit.github.io/xeokit-sdk/examples/#sceneRepresentation_SceneGraph_metadata)
 */
class MetaScene {

    /**
     * @private
     */
    constructor(viewer, scene) {

        /**
         * The {@link Viewer}.
         * @property viewer
         * @type {Viewer}
         */
        this.viewer = viewer;

        /**
         * The {@link Scene}.
         * @property scene
         * @type {Scene}
         */
        this.scene = scene;

        /**
         * The {@link MetaModel}s belonging to this MetaScene, each mapped to its {@link MetaModel#modelId}.
         *
         * @type {{String:MetaModel}}
         */
        this.metaModels = {};

        /**
         * The {@link MetaObject}s belonging to this MetaScene, each mapped to its {@link MetaObject#id}.
         *
         * @type {{String:MetaObject}}
         */
        this.metaObjects = {};

        /**
         * The {@link MetaObject}s belonging to this MetaScene, each mapped to its {@link MetaObject#type}.
         *
         * @type {{String:MetaObject}}
         */
        this.metaObjectsByType = {};

        /**
         * Tracks number of MetaObjects of each type.
         * @private
         */
        this._typeCounts = {};

        /**
         * Subscriptions to events sent with {@link fire}.
         * @private
         */
        this._eventSubs = {};
    }

    /**
     * Subscribes to an event fired at this Viewer.
     *
     * @param {String} event The event
     * @param {Function} callback Callback fired on the event
     */
    on(event, callback) {
        let subs = this._eventSubs[event];
        if (!subs) {
            subs = [];
            this._eventSubs[event] = subs;
        }
        subs.push(callback);
    }

    /**
     * Fires an event at this Viewer.
     *
     * @param {String} event Event name
     * @param {Object} value Event parameters
     */
    fire(event, value) {
        const subs = this._eventSubs[event];
        if (subs) {
            for (let i = 0, len = subs.length; i < len; i++) {
                subs[i](value);
            }
        }
    }

    /**
     * Unsubscribes from an event fired at this Viewer.
     * @param event
     */
    off(event) { // TODO

    }

    /**
     * Creates a {@link MetaModel} in this MetaScene.
     *
     * @param {String} id ID for the new {@link MetaModel}, which will have {@link MetaModel#id} set to this value.
     * @param {Object} metaModelData Data for the {@link MetaModel} - (see [Model Metadata](https://github.com/xeolabs/xeokit.io/wiki/Model-Metadata)).
     * @param {Object} [options] Options for creating the {@link MetaModel}.
     * @param {Object} [options.includeTypes] When provided, only {@link MetaObject}s with types in this list.
     * @param {Object} [options.includeTypes] When provided, never {@link MetaObject}s with types in this list.
     * @param {Object} [options.excludeTypes]
     * @returns {MetaModel} The new MetaModel.
     */
    createMetaModel(id, metaModelData, options = {}) {

        // TODO: validate metadata
        // TODO: replace MetaModel if ID already used

        const projectId = metaModelData.projectId || "none";
        const revisionId = metaModelData.revisionId || "none";
        const newObjects = metaModelData.metaObjects;

        var includeTypes;
        // if (options.includeTypes) {
        //     includeTypes = {};
        //     for (let i = 0, len = options.includeTypes.length; i < len; i++) {
        //         includeTypes[options.includeTypes[i]] = true;
        //     }
        // }
        //
        var excludeTypes;
        // if (options.excludeTypes) {
        //     excludeTypes = {};
        //     for (let i = 0, len = options.excludeTypes.length; i < len; i++) {
        //         includeTypes[options.excludeTypes[i]] = true;
        //     }
        // }

        const metaModel = new MetaModel(this, id, projectId, revisionId, null);

        this.metaModels[id] = metaModel;

        for (let i = 0, len = newObjects.length; i < len; i++) {
            const newObject = newObjects[i];
            const type = newObject.type;
            if (excludeTypes && excludeTypes[type]) {
                continue;
            }
            if (includeTypes && !includeTypes[type]) {
                continue;
            }
            const id = newObject.id;
            const name = newObject.name;
            const properties = newObject.properties;
            const parent = null;
            const children = null;
            const external = newObject.external;
            const metaObject = new MetaObject(metaModel, id, name, type, properties, parent, children, external);
            this.metaObjects[id] = metaObject;
            (this.metaObjectsByType[type] || (this.metaObjectsByType[type] = {}))[id] = metaObject;
            if (this._typeCounts[type] === undefined) {
                this._typeCounts[type] = 1;
            } else {
                this._typeCounts[type]++;
            }
        }

        for (let i = 0, len = newObjects.length; i < len; i++) {
            const newObject = newObjects[i];
            const id = newObject.id;
            const metaObject = this.metaObjects[id];
            if (!metaObject) {
                continue;
            }
            if (newObject.parent === undefined || newObject.parent === null) {
                metaModel.rootMetaObject = metaObject;
            } else if (newObject.parent) {
                let parentMetaObject = this.metaObjects[newObject.parent];
                if (parentMetaObject) {
                    metaObject.parent = parentMetaObject;
                    parentMetaObject.children = parentMetaObject.children || [];
                    parentMetaObject.children.push(metaObject);
                }
            }
        }

        this.fire("metaModelCreated", id);
        return metaModel;
    }

    /**
     * Removes a {@link MetaModel} from this MetaScene.
     *
     * Fires a "metaModelDestroyed" event with the value of the {@link MetaModel#id}.
     *
     * @param {String} id ID of the target {@link MetaModel}.
     */
    destroyMetaModel(id) {
        const metaModel = this.metaModels[id];
        if (!metaModel) {
            return;
        }
        const metaObjects = this.metaObjects;
        const metaObjectsByType = this.metaObjectsByType;

        let visit = (metaObject) => {
            delete metaObjects[metaObject.id];
            const types = metaObjectsByType[metaObject.type];
            if (types && types[metaObject.id]) {
                delete types[metaObject.id];
                if (--this._typeCounts[metaObject.type] === 0) {
                    delete this._typeCounts[metaObject.type];
                    delete metaObjectsByType[metaObject.type];
                }
            }
            const children = metaObject.children;
            if (children) {
                for (let i = 0, len = children.length; i < len; i++) {
                    const childMetaObject = children[i];
                    visit(childMetaObject);
                }
            }
        };

        visit(metaModel.rootMetaObject);
        delete this.metaModels[id];
        this.fire("metaModelDestroyed", id);
    }

    /**
     * Gets the {@link MetaObject#id}s of the {@link MetaObject}s that have the given {@link MetaObject#type}.
     *
     * @param {String} type The type.
     * @returns {String[]} Array of {@link MetaObject#id}s.
     */
    getObjectIDsByType(type) {
        const metaObjects = this.metaObjectsByType[type];
        return metaObjects ? Object.keys(metaObjects) : [];
    }

    /**
     * Gets the {@link MetaObject#id}s of the {@link MetaObject}s within the given subtree.
     *
     * @param {String} id  ID of the root {@link MetaObject} of the given subtree.
     * @returns {String[]} Array of {@link MetaObject#id}s.
     */
    getObjectIDsInSubtree(id) {
        const list = [];
        const metaObject = this.metaObjects[id];

        function visit(metaObject) {
            if (!metaObject) {
                return;
            }
            list.push(metaObject.id);
            const children = metaObject.children;
            if (children) {
                for (var i = 0, len = children.length; i < len; i++) {
                    visit(children[i]);
                }
            }
        }

        visit(metaObject);
        return list;
    }
}

export {MetaScene};