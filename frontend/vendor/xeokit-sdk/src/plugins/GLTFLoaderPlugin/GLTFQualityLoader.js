import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {VBOGeometry} from "../../viewer/scene/geometry/VBOGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {MetallicMaterial} from "../../viewer/scene/materials/MetallicMaterial.js";
import {SpecularMaterial} from "../../viewer/scene/materials/SpecularMaterial.js";
import {Texture} from "../../viewer/scene/materials/Texture.js";
import {Node} from "../../viewer/scene/nodes/Node.js";
import {math} from "../../viewer/scene/math/math.js";
import {utils} from "../../viewer/scene/utils.js";
import {core} from "../../viewer/scene/core.js";

/**
 * @private
 */
class GLTFQualityLoader {

    constructor(cfg) { // TODO: Loading options fallbacks on loader, eg. handleGLTFNode etc
        cfg = cfg || {};
    }

    load(plugin, modelNode, src, options, ok, error) {
        options = options || {};
        var spinner = modelNode.scene.canvas.spinner;
        spinner.processes++;
        loadGLTF(plugin, modelNode, src, options, function () {
                spinner.processes--;
                core.scheduleTask(function () {
                    modelNode.scene.fire("modelLoaded", modelNode.id); // FIXME: Assumes listeners know order of these two events
                    modelNode.fire("loaded", true, true);
                });
                if (ok) {
                    ok();
                }
            },
            function (msg) {
                spinner.processes--;
                modelNode.error(msg);
                if (error) {
                    error(msg);
                }
                modelNode.fire("error", msg);
            });
    }

    parse(plugin, modelNode, gltf, options, ok, error) {
        options = options || {};
        var spinner = modelNode.scene.canvas.spinner;
        spinner.processes++;
        parseGLTF(plugin, gltf, "", options, plugin, modelNode, function () {
                spinner.processes--;
                modelNode.scene.fire("modelLoaded", modelNode.id); // FIXME: Assumes listeners know order of these two events
                modelNode.fire("loaded", true, true);
                if (ok) {
                    ok();
                }
            },
            function (msg) {
                spinner.processes--;
                modelNode.error(msg);
                modelNode.fire("error", msg);
                if (error) {
                    error(msg);
                }
            });
    }
}


var loadGLTF = (function () {
    return function (plugin, modelNode, src, options, ok, error) {
        plugin.dataSource.getGLTF(src, function (json) { // OK
                options.basePath = getBasePath(src);
                parseGLTF(plugin, json, src, options, modelNode, ok, error);
            },
            error);
    };

    function getBasePath(src) {
        var i = src.lastIndexOf("/");
        return (i !== 0) ? src.substring(0, i + 1) : "";
    }
})();

var parseGLTF = (function () {

    const WEBGL_COMPONENT_TYPES = {
        5120: Int8Array,
        5121: Uint8Array,
        5122: Int16Array,
        5123: Uint16Array,
        5125: Uint32Array,
        5126: Float32Array
    };

    const WEBGL_TYPE_SIZES = {
        'SCALAR': 1,
        'VEC2': 2,
        'VEC3': 3,
        'VEC4': 4,
        'MAT2': 4,
        'MAT3': 9,
        'MAT4': 16
    };

    return function (plugin, json, src, options, modelNode, ok) {
        modelNode.clear();
        var ctx = {
            src: src,
            loadBuffer: options.loadBuffer,
            basePath: options.basePath,
            prioritizeGLTFNode: options.prioritizeGLTFNode,
            handleGLTFNode: options.handleGLTFNode,
            ignoreMaterials: !!options.ignoreMaterials,
            edgeThreshold: options.edgeThreshold,
            readableGeometry: !!options.readableGeometry,
            json: json,
            scene: modelNode.scene,
            plugin: plugin,
            modelNode: modelNode,
            modelNodeProps: {
                visible: modelNode.visible,
                culled: modelNode.culled,
                xrayed: modelNode.xrayed,
                highlighted: modelNode.highlighted,
                selected: modelNode.selected,
                outlined: modelNode.outlined,
                clippable: modelNode.clippable,
                pickable: modelNode.pickable,
                collidable: modelNode.collidable,
                castsShadow: modelNode.castsShadow,
                receivesShadow: modelNode.receivesShadow,
                colorize: modelNode.colorize,
                opacity: modelNode.opacity,
                edges: modelNode.edges
            }
        };

        modelNode.scene.loading++; // Disables (re)compilation

        loadBuffers(ctx, function () {

            loadBufferViews(ctx);
            loadAccessors(ctx);
            loadTextures(ctx);
            loadMaterials(ctx);
            loadMeshes(ctx);
            loadDefaultScene(ctx);

            modelNode.scene.loading--; // Re-enables (re)compilation

            ok();
        });
    };

    function loadBuffers(ctx, ok) {
        var buffers = ctx.json.buffers;
        if (buffers) {
            var numToLoad = buffers.length;
            for (var i = 0, len = buffers.length; i < len; i++) {
                loadBuffer(ctx, buffers[i], function () {
                    if (--numToLoad === 0) {
                        ok();
                    }
                }, function (msg) {
                    ctx.plugin.error(msg);
                    if (--numToLoad === 0) {
                        ok();
                    }
                });
            }
        } else {
            ok();
        }
    }

    function loadBuffer(ctx, bufferInfo, ok, err) {
        var uri = bufferInfo.uri;
        if (uri) {
            ctx.plugin.dataSource.getArrayBuffer(ctx.src, uri, function (data) {
                    bufferInfo._buffer = data;
                    ok();
                },
                err);
        } else {
            err('gltf/handleBuffer missing uri in ' + JSON.stringify(bufferInfo));
        }
    }

    function loadBufferViews(ctx) {
        var bufferViewsInfo = ctx.json.bufferViews;
        if (bufferViewsInfo) {
            for (var i = 0, len = bufferViewsInfo.length; i < len; i++) {
                loadBufferView(ctx, bufferViewsInfo[i]);
            }
        }
    }

    function loadBufferView(ctx, bufferViewInfo) {

        var buffer = ctx.json.buffers[bufferViewInfo.buffer];

        bufferViewInfo._typedArray = null;

        var byteLength = bufferViewInfo.byteLength || 0;
        var byteOffset = bufferViewInfo.byteOffset || 0;

        bufferViewInfo._buffer = buffer._buffer.slice(byteOffset, byteOffset + byteLength);
    }

    function loadAccessors(ctx) {
        var accessorsInfo = ctx.json.accessors;
        if (accessorsInfo) {
            for (var i = 0, len = accessorsInfo.length; i < len; i++) {
                loadAccessor(ctx, accessorsInfo[i]);
            }
        }
    }

    function loadAccessor(ctx, accessorInfo) {
        var bufferViewInfo = ctx.json.bufferViews[accessorInfo.bufferView];
        var itemSize = WEBGL_TYPE_SIZES[accessorInfo.type];
        var TypedArray = WEBGL_COMPONENT_TYPES[accessorInfo.componentType];

        // For VEC3: itemSize is 3, elementBytes is 4, itemBytes is 12.
        var elementBytes = TypedArray.BYTES_PER_ELEMENT;
        var itemBytes = elementBytes * itemSize;

        // The buffer is not interleaved if the stride is the item size in bytes.
        if (accessorInfo.byteStride && accessorInfo.byteStride !== itemBytes) {

        } else {
            accessorInfo._typedArray = new TypedArray(bufferViewInfo._buffer, accessorInfo.byteOffset || 0, accessorInfo.count * itemSize);
            accessorInfo._itemSize = itemSize;
        }
    }


    function loadTextures(ctx) {
        var texturesInfo = ctx.json.textures;
        if (texturesInfo) {
            for (var i = 0, len = texturesInfo.length; i < len; i++) {
                loadTexture(ctx, texturesInfo[i]);
            }
        }
    }

    function loadTexture(ctx, textureInfo) {
        textureInfo._texture = new Texture(ctx.modelNode, {
            src: ctx.json.images[textureInfo.source].uri ? ctx.basePath + ctx.json.images[textureInfo.source].uri : undefined,
            flipY: !!textureInfo.flipY,
            encoding: "sRGB"
        });
    }

    function loadMaterials(ctx) {
        var materialsInfo = ctx.json.materials;
        if (materialsInfo) {
            var materialInfo;
            var material;
            for (var i = 0, len = materialsInfo.length; i < len; i++) {
                materialInfo = materialsInfo[i];
                material = loadMaterial(ctx, materialInfo);
                materialInfo._material = material;
            }
        }
    }

    function loadMaterial(ctx, materialInfo) {

        var json = ctx.json;
        var cfg = {};
        var textureInfo;

        // Common attributes

        var normalTexture = materialInfo.normalTexture;
        if (normalTexture) {
            textureInfo = json.textures[normalTexture.index];
            if (textureInfo) {
                cfg.normalMap = textureInfo._texture;
                //cfg.normalMap.encoding = "linear";
            }
        }

        var occlusionTexture = materialInfo.occlusionTexture;
        if (occlusionTexture) {
            textureInfo = json.textures[occlusionTexture.index];
            if (textureInfo) {
                cfg.occlusionMap = textureInfo._texture;
            }
        }

        var emissiveTexture = materialInfo.emissiveTexture;
        if (emissiveTexture) {
            textureInfo = json.textures[emissiveTexture.index];
            if (textureInfo) {
                cfg.emissiveMap = textureInfo._texture;
                //cfg.emissiveMap.encoding = "sRGB";
            }
        }

        var emissiveFactor = materialInfo.emissiveFactor;
        if (emissiveFactor) {
            cfg.emissive = emissiveFactor;
        }

        cfg.backfaces = !!materialInfo.doubleSided;

        var alphaMode = materialInfo.alphaMode;
        switch (alphaMode) {
            case "NORMAL_OPAQUE":
                cfg.alphaMode = "opaque";
                break;
            case "MASK":
                cfg.alphaMode = "mask";
                break;
            case "BLEND":
                cfg.alphaMode = "blend";
                break;
            default:
        }

        var alphaCutoff = materialInfo.alphaCutoff;
        if (alphaCutoff !== undefined) {
            cfg.alphaCutoff = alphaCutoff;
        }

        var extensions = materialInfo.extensions;
        if (extensions) {

            // Specular PBR material

            var specularPBR = extensions["KHR_materials_pbrSpecularGlossiness"];
            if (specularPBR) {

                var diffuseFactor = specularPBR.diffuseFactor;
                if (diffuseFactor !== null && diffuseFactor !== undefined) {
                    cfg.diffuse = diffuseFactor.slice(0, 3);
                    cfg.alpha = diffuseFactor[3];
                }

                var diffuseTexture = specularPBR.diffuseTexture;
                if (diffuseTexture) {
                    textureInfo = json.textures[diffuseTexture.index];
                    if (textureInfo) {
                        cfg.diffuseMap = textureInfo._texture;
                        //cfg.diffuseMap.encoding = "sRGB";
                    }
                }

                var specularFactor = specularPBR.specularFactor;
                if (specularFactor !== null && specularFactor !== undefined) {
                    cfg.specular = specularFactor.slice(0, 3);
                }

                var glossinessFactor = specularPBR.glossinessFactor;
                if (glossinessFactor !== null && glossinessFactor !== undefined) {
                    cfg.glossiness = glossinessFactor;
                }

                var specularGlossinessTexture = specularPBR.specularGlossinessTexture;
                if (specularGlossinessTexture) {
                    textureInfo = json.textures[specularGlossinessTexture.index];
                    if (textureInfo) {
                        cfg.specularGlossinessMap = textureInfo._texture;
                        //cfg.specularGlossinessMap.encoding = "linear";
                    }
                }

                return new SpecularMaterial(ctx.modelNode, cfg);
            }

            // Common Phong, Blinn, Lambert or Constant materials

            var common = extensions["KHR_materials_common"];
            if (common) {

                var technique = common.technique;
                var values = common.values || {};

                var blinn = technique === "BLINN";
                var phong = technique === "PHONG";
                var lambert = technique === "LAMBERT";
                var constant = technique === "CONSTANT";

                var shininess = values.shininess;
                if ((blinn || phong) && shininess !== null && shininess !== undefined) {
                    cfg.shininess = shininess;
                } else {
                    cfg.shininess = 0;
                }
                var texture;
                var diffuse = values.diffuse;
                if (diffuse && (blinn || phong || lambert)) {
                    if (utils.isString(diffuse)) {
                        texture = ctx.textures[diffuse];
                        if (texture) {
                            cfg.diffuseMap = texture;
                            //  cfg.diffuseMap.encoding = "sRGB";
                        }
                    } else {
                        cfg.diffuse = diffuse.slice(0, 3);
                    }
                } else {
                    cfg.diffuse = [0, 0, 0];
                }

                var specular = values.specular;
                if (specular && (blinn || phong)) {
                    if (utils.isString(specular)) {
                        texture = ctx.textures[specular];
                        if (texture) {
                            cfg.specularMap = texture;
                        }
                    } else {
                        cfg.specular = specular.slice(0, 3);
                    }
                } else {
                    cfg.specular = [0, 0, 0];
                }

                var emission = values.emission;
                if (emission) {
                    if (utils.isString(emission)) {
                        texture = ctx.textures[emission];
                        if (texture) {
                            cfg.emissiveMap = texture;
                        }
                    } else {
                        cfg.emissive = emission.slice(0, 3);
                    }
                } else {
                    cfg.emissive = [0, 0, 0];
                }

                var transparency = values.transparency;
                if (transparency !== null && transparency !== undefined) {
                    cfg.alpha = transparency;
                } else {
                    cfg.alpha = 1.0;
                }

                var transparent = values.transparent;
                if (transparent !== null && transparent !== undefined) {
                    //cfg.transparent = transparent;
                } else {
                    //cfg.transparent = 1.0;
                }

                return new PhongMaterial(ctx.scene, cfg);
            }
        }

        // Metallic PBR naterial

        var metallicPBR = materialInfo.pbrMetallicRoughness;
        if (metallicPBR) {

            var baseColorFactor = metallicPBR.baseColorFactor;
            if (baseColorFactor) {
                cfg.baseColor = baseColorFactor.slice(0, 3);
                cfg.alpha = baseColorFactor[3];
            }

            var baseColorTexture = metallicPBR.baseColorTexture;
            if (baseColorTexture) {
                textureInfo = json.textures[baseColorTexture.index];
                if (textureInfo) {
                    cfg.baseColorMap = textureInfo._texture;
                    //cfg.baseColorMap.encoding = "sRGB";
                }
            }

            var metallicFactor = metallicPBR.metallicFactor;
            if (metallicFactor !== null && metallicFactor !== undefined) {
                cfg.metallic = metallicFactor;
            }

            var roughnessFactor = metallicPBR.roughnessFactor;
            if (roughnessFactor !== null && roughnessFactor !== undefined) {
                cfg.roughness = roughnessFactor;
            }

            var metallicRoughnessTexture = metallicPBR.metallicRoughnessTexture;
            if (metallicRoughnessTexture) {
                textureInfo = json.textures[metallicRoughnessTexture.index];
                if (textureInfo) {
                    cfg.metallicRoughnessMap = textureInfo._texture;
                    // cfg.metallicRoughnessMap.encoding = "linear";
                }
            }

            return new MetallicMaterial(ctx.scene, cfg);
        }

        // Default material

        return new PhongMaterial(ctx.scene, cfg);
    }

    // Extract diffuse/baseColor and alpha into RGBA Mesh 'colorize' property
    function loadMaterialColorize(ctx, materialInfo) {

        var json = ctx.json;
        var colorize = new Float32Array([1, 1, 1, 1]);

        var extensions = materialInfo.extensions;
        if (extensions) {

            // Specular PBR material

            var specularPBR = extensions["KHR_materials_pbrSpecularGlossiness"];
            if (specularPBR) {
                var diffuseFactor = specularPBR.diffuseFactor;
                if (diffuseFactor !== null && diffuseFactor !== undefined) {
                    colorize.set(diffuseFactor);
                }
            }

            // Common Phong, Blinn, Lambert or Constant materials

            var common = extensions["KHR_materials_common"];
            if (common) {

                var technique = common.technique;
                var values = common.values || {};

                var blinn = technique === "BLINN";
                var phong = technique === "PHONG";
                var lambert = technique === "LAMBERT";
                var constant = technique === "CONSTANT";

                var diffuse = values.diffuse;
                if (diffuse && (blinn || phong || lambert)) {
                    if (!utils.isString(diffuse)) {
                        colorize.set(diffuse);
                    }
                }

                var transparency = values.transparency;
                if (transparency !== null && transparency !== undefined) {
                    colorize[3] = transparency;
                }

                var transparent = values.transparent;
                if (transparent !== null && transparent !== undefined) {
                    colorize[3] = transparent;
                }
            }
        }

        // Metallic PBR naterial

        var metallicPBR = materialInfo.pbrMetallicRoughness;
        if (metallicPBR) {
            var baseColorFactor = metallicPBR.baseColorFactor;
            if (baseColorFactor) {
                colorize.set(baseColorFactor);
            }
        }

        return colorize;
    }

    function loadMeshes(ctx) {
        var meshes = ctx.json.meshes;
        if (meshes) {
            for (var i = 0, len = meshes.length; i < len; i++) {
                loadMesh(ctx, meshes[i]);
            }
        }
    }

    function loadMesh(ctx, meshInfo) {
        var json = ctx.json;
        var mesh = [];
        var primitivesInfo = meshInfo.primitives;
        var materialIndex;
        var materialInfo;
        var accessorInfo;
        var attributes;

        if (primitivesInfo) {

            var primitiveInfo;
            var indicesIndex;
            var positionsIndex;
            var normalsIndex;
            var uv0Index;
            var geometryCfg;
            var meshCfg;
            var geometry;

            for (var i = 0, len = primitivesInfo.length; i < len; i++) {

                geometryCfg = {
                    primitive: "triangles",
                    compressGeometry: true,
                    edgeThreshold: ctx.edgeThreshold
                };

                primitiveInfo = primitivesInfo[i];
                indicesIndex = primitiveInfo.indices;

                if (indicesIndex !== null && indicesIndex !== undefined) {
                    accessorInfo = json.accessors[indicesIndex];
                    geometryCfg.indices = accessorInfo._typedArray;
                }

                attributes = primitiveInfo.attributes;
                if (!attributes) {
                    continue;
                }

                positionsIndex = attributes.POSITION;

                if (positionsIndex !== null && positionsIndex !== undefined) {
                    accessorInfo = json.accessors[positionsIndex];
                    geometryCfg.positions = accessorInfo._typedArray;
                }

                normalsIndex = attributes.NORMAL;

                if (normalsIndex !== null && normalsIndex !== undefined) {
                    accessorInfo = json.accessors[normalsIndex];
                    geometryCfg.normals = accessorInfo._typedArray;
                }

                uv0Index = attributes.TEXCOORD_0;

                if (uv0Index !== null && uv0Index !== undefined) {
                    accessorInfo = json.accessors[uv0Index];
                    geometryCfg.uv = accessorInfo._typedArray;
                }

                meshCfg = {};

                if (ctx.readableGeometry) {
                    geometry = new ReadableGeometry(ctx.modelNode, geometryCfg);
                } else {
                    geometry = new VBOGeometry(ctx.modelNode, geometryCfg);
                }

                meshCfg.geometry = geometry;

                materialIndex = primitiveInfo.material;
                if (materialIndex !== null && materialIndex !== undefined) {
                    materialInfo = json.materials[materialIndex];
                    if (materialInfo) {
                        meshCfg.material = materialInfo._material;
                    }
                }

                mesh.push(meshCfg);
            }
        }
        meshInfo._mesh = mesh;
    }

    function loadDefaultScene(ctx) {
        var json = ctx.json;
        var scene = json.scene || 0;
        var defaultSceneInfo = json.scenes[scene];
        if (!defaultSceneInfo) {
            error(ctx, "glTF has no default scene");
            return;
        }
        loadScene(ctx, defaultSceneInfo);
    }

    function loadScene(ctx, sceneInfo) {
        var nodes = sceneInfo.nodes;
        if (!nodes) {
            return;
        }
        var json = ctx.json;
        var glTFNode;
        for (var i = 0, len = nodes.length; i < len; i++) {
            glTFNode = json.nodes[nodes[i]];
            if (!glTFNode) {
                error(ctx, "Node not found: " + i);
                continue;
            }
            loadNode(ctx, glTFNode, null, null);
        }
    }

    function loadNode(ctx, glTFNode, matrix, parent) {

        parent = parent || ctx.modelNode;

        var createEntity;

        if (ctx.prioritizeGLTFNode) {
            const priority = ctx.prioritizeGLTFNode(ctx.modelNode.id, glTFNode);
            if (priority === undefined || priority === null) {
                return;
            }
        }

        if (ctx.handleGLTFNode) {
            var actions = {};
            if (!ctx.handleGLTFNode(ctx.modelNode.id, glTFNode, actions)) {
                return;
            }
            if (actions.createEntity) {
                createEntity = actions.createEntity;
            }
        }

        const json = ctx.json;
        const modelNode = ctx.modelNode;
        const hasChildNodes = glTFNode.children && glTFNode.children.length > 0;

        var localMatrix;

        if (glTFNode.matrix) {
            localMatrix = glTFNode.matrix;
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, math.mat4());
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.translation) {
            localMatrix = math.translationMat4v(glTFNode.translation);
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, localMatrix);
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.rotation) {
            localMatrix = math.quaternionToMat4(glTFNode.rotation);
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, localMatrix);
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.scale) {
            localMatrix = math.scalingMat4v(glTFNode.scale);
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, localMatrix);
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.mesh !== undefined) {

            var meshInfo = json.meshes[glTFNode.mesh];

            if (meshInfo) {

                var meshesInfo = meshInfo._mesh;
                var meshesInfoMesh;
                var mesh;
                var numMeshes = meshesInfo.length;

                if (!createEntity && numMeshes > 0 && !hasChildNodes) {

                    // Case 1: Not creating object, node has meshes, node has no child nodes

                    for (var i = 0, len = numMeshes; i < len; i++) {
                        meshesInfoMesh = meshesInfo[i];
                        let meshCfg = {
                            geometry: meshesInfoMesh.geometry,
                            matrix: matrix
                        };
                        utils.apply(ctx.modelNodeProps, meshCfg);
                        meshCfg.material = meshesInfoMesh.material;
                        mesh = new Mesh(modelNode, meshCfg);
                        parent.addChild(mesh, false); // Don't automatically inherit properties
                    }
                    return;
                }

                if (createEntity && numMeshes === 1 && !hasChildNodes) {

                    // Case 2: Creating object, node has one mesh, node has no child nodes

                    meshesInfoMesh = meshesInfo[0];
                    let meshCfg = {
                        geometry: meshesInfoMesh.geometry,
                        matrix: matrix
                    };
                    utils.apply(ctx.modelNodeProps, meshCfg);
                    meshCfg.material = meshesInfoMesh.material;
                    utils.apply(createEntity, meshCfg);
                    mesh = new Mesh(modelNode, meshCfg);
                    parent.addChild(mesh, false); // Don't automatically inherit properties
                    return;
                }

                if (createEntity && numMeshes > 0 && !hasChildNodes) {

                    // Case 3: Creating object, node has meshes, node has no child nodes

                    let nodeCfg = {
                        matrix: matrix
                    };
                    utils.apply(ctx.modelNodeProps, nodeCfg);
                    utils.apply(createEntity, nodeCfg);
                    let childNode = new Node(modelNode, nodeCfg);
                    parent.addChild(childNode, false);
                    for (let i = 0, len = numMeshes; i < len; i++) {
                        meshesInfoMesh = meshesInfo[i];
                        let meshCfg = {
                            geometry: meshesInfoMesh.geometry
                        };
                        utils.apply(ctx.modelNodeProps, meshCfg);
                        meshCfg.material = meshesInfoMesh.material;
                        utils.apply(createEntity, meshCfg);
                        meshCfg.id = null; // Avoid ID clash with parent Node
                        mesh = new Mesh(modelNode, meshCfg);
                        childNode.addChild(mesh, false);
                    }
                    return;
                }

                if (!createEntity && numMeshes > 0 && hasChildNodes) {

                    // Case 4: Not creating object, node has meshes, node has child nodes

                    let nodeCfg = {
                        matrix: matrix
                    };
                    utils.apply(ctx.modelNodeProps, nodeCfg);
                    let childNode = new Node(modelNode, nodeCfg);
                    parent.addChild(childNode, false);
                    for (let i = 0, len = numMeshes; i < len; i++) {
                        meshesInfoMesh = meshesInfo[i];
                        let meshCfg = {
                            geometry: meshesInfoMesh.geometry
                        };
                        utils.apply(nodeCfg, meshCfg);
                        meshCfg.id = null; // Avoid ID clash with parent Node
                        meshCfg.matrix = null; // Node has matrix
                        meshCfg.material = meshesInfoMesh.material;
                        mesh = new Mesh(modelNode, meshCfg);
                        childNode.addChild(mesh, false);
                    }
                    matrix = null;
                    parent = childNode;
                }

                if (createEntity && numMeshes === 0 && hasChildNodes) {

                    // Case 5: Creating explicit object, node has meshes OR node has child nodes

                    let nodeCfg = {
                        matrix: matrix
                    };
                    utils.apply(ctx.modelNodeProps, nodeCfg);
                    utils.apply(createEntity, nodeCfg);
                    createEntity.matrix = matrix;
                    let childNode = new Node(modelNode, nodeCfg);
                    parent.addChild(childNode, false); // Don't automatically inherit properties
                    matrix = null;
                    parent = childNode;
                }

                if (createEntity && numMeshes > 0 || hasChildNodes) {

                    // Case 6: Creating explicit object, node has meshes OR node has child nodes

                    let nodeCfg = {
                        matrix: matrix
                    };
                    utils.apply(ctx.modelNodeProps, nodeCfg);
                    if (createEntity) {
                        utils.apply(createEntity, nodeCfg);
                    }
                    let childNode = new Node(modelNode, nodeCfg);
                    parent.addChild(childNode, false); // Don't automatically inherit properties
                    for (let i = 0, len = numMeshes; i < len; i++) {
                        meshesInfoMesh = meshesInfo[i];
                        let meshCfg = {
                            geometry: meshesInfoMesh.geometry
                        };
                        utils.apply(ctx.modelProps, meshCfg);
                        meshCfg.material = meshesInfoMesh.material;
                        if (createEntity) {
                            utils.apply(createEntity, meshCfg);
                        }
                        meshCfg.id = null; // Avoid ID clash with parent Node
                        mesh = new Mesh(modelNode, meshCfg);
                        childNode.addChild(mesh, false); // Don't automatically inherit properties
                    }
                    matrix = null;
                    parent = childNode;
                }
            }
        }

        if (glTFNode.children) {
            var children = glTFNode.children;
            var childNodeInfo;
            var childNodeIdx;
            for (let i = 0, len = children.length; i < len; i++) {
                childNodeIdx = children[i];
                childNodeInfo = json.nodes[childNodeIdx];
                if (!childNodeInfo) {
                    error(ctx, "Node not found: " + i);
                    continue;
                }
                loadNode(ctx, childNodeInfo, matrix, parent);
            }
        }
    }

    function error(ctx, msg) {
        ctx.plugin.error(msg);
    }
})();

export {GLTFQualityLoader}
