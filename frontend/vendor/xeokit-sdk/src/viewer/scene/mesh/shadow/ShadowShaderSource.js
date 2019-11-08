/**
 * @author xeolabs / https://github.com/xeolabs
 */

/**
 * @private
 */
class ShadowShaderSource {
    constructor(mesh) {
        this.vertex = buildVertex(mesh);
        this.fragment = buildFragment(mesh);
    }
}

function buildVertex(mesh) {
    const scene = mesh.scene;
    const clipping = scene._sectionPlanesState.sectionPlanes.length > 0;
    const quantizedGeometry = !!mesh._geometry._state.compressGeometry;
    const billboard = mesh._state.billboard;
    const stationary = mesh._state.stationary;
    const src = [];
    src.push("// Shadow drawing vertex shader");
    src.push("attribute vec3 position;");
    src.push("uniform mat4 modelMatrix;");
    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    if (quantizedGeometry) {
        src.push("uniform mat4 positionsDecodeMatrix;");
    }
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
    }
    if (billboard === "spherical" || billboard === "cylindrical") {
        src.push("void billboard(inout mat4 mat) {");
        src.push("   mat[0][0] = 1.0;");
        src.push("   mat[0][1] = 0.0;");
        src.push("   mat[0][2] = 0.0;");
        if (billboard === "spherical") {
            src.push("   mat[1][0] = 0.0;");
            src.push("   mat[1][1] = 1.0;");
            src.push("   mat[1][2] = 0.0;");
        }
        src.push("   mat[2][0] = 0.0;");
        src.push("   mat[2][1] = 0.0;");
        src.push("   mat[2][2] =1.0;");
        src.push("}");
    }
    src.push("void main(void) {");
    src.push("vec4 localPosition = vec4(position, 1.0); ");
    src.push("vec4 worldPosition;");
    if (quantizedGeometry) {
        src.push("localPosition = positionsDecodeMatrix * localPosition;");
    }
    src.push("mat4 viewMatrix2 = viewMatrix;");
    src.push("mat4 modelMatrix2 = modelMatrix;");
    if (stationary) {
        src.push("viewMatrix2[3][0] = viewMatrix2[3][1] = viewMatrix2[3][2] = 0.0;")
    }
    if (billboard === "spherical" || billboard === "cylindrical") {
        src.push("mat4 modelViewMatrix = viewMatrix2 * modelMatrix2;");
        src.push("billboard(modelMatrix2);");
        src.push("billboard(viewMatrix2);");
    }
    src.push("worldPosition = modelMatrix2 * localPosition;");
    src.push("vec4 viewPosition  = viewMatrix2 * worldPosition; ");
    if (clipping) {
        src.push("vWorldPosition = worldPosition;");
    }
    src.push("   gl_Position = projMatrix * viewPosition;");
    src.push("}");
    return src;
}

function buildFragment(mesh) {
    const scene = mesh.scene;
    const gl = scene.canvas.gl;
    const sectionPlanesState = scene._sectionPlanesState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Shadow fragment shader");
    src.push("precision " + getFragmentFloatPrecision(gl) + " float;");
    if (clipping) {
        src.push("uniform bool clippable;");
        src.push("varying vec4 vWorldPosition;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("uniform bool sectionPlaneActive" + i + ";");
            src.push("uniform vec3 sectionPlanePos" + i + ";");
            src.push("uniform vec3 sectionPlaneDir" + i + ";");
        }
    }
    src.push("vec4 packDepth (float depth) {");
    src.push("  const vec4 bitShift = vec4(1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0);");
    src.push("  const vec4 bitMask = vec4(1.0/256.0, 1.0/256.0, 1.0/256.0, 0.0);");
    src.push("  vec4 comp = fract(depth * bitShift);");
    src.push("  comp -= comp.gbaa * bitMask;");
    src.push("  return comp;");
    src.push("}");

    src.push("void main(void) {");
    if (clipping) {
        src.push("if (clippable) {");
        src.push("  float dist = 0.0;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("if (sectionPlaneActive" + i + ") {");
            src.push("   dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
            src.push("}");
        }
        src.push("  if (dist > 0.0) { discard; }");
        src.push("}");
    }
    src.push("gl_FragColor = packDepth(gl_FragCoord.z);");
    src.push("}");
    return src;
}

function getFragmentFloatPrecision(gl) {
    if (!gl.getShaderPrecisionFormat) {
        return "mediump";
    }
    if (gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.HIGH_FLOAT).precision > 0) {
        return "highp";
    }
    if (gl.getShaderPrecisionFormat(gl.FRAGMENT_SHADER, gl.MEDIUM_FLOAT).precision > 0) {
        return "mediump";
    }
    return "lowp";
}

export {ShadowShaderSource};