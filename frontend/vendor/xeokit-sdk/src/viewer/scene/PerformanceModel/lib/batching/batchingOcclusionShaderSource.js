/**
 * @private
 */
class BatchingOcclusionShaderSource {
    constructor(layer) {
        this.vertex = buildVertex(layer);
        this.fragment = buildFragment(layer);
    }
}

function buildVertex(layer) {
    const scene = layer.model.scene;
    const clipping = scene._sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Batched occlusion vertex shader");
    src.push("attribute vec3 position;");
    src.push("attribute vec4 color;");
    src.push("attribute vec4 flags;");
    src.push("attribute vec4 flags2;");
    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    src.push("uniform mat4 positionsDecodeMatrix;");
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("varying vec4 vFlags2;");
    }
    src.push("void main(void) {");
    src.push("  bool visible   = (float(flags.x) > 0.0);");
    src.push("  bool transparent  = ((float(color.a) / 255.0) < 1.0);");
    src.push("  if (!visible || transparent) {");
    src.push("      gl_Position = vec4(0.0, 0.0, 0.0, 0.0);"); // Cull vertex
    src.push("  } else {");
    src.push("      vec4 worldPosition = positionsDecodeMatrix * vec4(position, 1.0); "); // Batched positions are baked in World-space
    src.push("      vec4 viewPosition  = viewMatrix * worldPosition; ");
    if (clipping) {
        src.push("      vWorldPosition = worldPosition;");
        src.push("      vFlags2 = flags2;");
    }
    src.push("      gl_Position = projMatrix * viewPosition;");
    src.push("  }");
    src.push("}");
    return src;
}

function buildFragment(layer) {
    const scene = layer.model.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Batched occlusion fragment shader");
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
    src.push("void main(void) {");
    if (clipping) {
        src.push("  bool clippable = (float(vFlags2.x) > 0.0);");
        src.push("  if (clippable) {");
        src.push("      float dist = 0.0;");
        for (var i = 0; i < sectionPlanesState.sectionPlanes.length; i++) {
            src.push("      if (sectionPlaneActive" + i + ") {");
            src.push("          dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
            src.push("      }");
        }
        src.push("      if (dist > 0.0) { discard; }");
        src.push("  }");
    }
    src.push("   gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0); "); // Occluders are blue
    src.push("}");
    return src;
}

export {BatchingOcclusionShaderSource};