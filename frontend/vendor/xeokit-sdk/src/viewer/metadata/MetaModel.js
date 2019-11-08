/**
 * @desc Metadata corresponding to an {@link Entity} that represents a model.
 *
 * An {@link Entity} represents a model when {@link Entity#isModel} is ````true````
 *
 * A MetaModel corresponds to an {@link Entity} by having the same {@link MetaModel#id} as the {@link Entity#id}.
 *
 * A MetaModel is created by {@link MetaScene#createMetaModel} and belongs to a {@link MetaScene}.
 *
 * Each MetaModel is registered by {@link MetaModel#id} in {@link MetaScene#metaModels}.
 *
 * A {@link MetaModel} represents its object structure with a tree of {@link MetaObject}s, with {@link MetaModel#rootMetaObject} referencing the root {@link MetaObject}.
 *
 * @class MetaModel
 */
class MetaModel {

    /**
     * @private
     */
    constructor(metaScene, id, projectId, revisionId, rootMetaObject) {

        /**
         * Globally-unique ID.
         *
         * MetaModels are registered by ID in {@link MetaScene#metaModels}.
         *
         * When this MetaModel corresponds to an {@link Entity} then this ID will match the {@link Entity#id}.
         *
         * @property id
         * @type {String|Number}
         */
        this.id = id;

        /**
         * The project ID
         * @property projectId
         * @type {String|Number}
         */
        this.projectId = projectId;

        /**
         * The revision ID
         * @property revisionId
         * @type {String|Number}
         */
        this.revisionId = revisionId;

        /**
         * Metadata on the {@link Scene}.
         *
         * @property metaScene
         * @type {MetaScene}
         */
        this.metaScene = metaScene;

        /**
         * The root {@link MetaObject} in this MetaModel's composition structure hierarchy.
         *
         * @property rootMetaObject
         * @type {MetaObject}
         */
        this.rootMetaObject = rootMetaObject;
    }

    getJSON() {

        var metaObjects = [];

        function visit(metaObject) {
            var metaObjectCfg = {
                id: metaObject.id,
                extId: metaObject.extId,
                type: metaObject.type,
                name: metaObject.name
            };
            if (metaObject.parent) {
                metaObjectCfg.parent = metaObject.parent.id;
            }
            metaObjects.push(metaObjectCfg);
            var children = metaObject.children;
            if (children) {
                for (var i = 0, len = children.length; i < len; i++) {
                    visit(children[i]);
                }
            }
        }

        visit(this.rootMetaObject);

        var json = {
            id: this.id,
            projectId: this.projectId,
            revisionId: this.revisionId,
            metaObjects: metaObjects
        };
        return json;
    }
}


export {MetaModel};