/**
 * @desc Information about an ````IfcBuildingStorey````.
 *
 * These are provided by a {@link StoreyViewsPlugin}.
 */
class Storey {

    /**
     * @private
     */
    constructor(plugin, aabb, modelId, storeyId) {

        /**
         * The {@link StoreyViewsPlugin} this Storey belongs to.
         *
         * @property plugin
         * @type {StoreyViewsPlugin}
         */
        this.plugin = plugin;

        /**
         * ID of the IfcBuildingStorey.
         *
         * This matches IDs of the IfcBuildingStorey's {@link MetaObject} and {@link Entity}.
         *
         * @property storeyId
         * @type {String}
         */
        this.storeyId = storeyId;

        /**
         * ID of the model.
         *
         * This matches the ID of the {@link MetaModel} that contains the IfcBuildingStorey's {@link MetaObject}.
         *
         * @property modelId
         * @type {String|Number}
         */
        this.modelId = modelId;

        /**
         * Axis-aligned World-space boundary of the {@link Entity}s that represent the IfcBuildingStorey.
         *
         * The boundary is a six-element Float32Array containing the min/max extents of the
         * axis-aligned boundary, ie. ````[xmin, ymin, zmin, xmax, ymax, zmax]````
         *
         * @property aabb
         * @type {Number[]}
         */
        this.aabb = aabb.slice();
    }
}

export {Storey};