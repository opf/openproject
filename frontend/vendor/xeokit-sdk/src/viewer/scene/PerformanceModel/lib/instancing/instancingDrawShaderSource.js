/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {RENDER_PASSES} from '../renderPasses.js';

/**
 * @private
 */
const InstancingDrawShaderSource = function (layer) {
    this.vertex = buildVertex(layer);
    this.fragment = buildFragment(layer);
};

function buildVertex(layer) {
    var scene = layer.model.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    const lightsState = scene._lightsState;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    let i;
    let len;
    let light;
    const src = [];

    src.push("// Instancing geometry drawing vertex shader");

    src.push("uniform int renderPass;");

    src.push("attribute vec3 position;");
    src.push("attribute vec2 normal;");
    src.push("attribute vec4 color;");
    src.push("attribute vec4 flags;");
    src.push("attribute vec4 flags2;");

    src.push("attribute vec4 modelMatrixCol0;"); // Modeling matrix
    src.push("attribute vec4 modelMatrixCol1;");
    src.push("attribute vec4 modelMatrixCol2;");

    src.push("attribute vec4 modelNormalMatrixCol0;");
    src.push("attribute vec4 modelNormalMatrixCol1;");
    src.push("attribute vec4 modelNormalMatrixCol2;");

    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    src.push("uniform mat4 viewNormalMatrix;");
    src.push("uniform mat4 positionsDecodeMatrix;");

    src.push("uniform vec4 colorize;");

    src.push("uniform vec4 lightAmbient;");

    for (i = 0, len = lightsState.lights.length; i < len; i++) {
        light = lightsState.lights[i];
        if (light.type === "ambient") {
            continue;
        }
        src.push("uniform vec4 lightColor" + i + ";");
        if (light.type === "dir") {
            src.push("uniform vec3 lightDir" + i + ";");
        }
        if (light.type === "point") {
            src.push("uniform vec3 lightPos" + i + ";");
        }
        if (light.type === "spot") {
            src.push("uniform vec3 lightPos" + i + ";");
            src.push("uniform vec3 lightDir" + i + ";");
        }
    }

    src.push("vec3 octDecode(vec2 oct) {");
    src.push("    vec3 v = vec3(oct.xy, 1.0 - abs(oct.x) - abs(oct.y));");
    src.push("    if (v.z < 0.0) {");
    src.push("        v.xy = (1.0 - abs(v.yx)) * vec2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0);");
    src.push("    }");
    src.push("    return normalize(v);");
    src.push("}");

    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("varying vec4 vFlags2;");
    }
    src.push("varying vec4 vColor;");

    src.push("void main(void) {");

    src.push("bool visible      = (float(flags.x) > 0.0);");
    src.push("bool xrayed       = (float(flags.y) > 0.0);");
    src.push("bool highlighted  = (float(flags.z) > 0.0);");
    src.push("bool selected     = (float(flags.w) > 0.0);");

    src.push("bool transparent  = ((float(color.a) / 255.0) < 1.0);");

    src.push(`if 
    (!visible || 
    (renderPass == ${RENDER_PASSES.NORMAL_OPAQUE} && (transparent || xrayed)) || 
    (renderPass == ${RENDER_PASSES.NORMAL_TRANSPARENT} && (!transparent || xrayed || highlighted || selected)) || 
    (renderPass == ${RENDER_PASSES.XRAYED} && (!xrayed || highlighted || selected)) || 
    (renderPass == ${RENDER_PASSES.HIGHLIGHTED} && !highlighted) ||
    (renderPass == ${RENDER_PASSES.SELECTED} && !selected)) {`);

    src.push("   gl_Position = vec4(0.0, 0.0, 0.0, 0.0);"); // Cull vertex
    src.push("} else {");

    src.push("vec4 worldPosition = positionsDecodeMatrix * vec4(position, 1.0); ");

    src.push("worldPosition = vec4(dot(worldPosition, modelMatrixCol0), dot(worldPosition, modelMatrixCol1), dot(worldPosition, modelMatrixCol2), 1.0);");

    src.push("vec4 viewPosition  = viewMatrix * worldPosition; ");

    src.push("vec4 modelNormal = vec4(octDecode(normal.xy), 0.0); ");
    src.push("vec4 worldNormal = vec4(dot(modelNormal, modelNormalMatrixCol0), dot(modelNormal, modelNormalMatrixCol1), dot(modelNormal, modelNormalMatrixCol2), 0.0);");
    src.push("vec3 viewNormal = normalize(vec4(worldNormal * viewNormalMatrix).xyz);");

    src.push("vec3 reflectedColor = vec3(0.0, 0.0, 0.0);");
    src.push("vec3 viewLightDir = vec3(0.0, 0.0, -1.0);");

    src.push("float lambertian = 1.0;");
    for (i = 0, len = lightsState.lights.length; i < len; i++) {
        light = lightsState.lights[i];
        if (light.type === "ambient") {
            continue;
        }
        if (light.type === "dir") {
            if (light.space === "view") {
                src.push("viewLightDir = normalize(lightDir" + i + ");");
            } else {
                src.push("viewLightDir = normalize((viewMatrix * vec4(lightDir" + i + ", 0.0)).xyz);");
            }
        } else if (light.type === "point") {
            if (light.space === "view") {
                src.push("viewLightDir = normalize(lightPos" + i + " - viewPosition.xyz);");
            } else {
                src.push("viewLightDir = normalize((viewMatrix * vec4(lightPos" + i + ", 0.0)).xyz);");
            }
        } else if (light.type === "spot") {
            if (light.space === "view") {
                src.push("viewLightDir = normalize(lightDir" + i + ");");
            } else {
                src.push("viewLightDir = normalize((viewMatrix * vec4(lightDir" + i + ", 0.0)).xyz);");
            }
        } else {
            continue;
        }
        src.push("lambertian = max(dot(-viewNormal, viewLightDir), 0.0);");
        src.push("reflectedColor += lambertian * (lightColor" + i + ".rgb * lightColor" + i + ".a);");
    }

    src.push("vColor = colorize *  vec4(reflectedColor * ((lightAmbient.rgb * lightAmbient.a) + vec3(float(color.r) / 255.0, float(color.g) / 255.0, float(color.b) / 255.0)), float(color.a) / 255.0);");

    if (clipping) {
        src.push("vWorldPosition = worldPosition;");
        src.push("vFlags2 = flags2;");
    }
    src.push("gl_Position = projMatrix * viewPosition;");
    src.push("}");
    src.push("}");
    return src;
}

function buildFragment(layer) {
    const scene = layer.model.scene;
    const sectionPlanesState = scene._sectionPlanesState;
    let i;
    let len;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    const src = [];
    src.push("// Instancing geometry drawing fragment shader");
    src.push("precision mediump float;");
    src.push("precision mediump int;");
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("varying vec4 vFlags2;");
        for (i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
            src.push("uniform bool sectionPlaneActive" + i + ";");
            src.push("uniform vec3 sectionPlanePos" + i + ";");
            src.push("uniform vec3 sectionPlaneDir" + i + ";");
        }
    }
    src.push("varying vec4 vColor;");
    src.push("void main(void) {");
    if (clipping) {
        src.push("  bool clippable = (float(vFlags2.x) > 0.0);");
        src.push("  if (clippable) {");
        src.push("  float dist = 0.0;");
        for (i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
            src.push("if (sectionPlaneActive" + i + ") {");
            src.push("   dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
            src.push("}");
        }
        src.push("if (dist > 0.0) { discard; }");
        src.push("}");
    }
    src.push("gl_FragColor = vColor;");
    src.push("}");
    return src;
}

export {InstancingDrawShaderSource};