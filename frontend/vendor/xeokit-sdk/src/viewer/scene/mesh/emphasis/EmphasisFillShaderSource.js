/**
 * @author xeolabs / https://github.com/xeolabs
 */

/**
 * @private
 */
class EmphasisFillShaderSource {
    constructor(mesh) {
        this.vertex = buildVertex(mesh);
        this.fragment = buildFragment(mesh);
    }
}

function buildVertex(mesh) {
    const scene = mesh.scene;
    const lightsState = scene._lightsState;
    const normals = hasNormals(mesh);
    const clipping = scene._sectionPlanesState.sectionPlanes.length > 0;
    const quantizedGeometry = !!mesh._geometry._state.compressGeometry;
    const billboard = mesh._state.billboard;
    const stationary = mesh._state.stationary;
    const src = [];
    let i;
    let len;
    let light;
    src.push("// EmphasisFillShaderSource vertex shader");
    src.push("attribute vec3 position;");
    src.push("uniform mat4 modelMatrix;");
    src.push("uniform mat4 viewMatrix;");
    src.push("uniform mat4 projMatrix;");
    src.push("uniform vec4 colorize;");
    if (quantizedGeometry) {
        src.push("uniform mat4 positionsDecodeMatrix;");
    }
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
    }
    src.push("uniform vec4   lightAmbient;");
    src.push("uniform vec4   fillColor;");
    if (normals) {
        src.push("attribute vec3 normal;");
        src.push("uniform mat4 modelNormalMatrix;");
        src.push("uniform mat4 viewNormalMatrix;");
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
            }
        }
        if (quantizedGeometry) {
            src.push("vec3 octDecode(vec2 oct) {");
            src.push("    vec3 v = vec3(oct.xy, 1.0 - abs(oct.x) - abs(oct.y));");
            src.push("    if (v.z < 0.0) {");
            src.push("        v.xy = (1.0 - abs(v.yx)) * vec2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0);");
            src.push("    }");
            src.push("    return normalize(v);");
            src.push("}");
        }
    }
    src.push("varying vec4 vColor;");
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
    if (normals) {
        if (quantizedGeometry) {
            src.push("vec4 localNormal = vec4(octDecode(normal.xy), 0.0); ");
        } else {
            src.push("vec4 localNormal = vec4(normal, 0.0); ");
        }
        src.push("mat4 modelNormalMatrix2 = modelNormalMatrix;");
        src.push("mat4 viewNormalMatrix2 = viewNormalMatrix;");
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
        src.push("billboard(modelViewMatrix);");
        if (normals) {
            src.push("mat4 modelViewNormalMatrix =  viewNormalMatrix2 * modelNormalMatrix2;");
            src.push("billboard(modelNormalMatrix2);");
            src.push("billboard(viewNormalMatrix2);");
            src.push("billboard(modelViewNormalMatrix);");
        }
        src.push("worldPosition = modelMatrix2 * localPosition;");
        src.push("vec4 viewPosition = modelViewMatrix * localPosition;");
    } else {
        src.push("worldPosition = modelMatrix2 * localPosition;");
        src.push("vec4 viewPosition  = viewMatrix2 * worldPosition; ");
    }
    if (normals) {
        src.push("vec3 viewNormal = normalize((viewNormalMatrix2 * modelNormalMatrix2 * localNormal).xyz);");
    }
    src.push("vec3 reflectedColor = vec3(0.0, 0.0, 0.0);");
    src.push("vec3 viewLightDir = vec3(0.0, 0.0, -1.0);");
    src.push("float lambertian = 1.0;");
    if (normals) {
        for (i = 0, len = lightsState.lights.length; i < len; i++) {
            light = lightsState.lights[i];
            if (light.type === "ambient") {
                continue;
            }
            if (light.type === "dir") {
                if (light.space === "view") {
                    src.push("viewLightDir = normalize(lightDir" + i + ");");
                } else {
                    src.push("viewLightDir = normalize((viewMatrix2 * vec4(lightDir" + i + ", 0.0)).xyz);");
                }
            } else if (light.type === "point") {
                if (light.space === "view") {
                    src.push("viewLightDir = normalize(lightPos" + i + " - viewPosition.xyz);");
                } else {
                    src.push("viewLightDir = normalize((viewMatrix2 * vec4(lightPos" + i + ", 0.0)).xyz);");
                }
            } else {
                continue;
            }
            src.push("lambertian = max(dot(-viewNormal, viewLightDir), 0.0);");
            src.push("reflectedColor += lambertian * (lightColor" + i + ".rgb * lightColor" + i + ".a);");
        }
    }
    // TODO: A blending mode for emphasis materials, to select add/multiply/mix
    //src.push("vColor = vec4((mix(reflectedColor, fillColor.rgb, 0.7)), fillColor.a);");
    src.push("vColor = vec4(reflectedColor * fillColor.rgb, fillColor.a);");
    //src.push("vColor = vec4(reflectedColor + fillColor.rgb, fillColor.a);");
    if (clipping) {
        src.push("vWorldPosition = worldPosition;");
    }
    if (mesh._geometry._state.primitiveName === "points") {
        src.push("gl_PointSize = pointSize;");
    }
    src.push("   gl_Position = projMatrix * viewPosition;");
    src.push("}");
    return src;
}

function hasNormals(mesh) {
    const primitive = mesh._geometry._state.primitiveName;
    if ((mesh._geometry._state.autoVertexNormals || mesh._geometry._state.normalsBuf) && (primitive === "triangles" || primitive === "triangle-strip" || primitive === "triangle-fan")) {
        return true;
    }
    return false;
}

function buildFragment(mesh) {
    const sectionPlanesState = mesh.scene._sectionPlanesState;
    const gammaOutput = mesh.scene.gammaOutput;
    const clipping = sectionPlanesState.sectionPlanes.length > 0;
    let i;
    let len;
    const src = [];
    src.push("// Lambertian drawing fragment shader");
    src.push("precision lowp float;");
    if (gammaOutput) {
        src.push("uniform float gammaFactor;");
        src.push("vec4 linearToGamma( in vec4 value, in float gammaFactor ) {");
        src.push("  return vec4( pow( value.xyz, vec3( 1.0 / gammaFactor ) ), value.w );");
        src.push("}");
    }
    if (clipping) {
        src.push("varying vec4 vWorldPosition;");
        src.push("uniform bool clippable;");
        for (i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
            src.push("uniform bool sectionPlaneActive" + i + ";");
            src.push("uniform vec3 sectionPlanePos" + i + ";");
            src.push("uniform vec3 sectionPlaneDir" + i + ";");
        }
    }
    src.push("varying vec4 vColor;");
    src.push("void main(void) {");
    if (clipping) {
        src.push("if (clippable) {");
        src.push("  float dist = 0.0;");
        for (i = 0, len = sectionPlanesState.sectionPlanes.length; i < len; i++) {
            src.push("if (sectionPlaneActive" + i + ") {");
            src.push("   dist += clamp(dot(-sectionPlaneDir" + i + ".xyz, vWorldPosition.xyz - sectionPlanePos" + i + ".xyz), 0.0, 1000.0);");
            src.push("}");
        }
        src.push("  if (dist > 0.0) { discard; }");
        src.push("}");
    }
    if (mesh._geometry._state.primitiveName === "points") {
        src.push("vec2 cxy = 2.0 * gl_PointCoord - 1.0;");
        src.push("float r = dot(cxy, cxy);");
        src.push("if (r > 1.0) {");
        src.push("   discard;");
        src.push("}");
    }
    src.push("gl_FragColor = vColor;");
    if (gammaOutput) {
        src.push("gl_FragColor = linearToGamma(vColor, gammaFactor);");
    } else {
        src.push("gl_FragColor = vColor;");
    }
    src.push("}");
    return src;
}

export {EmphasisFillShaderSource};