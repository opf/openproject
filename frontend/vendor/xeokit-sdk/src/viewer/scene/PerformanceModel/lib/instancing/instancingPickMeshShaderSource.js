/**
 * @author xeolabs / https://github.com/xeolabs
 */

/**
 * @private
 */
const InstancingPickMeshShaderSource = function (layer) {
    this.vertex = buildVertex(layer);
    this.fragment = buildFragment(layer);
};

function buildVertex(layer) {
    var scene = layer.model.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];

    src.push("// Instancing geometry picking vertex shader");

    src.push("attribute vec3 position;");
    src.push("attribute vec4 flags;");
    src.push("attribute vec4 flags2;");
    src.push("attribute vec4 pickColor;");

    src.push("attribute vec4 modelMatrixCol0;"); // Modeling matrix
    src.push("attribute vec4 modelMatrixCol1;");
    src.push("attribute vec4 modelMatrixCol2;");

    src.push("uniform bool pickInvisible;");
    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    src.push("uniform mat4 positionsDecodeMatrix;");

    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("varying vec4 vFlags2;");
    }
    src.push("varying vec4 vPickColor;");
    src.push("void main(void) {");
    src.push("bool visible   = (float(flags.x) > 0.0);");
    src.push("bool pickable  = (float(flags2.z) > 0.0);");
    src.push(`if ((!pickInvisible && !visible) || !pickable) {`);
    src.push("   gl_Position = vec4(0.0, 0.0, 0.0, 0.0);"); // Cull vertex
    src.push("} else {");


    src.push("  vec4 worldPosition = positionsDecodeMatrix * vec4(position, 1.0); ");

    src.push("  worldPosition = vec4(dot(worldPosition, modelMatrixCol0), dot(worldPosition, modelMatrixCol1), dot(worldPosition, modelMatrixCol2), 1.0);");

    src.push("  vec4 viewPosition  = viewMatrix * worldPosition; ");

    src.push("  vPickColor = vec4(float(pickColor.r) / 255.0, float(pickColor.g) / 255.0, float(pickColor.b) / 255.0, float(pickColor.a) / 255.0);");
    if (clipping) {
        src.push("  vWorldPosition = worldPosition;");
        src.push("vFlags2 = flags2;");
    }
    src.push("  gl_Position = projMatrix * viewPosition;");
    src.push("}");
    src.push("}");
    return src;
}

function buildFragment(layer) {
    const scene = layer.model.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Batched geometry picking fragment shader");
    src.push("precision mediump float;");
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("varying vec4 vFlags2;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("uniform bool sectionPlaneActive" + i + ";");
            src.push("uniform vec3 sectionPlanePos" + i + ";");
            src.push("uniform vec3 sectionPlaneDir" + i + ";");
        }
    }
    src.push("varying vec4 vPickColor;");
    src.push("void main(void) {");
    if (clipping) {
        src.push("  bool clippable = (float(vFlags2.x) > 0.0);");
        src.push("  if (clippable) {");
        src.push("  float dist = 0.0;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("if (sectionPlaneActive" + i + ") {");
            src.push("   dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
            src.push("}");
        }
        src.push("if (dist > 0.0) { discard; }");
        src.push("}");
    }
    src.push("gl_FragColor = vPickColor; ");
    src.push("}");
    return src;
}

export {InstancingPickMeshShaderSource};