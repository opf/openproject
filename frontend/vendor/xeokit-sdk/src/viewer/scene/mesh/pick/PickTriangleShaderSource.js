/**
 * @author xeolabs / https://github.com/xeolabs
 */

/**
 * @private
 */
class PickTriangleShaderSource {
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
    src.push("// Surface picking vertex shader");
    src.push("attribute vec3 position;");
    src.push("attribute vec4 color;");
    src.push("uniform mat4 modelMatrix;");
    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    if (clipping) {
        src.push("uniform bool clippable;");
        src.push("varying vec4 vWorldPosition;");
    }
    src.push("varying vec4 vColor;");
    if (quantizedGeometry) {
        src.push("uniform mat4 positionsDecodeMatrix;");
    }
    src.push("void main(void) {");
    src.push("vec4 localPosition = vec4(position, 1.0); ");
    if (quantizedGeometry) {
        src.push("localPosition = positionsDecodeMatrix * localPosition;");
    }
    src.push("   vec4 worldPosition = modelMatrix * localPosition; ");
    src.push("   vec4 viewPosition = viewMatrix * worldPosition;");
    if (clipping) {
        src.push("   vWorldPosition = worldPosition;");
    }
    src.push("   vColor = color;");
    src.push("   gl_Position = projMatrix * viewPosition;");
    src.push("}");
    return src;
}

function buildFragment(mesh) {
    const scene = mesh.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Surface picking fragment shader");
    src.push("precision lowp float;");
    src.push("varying vec4 vColor;");
    if (clipping) {
        src.push("uniform bool clippable;");
        src.push("varying vec4 vWorldPosition;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("uniform bool sectionPlaneActive" + i + ";");
            src.push("uniform vec3 sectionPlanePos" + i + ";");
            src.push("uniform vec3 sectionPlaneDir" + i + ";");
        }
    }
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
    src.push("   gl_FragColor = vColor;");
    src.push("}");
    return src;
}

export {PickTriangleShaderSource};