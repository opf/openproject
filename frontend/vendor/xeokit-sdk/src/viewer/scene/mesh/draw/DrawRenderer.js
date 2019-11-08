/**
 * @author xeolabs / https://github.com/xeolabs
 */

import {Map} from "../../utils/Map.js";
import {DrawShaderSource} from "./DrawShaderSource.js";
import {Program} from "../../webgl/Program.js";
import {stats} from '../../stats.js';
import {WEBGL_INFO} from '../../webglInfo.js';

const ids = new Map({});

/**
 * @private
 */
const DrawRenderer = function (hash, mesh) {
    this.id = ids.addItem({});
    this._hash = hash;
    this._scene = mesh.scene;
    this._useCount = 0;
    this._shaderSource = new DrawShaderSource(mesh);
    this._allocate(mesh);
};

const drawRenderers = {};

DrawRenderer.get = function (mesh) {
    const scene = mesh.scene;
    const hash = [
        scene.canvas.canvas.id,
        (scene.gammaInput ? "gi;" : ";") + (scene.gammaOutput ? "go" : ""),
        scene._lightsState.getHash(),
        scene._sectionPlanesState.getHash(),
        mesh._geometry._state.hash,
        mesh._material._state.hash,
        mesh._state.drawHash
    ].join(";");
    let renderer = drawRenderers[hash];
    if (!renderer) {
        renderer = new DrawRenderer(hash, mesh);
        if (renderer.errors) {
            console.log(renderer.errors.join("\n"));
            return null;
        }
        drawRenderers[hash] = renderer;
        stats.memory.programs++;
    }
    renderer._useCount++;
    return renderer;
};

DrawRenderer.prototype.put = function () {
    if (--this._useCount === 0) {
        ids.removeItem(this.id);
        if (this._program) {
            this._program.destroy();
        }
        delete drawRenderers[this._hash];
        stats.memory.programs--;
    }
};

DrawRenderer.prototype.webglContextRestored = function () {
    this._program = null;
};

DrawRenderer.prototype.drawMesh = function (frame, mesh) {
    if (!this._program) {
        this._allocate(mesh);
    }
    const maxTextureUnits = WEBGL_INFO.MAX_TEXTURE_UNITS;
    const scene = mesh.scene;
    const material = mesh._material;
    const gl = scene.canvas.gl;
    const program = this._program;
    const meshState = mesh._state;
    const materialState = mesh._material._state;
    const geometryState = mesh._geometry._state;

    if (frame.lastProgramId !== this._program.id) {
        frame.lastProgramId = this._program.id;
        this._bindProgram(frame);
    }

    if (materialState.id !== this._lastMaterialId) {

        frame.textureUnit = this._baseTextureUnit;

        const backfaces = materialState.backfaces;
        if (frame.backfaces !== backfaces) {
            if (backfaces) {
                gl.disable(gl.CULL_FACE);
            } else {
                gl.enable(gl.CULL_FACE);
            }
            frame.backfaces = backfaces;
        }

        const frontface = materialState.frontface;
        if (frame.frontface !== frontface) {
            if (frontface) {
                gl.frontFace(gl.CCW);
            } else {
                gl.frontFace(gl.CW);
            }
            frame.frontface = frontface;
        }

        if (frame.lineWidth !== materialState.lineWidth) {
            gl.lineWidth(materialState.lineWidth);
            frame.lineWidth = materialState.lineWidth;
        }

        if (this._uPointSize) {
            gl.uniform1f(this._uPointSize, materialState.pointSize);
        }

        switch (materialState.type) {
            case "LambertMaterial":
                if (this._uMaterialAmbient) {
                    gl.uniform3fv(this._uMaterialAmbient, materialState.ambient);
                }
                if (this._uMaterialColor) {
                    gl.uniform4f(this._uMaterialColor, materialState.color[0], materialState.color[1], materialState.color[2], materialState.alpha);
                }
                if (this._uMaterialEmissive) {
                    gl.uniform3fv(this._uMaterialEmissive, materialState.emissive);
                }
                break;

            case "PhongMaterial":
                if (this._uMaterialShininess) {
                    gl.uniform1f(this._uMaterialShininess, materialState.shininess);
                }
                if (this._uMaterialAmbient) {
                    gl.uniform3fv(this._uMaterialAmbient, materialState.ambient);
                }
                if (this._uMaterialDiffuse) {
                    gl.uniform3fv(this._uMaterialDiffuse, materialState.diffuse);
                }
                if (this._uMaterialSpecular) {
                    gl.uniform3fv(this._uMaterialSpecular, materialState.specular);
                }
                if (this._uMaterialEmissive) {
                    gl.uniform3fv(this._uMaterialEmissive, materialState.emissive);
                }
                if (this._uAlphaModeCutoff) {
                    gl.uniform4f(
                        this._uAlphaModeCutoff,
                        1.0 * materialState.alpha,
                        materialState.alphaMode === 1 ? 1.0 : 0.0,
                        materialState.alphaCutoff,
                        0);
                }
                if (material._ambientMap && material._ambientMap._state.texture && this._uMaterialAmbientMap) {
                    program.bindTexture(this._uMaterialAmbientMap, material._ambientMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uMaterialAmbientMapMatrix) {
                        gl.uniformMatrix4fv(this._uMaterialAmbientMapMatrix, false, material._ambientMap._state.matrix);
                    }
                }
                if (material._diffuseMap && material._diffuseMap._state.texture && this._uDiffuseMap) {
                    program.bindTexture(this._uDiffuseMap, material._diffuseMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uDiffuseMapMatrix) {
                        gl.uniformMatrix4fv(this._uDiffuseMapMatrix, false, material._diffuseMap._state.matrix);
                    }
                }
                if (material._specularMap && material._specularMap._state.texture && this._uSpecularMap) {
                    program.bindTexture(this._uSpecularMap, material._specularMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uSpecularMapMatrix) {
                        gl.uniformMatrix4fv(this._uSpecularMapMatrix, false, material._specularMap._state.matrix);
                    }
                }
                if (material._emissiveMap && material._emissiveMap._state.texture && this._uEmissiveMap) {
                    program.bindTexture(this._uEmissiveMap, material._emissiveMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uEmissiveMapMatrix) {
                        gl.uniformMatrix4fv(this._uEmissiveMapMatrix, false, material._emissiveMap._state.matrix);
                    }
                }
                if (material._alphaMap && material._alphaMap._state.texture && this._uAlphaMap) {
                    program.bindTexture(this._uAlphaMap, material._alphaMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uAlphaMapMatrix) {
                        gl.uniformMatrix4fv(this._uAlphaMapMatrix, false, material._alphaMap._state.matrix);
                    }
                }
                if (material._reflectivityMap && material._reflectivityMap._state.texture && this._uReflectivityMap) {
                    program.bindTexture(this._uReflectivityMap, material._reflectivityMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    if (this._uReflectivityMapMatrix) {
                        gl.uniformMatrix4fv(this._uReflectivityMapMatrix, false, material._reflectivityMap._state.matrix);
                    }
                }
                if (material._normalMap && material._normalMap._state.texture && this._uNormalMap) {
                    program.bindTexture(this._uNormalMap, material._normalMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uNormalMapMatrix) {
                        gl.uniformMatrix4fv(this._uNormalMapMatrix, false, material._normalMap._state.matrix);
                    }
                }
                if (material._occlusionMap && material._occlusionMap._state.texture && this._uOcclusionMap) {
                    program.bindTexture(this._uOcclusionMap, material._occlusionMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uOcclusionMapMatrix) {
                        gl.uniformMatrix4fv(this._uOcclusionMapMatrix, false, material._occlusionMap._state.matrix);
                    }
                }
                if (material._diffuseFresnel) {
                    if (this._uDiffuseFresnelEdgeBias) {
                        gl.uniform1f(this._uDiffuseFresnelEdgeBias, material._diffuseFresnel.edgeBias);
                    }
                    if (this._uDiffuseFresnelCenterBias) {
                        gl.uniform1f(this._uDiffuseFresnelCenterBias, material._diffuseFresnel.centerBias);
                    }
                    if (this._uDiffuseFresnelEdgeColor) {
                        gl.uniform3fv(this._uDiffuseFresnelEdgeColor, material._diffuseFresnel.edgeColor);
                    }
                    if (this._uDiffuseFresnelCenterColor) {
                        gl.uniform3fv(this._uDiffuseFresnelCenterColor, material._diffuseFresnel.centerColor);
                    }
                    if (this._uDiffuseFresnelPower) {
                        gl.uniform1f(this._uDiffuseFresnelPower, material._diffuseFresnel.power);
                    }
                }
                if (material._specularFresnel) {
                    if (this._uSpecularFresnelEdgeBias) {
                        gl.uniform1f(this._uSpecularFresnelEdgeBias, material._specularFresnel.edgeBias);
                    }
                    if (this._uSpecularFresnelCenterBias) {
                        gl.uniform1f(this._uSpecularFresnelCenterBias, material._specularFresnel.centerBias);
                    }
                    if (this._uSpecularFresnelEdgeColor) {
                        gl.uniform3fv(this._uSpecularFresnelEdgeColor, material._specularFresnel.edgeColor);
                    }
                    if (this._uSpecularFresnelCenterColor) {
                        gl.uniform3fv(this._uSpecularFresnelCenterColor, material._specularFresnel.centerColor);
                    }
                    if (this._uSpecularFresnelPower) {
                        gl.uniform1f(this._uSpecularFresnelPower, material._specularFresnel.power);
                    }
                }
                if (material._alphaFresnel) {
                    if (this._uAlphaFresnelEdgeBias) {
                        gl.uniform1f(this._uAlphaFresnelEdgeBias, material._alphaFresnel.edgeBias);
                    }
                    if (this._uAlphaFresnelCenterBias) {
                        gl.uniform1f(this._uAlphaFresnelCenterBias, material._alphaFresnel.centerBias);
                    }
                    if (this._uAlphaFresnelEdgeColor) {
                        gl.uniform3fv(this._uAlphaFresnelEdgeColor, material._alphaFresnel.edgeColor);
                    }
                    if (this._uAlphaFresnelCenterColor) {
                        gl.uniform3fv(this._uAlphaFresnelCenterColor, material._alphaFresnel.centerColor);
                    }
                    if (this._uAlphaFresnelPower) {
                        gl.uniform1f(this._uAlphaFresnelPower, material._alphaFresnel.power);
                    }
                }
                if (material._reflectivityFresnel) {
                    if (this._uReflectivityFresnelEdgeBias) {
                        gl.uniform1f(this._uReflectivityFresnelEdgeBias, material._reflectivityFresnel.edgeBias);
                    }
                    if (this._uReflectivityFresnelCenterBias) {
                        gl.uniform1f(this._uReflectivityFresnelCenterBias, material._reflectivityFresnel.centerBias);
                    }
                    if (this._uReflectivityFresnelEdgeColor) {
                        gl.uniform3fv(this._uReflectivityFresnelEdgeColor, material._reflectivityFresnel.edgeColor);
                    }
                    if (this._uReflectivityFresnelCenterColor) {
                        gl.uniform3fv(this._uReflectivityFresnelCenterColor, material._reflectivityFresnel.centerColor);
                    }
                    if (this._uReflectivityFresnelPower) {
                        gl.uniform1f(this._uReflectivityFresnelPower, material._reflectivityFresnel.power);
                    }
                }
                if (material._emissiveFresnel) {
                    if (this._uEmissiveFresnelEdgeBias) {
                        gl.uniform1f(this._uEmissiveFresnelEdgeBias, material._emissiveFresnel.edgeBias);
                    }
                    if (this._uEmissiveFresnelCenterBias) {
                        gl.uniform1f(this._uEmissiveFresnelCenterBias, material._emissiveFresnel.centerBias);
                    }
                    if (this._uEmissiveFresnelEdgeColor) {
                        gl.uniform3fv(this._uEmissiveFresnelEdgeColor, material._emissiveFresnel.edgeColor);
                    }
                    if (this._uEmissiveFresnelCenterColor) {
                        gl.uniform3fv(this._uEmissiveFresnelCenterColor, material._emissiveFresnel.centerColor);
                    }
                    if (this._uEmissiveFresnelPower) {
                        gl.uniform1f(this._uEmissiveFresnelPower, material._emissiveFresnel.power);
                    }
                }
                break;

            case "MetallicMaterial":
                if (this._uBaseColor) {
                    gl.uniform3fv(this._uBaseColor, materialState.baseColor);
                }
                if (this._uMaterialMetallic) {
                    gl.uniform1f(this._uMaterialMetallic, materialState.metallic);
                }
                if (this._uMaterialRoughness) {
                    gl.uniform1f(this._uMaterialRoughness, materialState.roughness);
                }
                if (this._uMaterialSpecularF0) {
                    gl.uniform1f(this._uMaterialSpecularF0, materialState.specularF0);
                }
                if (this._uMaterialEmissive) {
                    gl.uniform3fv(this._uMaterialEmissive, materialState.emissive);
                }
                if (this._uAlphaModeCutoff) {
                    gl.uniform4f(
                        this._uAlphaModeCutoff,
                        1.0 * materialState.alpha,
                        materialState.alphaMode === 1 ? 1.0 : 0.0,
                        materialState.alphaCutoff,
                        0.0);
                }
                const baseColorMap = material._baseColorMap;
                if (baseColorMap && baseColorMap._state.texture && this._uBaseColorMap) {
                    program.bindTexture(this._uBaseColorMap, baseColorMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uBaseColorMapMatrix) {
                        gl.uniformMatrix4fv(this._uBaseColorMapMatrix, false, baseColorMap._state.matrix);
                    }
                }
                const metallicMap = material._metallicMap;
                if (metallicMap && metallicMap._state.texture && this._uMetallicMap) {
                    program.bindTexture(this._uMetallicMap, metallicMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uMetallicMapMatrix) {
                        gl.uniformMatrix4fv(this._uMetallicMapMatrix, false, metallicMap._state.matrix);
                    }
                }
                const roughnessMap = material._roughnessMap;
                if (roughnessMap && roughnessMap._state.texture && this._uRoughnessMap) {
                    program.bindTexture(this._uRoughnessMap, roughnessMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uRoughnessMapMatrix) {
                        gl.uniformMatrix4fv(this._uRoughnessMapMatrix, false, roughnessMap._state.matrix);
                    }
                }
                const metallicRoughnessMap = material._metallicRoughnessMap;
                if (metallicRoughnessMap && metallicRoughnessMap._state.texture && this._uMetallicRoughnessMap) {
                    program.bindTexture(this._uMetallicRoughnessMap, metallicRoughnessMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uMetallicRoughnessMapMatrix) {
                        gl.uniformMatrix4fv(this._uMetallicRoughnessMapMatrix, false, metallicRoughnessMap._state.matrix);
                    }
                }
                var emissiveMap = material._emissiveMap;
                if (emissiveMap && emissiveMap._state.texture && this._uEmissiveMap) {
                    program.bindTexture(this._uEmissiveMap, emissiveMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uEmissiveMapMatrix) {
                        gl.uniformMatrix4fv(this._uEmissiveMapMatrix, false, emissiveMap._state.matrix);
                    }
                }
                var occlusionMap = material._occlusionMap;
                if (occlusionMap && material._occlusionMap._state.texture && this._uOcclusionMap) {
                    program.bindTexture(this._uOcclusionMap, occlusionMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uOcclusionMapMatrix) {
                        gl.uniformMatrix4fv(this._uOcclusionMapMatrix, false, occlusionMap._state.matrix);
                    }
                }
                var alphaMap = material._alphaMap;
                if (alphaMap && alphaMap._state.texture && this._uAlphaMap) {
                    program.bindTexture(this._uAlphaMap, alphaMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uAlphaMapMatrix) {
                        gl.uniformMatrix4fv(this._uAlphaMapMatrix, false, alphaMap._state.matrix);
                    }
                }
                var normalMap = material._normalMap;
                if (normalMap && normalMap._state.texture && this._uNormalMap) {
                    program.bindTexture(this._uNormalMap, normalMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uNormalMapMatrix) {
                        gl.uniformMatrix4fv(this._uNormalMapMatrix, false, normalMap._state.matrix);
                    }
                }
                break;

            case "SpecularMaterial":
                if (this._uMaterialDiffuse) {
                    gl.uniform3fv(this._uMaterialDiffuse, materialState.diffuse);
                }
                if (this._uMaterialSpecular) {
                    gl.uniform3fv(this._uMaterialSpecular, materialState.specular);
                }
                if (this._uMaterialGlossiness) {
                    gl.uniform1f(this._uMaterialGlossiness, materialState.glossiness);
                }
                if (this._uMaterialReflectivity) {
                    gl.uniform1f(this._uMaterialReflectivity, materialState.reflectivity);
                }
                if (this._uMaterialEmissive) {
                    gl.uniform3fv(this._uMaterialEmissive, materialState.emissive);
                }
                if (this._uAlphaModeCutoff) {
                    gl.uniform4f(
                        this._uAlphaModeCutoff,
                        1.0 * materialState.alpha,
                        materialState.alphaMode === 1 ? 1.0 : 0.0,
                        materialState.alphaCutoff,
                        0.0);
                }
                const diffuseMap = material._diffuseMap;
                if (diffuseMap && diffuseMap._state.texture && this._uDiffuseMap) {
                    program.bindTexture(this._uDiffuseMap, diffuseMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uDiffuseMapMatrix) {
                        gl.uniformMatrix4fv(this._uDiffuseMapMatrix, false, diffuseMap._state.matrix);
                    }
                }
                const specularMap = material._specularMap;
                if (specularMap && specularMap._state.texture && this._uSpecularMap) {
                    program.bindTexture(this._uSpecularMap, specularMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uSpecularMapMatrix) {
                        gl.uniformMatrix4fv(this._uSpecularMapMatrix, false, specularMap._state.matrix);
                    }
                }
                const glossinessMap = material._glossinessMap;
                if (glossinessMap && glossinessMap._state.texture && this._uGlossinessMap) {
                    program.bindTexture(this._uGlossinessMap, glossinessMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uGlossinessMapMatrix) {
                        gl.uniformMatrix4fv(this._uGlossinessMapMatrix, false, glossinessMap._state.matrix);
                    }
                }
                const specularGlossinessMap = material._specularGlossinessMap;
                if (specularGlossinessMap && specularGlossinessMap._state.texture && this._uSpecularGlossinessMap) {
                    program.bindTexture(this._uSpecularGlossinessMap, specularGlossinessMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uSpecularGlossinessMapMatrix) {
                        gl.uniformMatrix4fv(this._uSpecularGlossinessMapMatrix, false, specularGlossinessMap._state.matrix);
                    }
                }
                var emissiveMap = material._emissiveMap;
                if (emissiveMap && emissiveMap._state.texture && this._uEmissiveMap) {
                    program.bindTexture(this._uEmissiveMap, emissiveMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uEmissiveMapMatrix) {
                        gl.uniformMatrix4fv(this._uEmissiveMapMatrix, false, emissiveMap._state.matrix);
                    }
                }
                var occlusionMap = material._occlusionMap;
                if (occlusionMap && occlusionMap._state.texture && this._uOcclusionMap) {
                    program.bindTexture(this._uOcclusionMap, occlusionMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uOcclusionMapMatrix) {
                        gl.uniformMatrix4fv(this._uOcclusionMapMatrix, false, occlusionMap._state.matrix);
                    }
                }
                var alphaMap = material._alphaMap;
                if (alphaMap && alphaMap._state.texture && this._uAlphaMap) {
                    program.bindTexture(this._uAlphaMap, alphaMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uAlphaMapMatrix) {
                        gl.uniformMatrix4fv(this._uAlphaMapMatrix, false, alphaMap._state.matrix);
                    }
                }
                var normalMap = material._normalMap;
                if (normalMap && normalMap._state.texture && this._uNormalMap) {
                    program.bindTexture(this._uNormalMap, normalMap._state.texture, frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                    if (this._uNormalMapMatrix) {
                        gl.uniformMatrix4fv(this._uNormalMapMatrix, false, normalMap._state.matrix);
                    }
                }
                break;
        }
        this._lastMaterialId = materialState.id;
    }

    gl.uniformMatrix4fv(this._uModelMatrix, gl.FALSE, mesh.worldMatrix);
    if (this._uModelNormalMatrix) {
        gl.uniformMatrix4fv(this._uModelNormalMatrix, gl.FALSE, mesh.worldNormalMatrix);
    }

    if (this._uClippable) {
        gl.uniform1i(this._uClippable, meshState.clippable);
    }

    if (this._uColorize) {
        const colorize = meshState.colorize;
        const lastColorize = this._lastColorize;
        if (lastColorize[0] !== colorize[0] ||
            lastColorize[1] !== colorize[1] ||
            lastColorize[2] !== colorize[2] ||
            lastColorize[3] !== colorize[3]) {
            gl.uniform4fv(this._uColorize, colorize);
            lastColorize[0] = colorize[0];
            lastColorize[1] = colorize[1];
            lastColorize[2] = colorize[2];
            lastColorize[3] = colorize[3];
        }
    }

    // Bind VBOs

    if (geometryState.id !== this._lastGeometryId) {
        if (this._uPositionsDecodeMatrix) {
            gl.uniformMatrix4fv(this._uPositionsDecodeMatrix, false, geometryState.positionsDecodeMatrix);
        }
        if (this._uUVDecodeMatrix) {
            gl.uniformMatrix3fv(this._uUVDecodeMatrix, false, geometryState.uvDecodeMatrix);
        }
        if (this._aPosition) {
            this._aPosition.bindArrayBuffer(geometryState.positionsBuf);
            frame.bindArray++;
        }
        if (this._aNormal) {
            this._aNormal.bindArrayBuffer(geometryState.normalsBuf);
            frame.bindArray++;
        }
        if (this._aUV) {
            this._aUV.bindArrayBuffer(geometryState.uvBuf);
            frame.bindArray++;
        }
        if (this._aColor) {
            this._aColor.bindArrayBuffer(geometryState.colorsBuf);
            frame.bindArray++;
        }
        if (this._aFlags) {
            this._aFlags.bindArrayBuffer(geometryState.flagsBuf);
            frame.bindArray++;
        }
        if (geometryState.indicesBuf) {
            geometryState.indicesBuf.bind();
            frame.bindArray++;
            // gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
            // frame.drawElements++;
        } else if (geometryState.positions) {
            // gl.drawArrays(gl.TRIANGLES, 0, geometryState.positions.numItems);
            //  frame.drawArrays++;
        }
        this._lastGeometryId = geometryState.id;
    }

    // Draw (indices bound in prev step)

    if (geometryState.indicesBuf) {
        gl.drawElements(geometryState.primitive, geometryState.indicesBuf.numItems, geometryState.indicesBuf.itemType, 0);
        frame.drawElements++;
    } else if (geometryState.positions) {
        gl.drawArrays(gl.TRIANGLES, 0, geometryState.positions.numItems);
        frame.drawArrays++;
    }
};

DrawRenderer.prototype._allocate = function (mesh) {
    const gl = mesh.scene.canvas.gl;
    const material = mesh._material;
    const lightsState = mesh.scene._lightsState;
    const sectionPlanesState = mesh.scene._sectionPlanesState;
    const materialState = mesh._material._state;
    this._program = new Program(gl, this._shaderSource);
    if (this._program.errors) {
        this.errors = this._program.errors;
        return;
    }
    const program = this._program;
    this._uPositionsDecodeMatrix = program.getLocation("positionsDecodeMatrix");
    this._uUVDecodeMatrix = program.getLocation("uvDecodeMatrix");
    this._uModelMatrix = program.getLocation("modelMatrix");
    this._uModelNormalMatrix = program.getLocation("modelNormalMatrix");
    this._uViewMatrix = program.getLocation("viewMatrix");
    this._uViewNormalMatrix = program.getLocation("viewNormalMatrix");
    this._uProjMatrix = program.getLocation("projMatrix");
    this._uGammaFactor = program.getLocation("gammaFactor");
    this._uLightAmbient = [];
    this._uLightColor = [];
    this._uLightDir = [];
    this._uLightPos = [];
    this._uLightAttenuation = [];
    this._uShadowViewMatrix = [];
    this._uShadowProjMatrix = [];

    const lights = lightsState.lights;
    let light;

    for (var i = 0, len = lights.length; i < len; i++) {
        light = lights[i];
        switch (light.type) {

            case "ambient":
                this._uLightAmbient[i] = program.getLocation("lightAmbient");
                break;

            case "dir":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = null;
                this._uLightDir[i] = program.getLocation("lightDir" + i);
                break;

            case "point":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = program.getLocation("lightPos" + i);
                this._uLightDir[i] = null;
                this._uLightAttenuation[i] = program.getLocation("lightAttenuation" + i);
                break;

            case "spot":
                this._uLightColor[i] = program.getLocation("lightColor" + i);
                this._uLightPos[i] = program.getLocation("lightPos" + i);
                this._uLightDir[i] = program.getLocation("lightDir" + i);
                this._uLightAttenuation[i] = program.getLocation("lightAttenuation" + i);
                break;
        }

        if (light.castsShadow) {
            this._uShadowViewMatrix[i] = program.getLocation("shadowViewMatrix" + i);
            this._uShadowProjMatrix[i] = program.getLocation("shadowProjMatrix" + i);
        }
    }

    if (lightsState.lightMaps.length > 0) {
        this._uLightMap = "lightMap";
    }

    if (lightsState.reflectionMaps.length > 0) {
        this._uReflectionMap = "reflectionMap";
    }

    this._uSectionPlanes = [];
    const sectionPlanes = sectionPlanesState.sectionPlanes;
    for (var i = 0, len = sectionPlanes.length; i < len; i++) {
        this._uSectionPlanes.push({
            active: program.getLocation("sectionPlaneActive" + i),
            pos: program.getLocation("sectionPlanePos" + i),
            dir: program.getLocation("sectionPlaneDir" + i)
        });
    }

    this._uPointSize = program.getLocation("pointSize");

    switch (materialState.type) {
        case "LambertMaterial":
            this._uMaterialColor = program.getLocation("materialColor");
            this._uMaterialEmissive = program.getLocation("materialEmissive");
            this._uAlphaModeCutoff = program.getLocation("materialAlphaModeCutoff");
            break;

        case "PhongMaterial":
            this._uMaterialAmbient = program.getLocation("materialAmbient");
            this._uMaterialDiffuse = program.getLocation("materialDiffuse");
            this._uMaterialSpecular = program.getLocation("materialSpecular");
            this._uMaterialEmissive = program.getLocation("materialEmissive");
            this._uAlphaModeCutoff = program.getLocation("materialAlphaModeCutoff");
            this._uMaterialShininess = program.getLocation("materialShininess");
            if (material._ambientMap) {
                this._uMaterialAmbientMap = "ambientMap";
                this._uMaterialAmbientMapMatrix = program.getLocation("ambientMapMatrix");
            }
            if (material._diffuseMap) {
                this._uDiffuseMap = "diffuseMap";
                this._uDiffuseMapMatrix = program.getLocation("diffuseMapMatrix");
            }
            if (material._specularMap) {
                this._uSpecularMap = "specularMap";
                this._uSpecularMapMatrix = program.getLocation("specularMapMatrix");
            }
            if (material._emissiveMap) {
                this._uEmissiveMap = "emissiveMap";
                this._uEmissiveMapMatrix = program.getLocation("emissiveMapMatrix");
            }
            if (material._alphaMap) {
                this._uAlphaMap = "alphaMap";
                this._uAlphaMapMatrix = program.getLocation("alphaMapMatrix");
            }
            if (material._reflectivityMap) {
                this._uReflectivityMap = "reflectivityMap";
                this._uReflectivityMapMatrix = program.getLocation("reflectivityMapMatrix");
            }
            if (material._normalMap) {
                this._uNormalMap = "normalMap";
                this._uNormalMapMatrix = program.getLocation("normalMapMatrix");
            }
            if (material._occlusionMap) {
                this._uOcclusionMap = "occlusionMap";
                this._uOcclusionMapMatrix = program.getLocation("occlusionMapMatrix");
            }
            if (material._diffuseFresnel) {
                this._uDiffuseFresnelEdgeBias = program.getLocation("diffuseFresnelEdgeBias");
                this._uDiffuseFresnelCenterBias = program.getLocation("diffuseFresnelCenterBias");
                this._uDiffuseFresnelEdgeColor = program.getLocation("diffuseFresnelEdgeColor");
                this._uDiffuseFresnelCenterColor = program.getLocation("diffuseFresnelCenterColor");
                this._uDiffuseFresnelPower = program.getLocation("diffuseFresnelPower");
            }
            if (material._specularFresnel) {
                this._uSpecularFresnelEdgeBias = program.getLocation("specularFresnelEdgeBias");
                this._uSpecularFresnelCenterBias = program.getLocation("specularFresnelCenterBias");
                this._uSpecularFresnelEdgeColor = program.getLocation("specularFresnelEdgeColor");
                this._uSpecularFresnelCenterColor = program.getLocation("specularFresnelCenterColor");
                this._uSpecularFresnelPower = program.getLocation("specularFresnelPower");
            }
            if (material._alphaFresnel) {
                this._uAlphaFresnelEdgeBias = program.getLocation("alphaFresnelEdgeBias");
                this._uAlphaFresnelCenterBias = program.getLocation("alphaFresnelCenterBias");
                this._uAlphaFresnelEdgeColor = program.getLocation("alphaFresnelEdgeColor");
                this._uAlphaFresnelCenterColor = program.getLocation("alphaFresnelCenterColor");
                this._uAlphaFresnelPower = program.getLocation("alphaFresnelPower");
            }
            if (material._reflectivityFresnel) {
                this._uReflectivityFresnelEdgeBias = program.getLocation("reflectivityFresnelEdgeBias");
                this._uReflectivityFresnelCenterBias = program.getLocation("reflectivityFresnelCenterBias");
                this._uReflectivityFresnelEdgeColor = program.getLocation("reflectivityFresnelEdgeColor");
                this._uReflectivityFresnelCenterColor = program.getLocation("reflectivityFresnelCenterColor");
                this._uReflectivityFresnelPower = program.getLocation("reflectivityFresnelPower");
            }
            if (material._emissiveFresnel) {
                this._uEmissiveFresnelEdgeBias = program.getLocation("emissiveFresnelEdgeBias");
                this._uEmissiveFresnelCenterBias = program.getLocation("emissiveFresnelCenterBias");
                this._uEmissiveFresnelEdgeColor = program.getLocation("emissiveFresnelEdgeColor");
                this._uEmissiveFresnelCenterColor = program.getLocation("emissiveFresnelCenterColor");
                this._uEmissiveFresnelPower = program.getLocation("emissiveFresnelPower");
            }
            break;

        case "MetallicMaterial":
            this._uBaseColor = program.getLocation("materialBaseColor");
            this._uMaterialMetallic = program.getLocation("materialMetallic");
            this._uMaterialRoughness = program.getLocation("materialRoughness");
            this._uMaterialSpecularF0 = program.getLocation("materialSpecularF0");
            this._uMaterialEmissive = program.getLocation("materialEmissive");
            this._uAlphaModeCutoff = program.getLocation("materialAlphaModeCutoff");
            if (material._baseColorMap) {
                this._uBaseColorMap = "baseColorMap";
                this._uBaseColorMapMatrix = program.getLocation("baseColorMapMatrix");
            }
            if (material._metallicMap) {
                this._uMetallicMap = "metallicMap";
                this._uMetallicMapMatrix = program.getLocation("metallicMapMatrix");
            }
            if (material._roughnessMap) {
                this._uRoughnessMap = "roughnessMap";
                this._uRoughnessMapMatrix = program.getLocation("roughnessMapMatrix");
            }
            if (material._metallicRoughnessMap) {
                this._uMetallicRoughnessMap = "metallicRoughnessMap";
                this._uMetallicRoughnessMapMatrix = program.getLocation("metallicRoughnessMapMatrix");
            }
            if (material._emissiveMap) {
                this._uEmissiveMap = "emissiveMap";
                this._uEmissiveMapMatrix = program.getLocation("emissiveMapMatrix");
            }
            if (material._occlusionMap) {
                this._uOcclusionMap = "occlusionMap";
                this._uOcclusionMapMatrix = program.getLocation("occlusionMapMatrix");
            }
            if (material._alphaMap) {
                this._uAlphaMap = "alphaMap";
                this._uAlphaMapMatrix = program.getLocation("alphaMapMatrix");
            }
            if (material._normalMap) {
                this._uNormalMap = "normalMap";
                this._uNormalMapMatrix = program.getLocation("normalMapMatrix");
            }
            break;

        case "SpecularMaterial":
            this._uMaterialDiffuse = program.getLocation("materialDiffuse");
            this._uMaterialSpecular = program.getLocation("materialSpecular");
            this._uMaterialGlossiness = program.getLocation("materialGlossiness");
            this._uMaterialReflectivity = program.getLocation("reflectivityFresnel");
            this._uMaterialEmissive = program.getLocation("materialEmissive");
            this._uAlphaModeCutoff = program.getLocation("materialAlphaModeCutoff");
            if (material._diffuseMap) {
                this._uDiffuseMap = "diffuseMap";
                this._uDiffuseMapMatrix = program.getLocation("diffuseMapMatrix");
            }
            if (material._specularMap) {
                this._uSpecularMap = "specularMap";
                this._uSpecularMapMatrix = program.getLocation("specularMapMatrix");
            }
            if (material._glossinessMap) {
                this._uGlossinessMap = "glossinessMap";
                this._uGlossinessMapMatrix = program.getLocation("glossinessMapMatrix");
            }
            if (material._specularGlossinessMap) {
                this._uSpecularGlossinessMap = "materialSpecularGlossinessMap";
                this._uSpecularGlossinessMapMatrix = program.getLocation("materialSpecularGlossinessMapMatrix");
            }
            if (material._emissiveMap) {
                this._uEmissiveMap = "emissiveMap";
                this._uEmissiveMapMatrix = program.getLocation("emissiveMapMatrix");
            }
            if (material._occlusionMap) {
                this._uOcclusionMap = "occlusionMap";
                this._uOcclusionMapMatrix = program.getLocation("occlusionMapMatrix");
            }
            if (material._alphaMap) {
                this._uAlphaMap = "alphaMap";
                this._uAlphaMapMatrix = program.getLocation("alphaMapMatrix");
            }
            if (material._normalMap) {
                this._uNormalMap = "normalMap";
                this._uNormalMapMatrix = program.getLocation("normalMapMatrix");
            }
            break;
    }

    this._aPosition = program.getAttribute("position");
    this._aNormal = program.getAttribute("normal");
    this._aUV = program.getAttribute("uv");
    this._aColor = program.getAttribute("color");
    this._aFlags = program.getAttribute("flags");

    this._uClippable = program.getLocation("clippable");
    this._uColorize = program.getLocation("colorize");

    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;

    this._lastColorize = new Float32Array(4);

    this._baseTextureUnit = 0;

};

DrawRenderer.prototype._bindProgram = function (frame) {

    const maxTextureUnits = WEBGL_INFO.MAX_TEXTURE_UNITS;
    const scene = this._scene;
    const gl = scene.canvas.gl;
    const lightsState = scene._lightsState;
    const sectionPlanesState = scene._sectionPlanesState;
    const lights = lightsState.lights;
    let light;

    const program = this._program;

    program.bind();

    frame.useProgram++;
    frame.textureUnit = 0;

    this._lastMaterialId = null;
    this._lastVertexBufsId = null;
    this._lastGeometryId = null;

    this._lastColorize[0] = -1;
    this._lastColorize[1] = -1;
    this._lastColorize[2] = -1;
    this._lastColorize[3] = -1;

    const camera = scene.camera;
    const cameraState = camera._state;

    gl.uniformMatrix4fv(this._uViewMatrix, false, cameraState.matrix);
    gl.uniformMatrix4fv(this._uViewNormalMatrix, false, cameraState.normalMatrix);
    gl.uniformMatrix4fv(this._uProjMatrix, false, camera._project._state.matrix);

    for (var i = 0, len = lightsState.lights.length; i < len; i++) {

        light = lightsState.lights[i];

        if (this._uLightAmbient[i]) {
            gl.uniform4f(this._uLightAmbient[i], light.color[0], light.color[1], light.color[2], light.intensity);

        } else {

            if (this._uLightColor[i]) {
                gl.uniform4f(this._uLightColor[i], light.color[0], light.color[1], light.color[2], light.intensity);
            }

            if (this._uLightPos[i]) {
                gl.uniform3fv(this._uLightPos[i], light.pos);
                if (this._uLightAttenuation[i]) {
                    gl.uniform1f(this._uLightAttenuation[i], light.attenuation);
                }
            }

            if (this._uLightDir[i]) {
                gl.uniform3fv(this._uLightDir[i], light.dir);
            }

            if (light.castsShadow) {
                if (this._uShadowViewMatrix[i]) {
                    gl.uniformMatrix4fv(this._uShadowViewMatrix[i], false, light.getShadowViewMatrix());
                }
                if (this._uShadowProjMatrix[i]) {
                    gl.uniformMatrix4fv(this._uShadowProjMatrix[i], false, light.getShadowProjMatrix());
                }
                const shadowRenderBuf = light.getShadowRenderBuf();
                if (shadowRenderBuf) {
                    program.bindTexture("shadowMap" + i, shadowRenderBuf.getTexture(), frame.textureUnit);
                    frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
                    frame.bindTexture++;
                }
            }
        }
    }

    if (lightsState.lightMaps.length > 0 && lightsState.lightMaps[0].texture && this._uLightMap) {
        program.bindTexture(this._uLightMap, lightsState.lightMaps[0].texture, frame.textureUnit);
        frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
        frame.bindTexture++;
    }

    if (lightsState.reflectionMaps.length > 0 && lightsState.reflectionMaps[0].texture && this._uReflectionMap) {
        program.bindTexture(this._uReflectionMap, lightsState.reflectionMaps[0].texture, frame.textureUnit);
        frame.textureUnit = (frame.textureUnit + 1) % maxTextureUnits;
        frame.bindTexture++;
    }

    if (sectionPlanesState.sectionPlanes.length > 0) {
        const sectionPlanes = scene._sectionPlanesState.sectionPlanes;
        let sectionPlaneUniforms;
        let uSectionPlaneActive;
        let sectionPlane;
        let uSectionPlanePos;
        let uSectionPlaneDir;
        for (var i = 0, len = this._uSectionPlanes.length; i < len; i++) {
            sectionPlaneUniforms = this._uSectionPlanes[i];
            uSectionPlaneActive = sectionPlaneUniforms.active;
            sectionPlane = sectionPlanes[i];
            if (uSectionPlaneActive) {
                gl.uniform1i(uSectionPlaneActive, sectionPlane.active);
            }
            uSectionPlanePos = sectionPlaneUniforms.pos;
            if (uSectionPlanePos) {
                gl.uniform3fv(sectionPlaneUniforms.pos, sectionPlane.pos);
            }
            uSectionPlaneDir = sectionPlaneUniforms.dir;
            if (uSectionPlaneDir) {
                gl.uniform3fv(sectionPlaneUniforms.dir, sectionPlane.dir);
            }
        }
    }

    if (this._uGammaFactor) {
        gl.uniform1f(this._uGammaFactor, scene.gammaFactor);
    }

    this._baseTextureUnit = frame.textureUnit;
};

export {DrawRenderer};