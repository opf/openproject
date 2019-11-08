/**
 * @private
 * @type {{WEBGL: boolean, SUPPORTED_EXTENSIONS: {}}}
 */
const WEBGL_INFO = {
    WEBGL: false,
    SUPPORTED_EXTENSIONS: {}
};

const canvas = document.createElement("canvas");

if (canvas) {

    const gl = canvas.getContext("webgl", {antialias: true}) || canvas.getContext("experimental-webgl", {antialias: true});

    WEBGL_INFO.WEBGL = !!gl;

    if (WEBGL_INFO.WEBGL) {
        WEBGL_INFO.ANTIALIAS = gl.getContextAttributes().antialias;
        if (gl.getShaderPrecisionFormat) {
            if (gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision > 0) {
                WEBGL_INFO.FS_MAX_FLOAT_PRECISION = "highp";
            } else if (gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT).precision > 0) {
                WEBGL_INFO.FS_MAX_FLOAT_PRECISION = "mediump";
            } else {
                WEBGL_INFO.FS_MAX_FLOAT_PRECISION = "lowp";
            }
        } else {
            WEBGL_INFO.FS_MAX_FLOAT_PRECISION = "mediump";
        }
        WEBGL_INFO.DEPTH_BUFFER_BITS = gl.getParameter(gl.DEPTH_BITS);
        WEBGL_INFO.MAX_TEXTURE_SIZE = gl.getParameter(gl.MAX_TEXTURE_SIZE);
        WEBGL_INFO.MAX_CUBE_MAP_SIZE = gl.getParameter(gl.MAX_CUBE_MAP_TEXTURE_SIZE);
        WEBGL_INFO.MAX_RENDERBUFFER_SIZE = gl.getParameter(gl.MAX_RENDERBUFFER_SIZE);
        WEBGL_INFO.MAX_TEXTURE_UNITS = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);
        WEBGL_INFO.MAX_TEXTURE_IMAGE_UNITS = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS);
        WEBGL_INFO.MAX_VERTEX_ATTRIBS = gl.getParameter(gl.MAX_VERTEX_ATTRIBS);
        WEBGL_INFO.MAX_VERTEX_UNIFORM_VECTORS = gl.getParameter(gl.MAX_VERTEX_UNIFORM_VECTORS);
        WEBGL_INFO.MAX_FRAGMENT_UNIFORM_VECTORS = gl.getParameter(gl.MAX_FRAGMENT_UNIFORM_VECTORS);
        WEBGL_INFO.MAX_VARYING_VECTORS = gl.getParameter(gl.MAX_VARYING_VECTORS);
        gl.getSupportedExtensions().forEach(function (ext) {
            WEBGL_INFO.SUPPORTED_EXTENSIONS[ext] = true;
        });
    }
}

export {WEBGL_INFO};