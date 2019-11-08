/**
 * @desc A 2D plan view image of an ````IfcBuildingStorey````.
 *
 * These are created by a {@link StoreyViewsPlugin}.
 */
class StoreyMap {

    /**
     * @private
     */
    constructor(storeyId, imageData, format, width, height, padding) {

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
         * Base64-encoded plan view image.
         *
         * @property imageData
         * @type {String}
         */
        this.imageData = imageData;

        /**
         * The image format - "png" or "jpeg".
         *
         * @property format
         * @type {String}
         */
        this.format = format;

        /**
         * Width of the image, in pixels.
         *
         * @property width
         * @type {Number}
         */
        this.width = width;

        /**
         * Height of the image, in pixels.
         *
         * @property height
         * @type {Number}
         */
        this.height = height;
    }
}

export {StoreyMap};