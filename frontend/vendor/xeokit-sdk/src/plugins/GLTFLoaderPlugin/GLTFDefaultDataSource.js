import {utils} from "../../viewer/scene/utils.js";

/**
 * Default data access strategy for {@link GLTFLoaderPlugin}.
 *
 * This just loads assets using XMLHttpRequest.
 */
class GLTFDefaultDataSource {

    constructor() {
    }

    /**
     * Gets metamodel JSON.
     *
     * @param {String|Number} metaModelSrc Identifies the metamodel JSON asset.
     * @param {{Function(*)}} ok Fired on successful loading of the metamodel JSON asset.
     * @param {{Function(*)}} error Fired on error while loading the metamodel JSON asset.
     */
    getMetaModel(metaModelSrc, ok, error) {
        utils.loadJSON(metaModelSrc,
            (json) => {
                ok(json);
            },
            function (errMsg) {
                error(errMsg);
            });
    }

    /**
     * Gets glTF JSON.
     *
     * @param {String|Number} glTFSrc Identifies the glTF JSON asset.
     * @param {Function} ok Fired on successful loading of the glTF JSON asset.
     * @param {Function} error Fired on error while loading the glTF JSON asset.
     */
    getGLTF(glTFSrc, ok, error) {
        utils.loadJSON(glTFSrc,
            (gltf) => {
                ok(gltf);
            },
            function (errMsg) {
                error(errMsg);
            });
    }

    /**
     * Gets glTF binary attachment.
     *
     * Note that this method requires the source of the glTF JSON asset. This is because the binary attachment
     * source could be relative to the glTF source, IE. it may not be a global ID.
     *
     * @param {String|Number} glTFSrc Identifies the glTF JSON asset.
     * @param {String|Number} binarySrc Identifies the glTF binary asset.
     * @param {Function} ok Fired on successful loading of the glTF binary asset.
     * @param {Function} error Fired on error while loading the glTF binary asset.
     */
    getArrayBuffer(glTFSrc, binarySrc, ok, error) {
        loadArraybuffer(glTFSrc, binarySrc,
            (arrayBuffer) => {
                ok(arrayBuffer);
            },
            function (errMsg) {
                error(errMsg);
            });
    }
}

function loadArraybuffer(glTFSrc, binarySrc, ok, err) {
    // Check for data: URI
    var defaultCallback = () => {
    };
    ok = ok || defaultCallback;
    err = err || defaultCallback;
    const dataUriRegex = /^data:(.*?)(;base64)?,(.*)$/;
    const dataUriRegexResult = binarySrc.match(dataUriRegex);
    if (dataUriRegexResult) { // Safari can't handle data URIs through XMLHttpRequest
        const isBase64 = !!dataUriRegexResult[2];
        var data = dataUriRegexResult[3];
        data = window.decodeURIComponent(data);
        if (isBase64) {
            data = window.atob(data);
        }
        try {
            const buffer = new ArrayBuffer(data.length);
            const view = new Uint8Array(buffer);
            for (var i = 0; i < data.length; i++) {
                view[i] = data.charCodeAt(i);
            }
            window.setTimeout(function () {
                ok(buffer);
            }, 0);
        } catch (error) {
            window.setTimeout(function () {
                err(error);
            }, 0);
        }
    } else {
        const basePath = getBasePath(glTFSrc);
        const url = basePath + binarySrc;
        const request = new XMLHttpRequest();
        request.open('GET', url, true);
        request.responseType = 'arraybuffer';
        request.onreadystatechange = function () {
            if (request.readyState === 4) {
                if (request.status === 200) {
                    ok(request.response);
                } else {
                    err('loadArrayBuffer error : ' + request.response);
                }
            }
        };
        request.send(null);
    }
}

function getBasePath(src) {
    var i = src.lastIndexOf("/");
    return (i !== 0) ? src.substring(0, i + 1) : "";
}

export {GLTFDefaultDataSource};