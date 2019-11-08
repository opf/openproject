/**
 * @desc Metadata corresponding to an {@link Entity} that represents an object.
 *
 * An {@link Entity} represents an object when {@link Entity#isObject} is ````true````
 *
 * A MetaObject corresponds to an {@link Entity} by having the same {@link MetaObject#id} as the {@link Entity#id}.
 *
 * A MetaObject is created within {@link MetaScene#createMetaModel} and belongs to a {@link MetaModel}.
 *
 * Each MetaObject is registered by {@link MetaObject#id} in {@link MetaScene#metaObjects}.
 *
 * A {@link MetaModel} represents its object structure with a tree of MetaObjects, with {@link MetaModel#rootMetaObject} referencing
 * the root MetaObject.
 *
 * @class MetaObject
 */
class MetaObject {

    constructor(metaModel, id, name, type, properties, parent, children, external) {

        /**
         * Model metadata.
         *
         * @property metaModel
         * @type {MetaModel}
         */
        this.metaModel = metaModel;

        /**
         * Globally-unique ID.
         *
         * MetaObject instances are registered by this ID in {@link MetaScene#metaObjects}.
         *
         * @property id
         * @type {String|Number}
         */
        this.id = id;

        /**
         * Human-readable name.
         *
         * @property name
         * @type {String}
         */
        this.name = name;

        /**
         * Type - often an IFC product type.
         *
         * @property type
         * @type {String}
         */
        this.type = type;

        if (properties) {

            /**
             * Arbitrary metadata properties.
             *
             * Undefined when no metadata properties are represented.
             *
             * @property properties
             * @type {*}
             */
            this.properties = properties;
        }

        if (parent !== undefined && parent !== null) {

            /**
             * The parent MetaObject within the structure hierarchy.
             *
             * Undefined when this is the root of its structure.
             *
             * @property parent
             * @type {MetaObject}
             */
            this.parent = parent;
        }

        if (children !== undefined && children !== null) {

            /**
             * Child ObjectMeta instances within the structure hierarchy.
             *
             * Undefined when there are no children.
             *
             * @property children
             * @type {Array}
             */
            this.children = children;
        }

        if (external !== undefined && external !== null) {

            /**
             * External application-specific metadata
             *
             * Undefined when there are is no external application-specific metadata.
             *
             * @property external
             * @type {*}
             */
            this.external = external;
        }
    }

    /**
     * Gets the {@link MetaObject#id}s of the {@link MetaObject}s within the subtree.
     *
     * @returns {String[]} Array of {@link MetaObject#id}s.
     */
    getObjectIDsInSubtree() {
        const objectIds = [];

        function visit(metaObject) {
            if (!metaObject) {
                return;
            }
            objectIds.push(metaObject.id);
            const children = metaObject.children;
            if (children) {
                for (var i = 0, len = children.length; i < len; i++) {
                    visit(children[i]);
                }
            }
        }

        visit(this);
        return objectIds;
    }

    /**
     * Gets the {@link MetaObject#id}s of the {@link MetaObject}s within the subtree that have the given {@link MetaObject#type}s.
     *
     * @param {String[]} types {@link MetaObject#type} values.
     * @returns {String[]} Array of {@link MetaObject#id}s.
     */
    getObjectIDsInSubtreeByType(types) {
        const mask = {};
        for (var i = 0, len = types.length; i < len; i++) {
            mask[types[i]] = types[i];
        }
        const objectIds = [];

        function visit(metaObject) {
            if (!metaObject) {
                return;
            }
            if (mask[metaObject.type]) {
                objectIds.push(metaObject.id);
            }
            const children = metaObject.children;
            if (children) {
                for (var i = 0, len = children.length; i < len; i++) {
                    visit(children[i]);
                }
            }
        }

        visit(this);
        return objectIds;
    }

    /**
     * Returns properties of this MeteObject as JSON.
     *
     * @returns {{id: (String|Number), type: String, name: String, parent: (String|Number|Undefined)}}
     */
    getJSON() {
        var json = {
            id: this.id,
            type: this.type,
            name: this.name
        };
        if (this.parent) {
            json.parent = this.parent.id
        }
        return json;
    }
}

export {MetaObject};