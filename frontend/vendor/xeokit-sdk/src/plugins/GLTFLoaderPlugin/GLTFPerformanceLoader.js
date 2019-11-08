import {math} from "../../viewer/scene/math/math.js";
import {utils} from "../../viewer/scene/utils.js";
import {core} from "../../viewer/scene/core.js";
import {buildEdgeIndices} from '../../viewer/scene/math/buildEdgeIndices.js';

/**
 * @private
 */
class GLTFPerformanceLoader {

    constructor(cfg) { // TODO: Loading options fallbacks on loader, eg. handleGLTFNode etc
        cfg = cfg || {};
    }

    load(plugin, performanceModel, src, options, ok, error) {
        options = options || {};
        loadGLTF(plugin, performanceModel, src, options, function () {
                core.scheduleTask(function () {
                    performanceModel.scene.fire("modelLoaded", performanceModel.id); // FIXME: Assumes listeners know order of these two events
                    performanceModel.fire("loaded", true, true);
                });
                if (ok) {
                    ok();
                }
            },
            function (msg) {
                plugin.error(msg);
                if (error) {
                    error(msg);
                }
                performanceModel.fire("error", msg);
            });
    }

    parse(plugin, performanceModel, gltf, options, ok, error) {
        options = options || {};
        parseGLTF(plugin, gltf, "", options, performanceModel, function () {
                performanceModel.scene.fire("modelLoaded", performanceModel.id); // FIXME: Assumes listeners know order of these two events
                performanceModel.fire("loaded", true, true);
                if (ok) {
                    ok();
                }
            },
            function (msg) {
                performanceModel.error(msg);
                performanceModel.fire("error", msg);
                if (error) {
                    error(msg);
                }
            });
    }
}

const INSTANCE_THRESHOLD = 1;

var loadGLTF = (function () {

    return function (plugin, performanceModel, src, options, ok, error) {
        var spinner = plugin.viewer.scene.canvas.spinner;
        spinner.processes++;
        plugin.dataSource.getGLTF(src, function (json) { // OK
                spinner.processes--;
                parseGLTF(plugin, json, src, options, performanceModel, ok, error);
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

    return function (plugin, json, src, options,  performanceModel, ok) {
        var ctx = {
            src: src,
            loadBuffer: options.loadBuffer,
            prioritizeGLTFNode: options.prioritizeGLTFNode,
            handleGLTFNode: options.handleGLTFNode,
            json: json,
            scene: performanceModel.scene,
            plugin: plugin,
            performanceModel: performanceModel,
            numObjects: 0,
            nodes: []
        };
        var spinner = plugin.viewer.scene.canvas.spinner;
        spinner.processes++;
        loadBuffers(ctx, function () {
            loadBufferViews(ctx);
            freeBuffers(ctx); // Don't need buffers once we've created views of them
            loadMaterials(ctx);
            spinner.processes--;
            loadDefaultScene(ctx, ok);
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

    function freeBuffers(ctx) {
        var buffers = ctx.json.buffers;
        if (buffers) {
            for (var i = 0, len = buffers.length; i < len; i++) {
                buffers[i]._buffer = null;
            }
        }
    }

    function loadMaterials(ctx) {
        var materialsInfo = ctx.json.materials;
        if (materialsInfo) {
            var materialInfo;
            var material;
            for (var i = 0, len = materialsInfo.length; i < len; i++) {
                materialInfo = materialsInfo[i];
                material = loadMaterialColorize(ctx, materialInfo);
                materialInfo._rgbaColor = material;
            }
        }
    }

    function loadMaterialColorize(ctx, materialInfo) { // Substitute RGBA for material, to use fast flat shading instead
        var json = ctx.json;
        var colorize = new Float32Array([1, 1, 1, 1]);
        var extensions = materialInfo.extensions;
        if (extensions) {
            var specularPBR = extensions["KHR_materials_pbrSpecularGlossiness"];
            if (specularPBR) {
                var diffuseFactor = specularPBR.diffuseFactor;
                if (diffuseFactor !== null && diffuseFactor !== undefined) {
                    colorize.set(diffuseFactor);
                }
            }
            var common = extensions["KHR_materials_common"];
            if (common) {
                var technique = common.technique;
                var values = common.values || {};
                var blinn = technique === "BLINN";
                var phong = technique === "PHONG";
                var lambert = technique === "LAMBERT";
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
        var metallicPBR = materialInfo.pbrMetallicRoughness;
        if (metallicPBR) {
            var baseColorFactor = metallicPBR.baseColorFactor;
            if (baseColorFactor) {
                colorize.set(baseColorFactor);
            }
        }
        return colorize;
    }

    function loadDefaultScene(ctx, ok) {
        var json = ctx.json;
        var scene = json.scene || 0;
        var defaultSceneInfo = json.scenes[scene];
        if (!defaultSceneInfo) {
            error(ctx, "glTF has no default scene");
            return;
        }
        preprocessScene(ctx, defaultSceneInfo);
        loadScene(ctx, defaultSceneInfo, ok);
    }

    function preprocessScene(ctx, sceneInfo) {
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
            countMeshUsage(ctx, i, glTFNode);
        }
        for (var i = 0, len = nodes.length; i < len; i++) {
            glTFNode = json.nodes[nodes[i]];
            if (glTFNode) {
                preprocessNode(ctx, i, glTFNode, null);
            }
        }
        ctx.nodes.sort(function (node1, node2) {
            return node1.priority - node2.priority;
        })
    }

    function preprocessNode(ctx, nodeIdx, glTFNode, matrix) {

        var priority = 0;

        if (ctx.prioritizeGLTFNode) {
            priority = ctx.prioritizeGLTFNode(ctx.performanceModel.id, glTFNode);
            if (priority === undefined || priority === null) {
                return;
            }
        }

        var json = ctx.json;
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
                matrix = math.mulMat4(matrix, localMatrix, math.mat4());
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.rotation) {
            localMatrix = math.quaternionToMat4(glTFNode.rotation);
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, math.mat4());
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.scale) {
            localMatrix = math.scalingMat4v(glTFNode.scale);
            if (matrix) {
                matrix = math.mulMat4(matrix, localMatrix, math.mat4());
            } else {
                matrix = localMatrix;
            }
        }

        if (glTFNode.mesh !== undefined) {
            const meshInfo = json.meshes[glTFNode.mesh];
            if (meshInfo) {
                glTFNode.worldMatrix = matrix ? matrix.slice() : math.identityMat4();
                glTFNode.priority = priority;
                ctx.nodes.push(glTFNode);
            }
        }

        if (glTFNode.children) {
            var children = glTFNode.children;
            var childNodeInfo;
            var childNodeIdx;
            for (var i = 0, len = children.length; i < len; i++) {
                childNodeIdx = children[i];
                childNodeInfo = json.nodes[childNodeIdx];
                if (!childNodeInfo) {
                    error(ctx, "Node not found: " + i);
                    continue;
                }
                preprocessNode(ctx, nodeIdx, childNodeInfo, matrix);
            }
        }
    }

    function loadScene(ctx, sceneInfo, ok) {
        const nodes = sceneInfo.nodes;
        if (!nodes) {
            return;
        }
        const json = ctx.json;
        var glTFNode;
        for (var i = 0, len = nodes.length; i < len; i++) {
            glTFNode = json.nodes[nodes[i]];
            if (!glTFNode) {
                error(ctx, "Node not found: " + i);
                continue;
            }
            countMeshUsage(ctx, glTFNode);
        }
        var priority = null;
        var tileId = null;
        var tileOpen = false;
        var nodei = 0;
        var spinnerShowing = true;
        ctx.plugin.viewer.scene.canvas.spinner.processes++;

        function nextPriority() {
            for (var i = nodei, len = ctx.nodes.length; i < len; i++) {
                const glTFNode = ctx.nodes[i];
                if (priority !== glTFNode.priority) {
                    if (tileId !== null) {
                        ctx.performanceModel.finalizeTile(tileId);
                        if (spinnerShowing) {
                            ctx.plugin.viewer.scene.canvas.spinner.processes--;
                            spinnerShowing = false;
                        }
                    }
                    nodei = i;
                    tileId = "" + glTFNode.priority;
                    ctx.performanceModel.createTile({
                        id: tileId
                    });
                    priority = glTFNode.priority;
                    tileOpen = true;
                    setTimeout(nextPriority, 100);
                    return;
                }
                loadNode(ctx, glTFNode, tileId);
            }
            if (tileOpen) {
                ctx.performanceModel.finalizeTile(tileId);
            }
            if (spinnerShowing) {
                ctx.plugin.viewer.scene.canvas.spinner.processes--;
                spinnerShowing = false;
            }
            ok();
        }
        nextPriority();
    }

    function countMeshUsage(ctx, glTFNode) {
        var json = ctx.json;
        var mesh = glTFNode.mesh;
        if (mesh !== undefined) {
            var meshInfo = json.meshes[glTFNode.mesh];
            if (meshInfo) {
                meshInfo.instances = meshInfo.instances ? meshInfo.instances + 1 : 1;
            }
        }
        if (glTFNode.children) {
            var children = glTFNode.children;
            var childNodeInfo;
            var childNodeIdx;
            for (var i = 0, len = children.length; i < len; i++) {
                childNodeIdx = children[i];
                childNodeInfo = json.nodes[childNodeIdx];
                if (!childNodeInfo) {
                    error(ctx, "Node not found: " + i);
                    continue;
                }
                countMeshUsage(ctx, childNodeInfo);
            }
        }
    }

    function loadNode(ctx, glTFNode, tileId) {

        var createEntity;

        if (ctx.handleGLTFNode) {
            var actions = {};
            if (!ctx.handleGLTFNode(ctx.performanceModel.id, glTFNode, actions)) {
                return;
            }
            if (actions.createEntity) {
                createEntity = actions.createEntity;
            }
        }

        var json = ctx.json;
        var performanceModel = ctx.performanceModel;

        if (glTFNode.mesh !== undefined) {

            const meshInfo = json.meshes[glTFNode.mesh];

            if (meshInfo) {

                const numPrimitives = meshInfo.primitives.length;

                if (numPrimitives > 0) {

                    const meshIds = [];

                    for (var i = 0; i < numPrimitives; i++) {
                        const meshCfg = {
                            id: performanceModel.id + "." + ctx.numObjects++,
                            tileId: tileId,
                            matrix: glTFNode.worldMatrix
                        };
                        const primitiveInfo = meshInfo.primitives[i];

                        const materialIndex = primitiveInfo.material;
                        var materialInfo;
                        if (materialIndex !== null && materialIndex !== undefined) {
                            materialInfo = json.materials[materialIndex];
                        }
                        if (materialInfo) {
                            meshCfg.color = materialInfo._rgbaColor;
                            meshCfg.opacity = materialInfo._rgbaColor[3];

                        } else {
                            meshCfg.color = new Float32Array([1.0, 1.0, 1.0]);
                            meshCfg.opacity = 1.0;
                        }

                        if (createEntity) {
                            if (createEntity.colorize) {
                                meshCfg.color = createEntity.colorize;
                            }
                            if (createEntity.opacity !== undefined && createEntity.opacity !== null) {
                                meshCfg.opacity = createEntity.opacity;
                            }
                        }

                        if (meshInfo.instances > INSTANCE_THRESHOLD) {

                            //------------------------------------------------------------------
                            // Instancing
                            //------------------------------------------------------------------

                            const geometryId = performanceModel.id + "." + glTFNode.mesh + "." + i;
                            if (!primitiveInfo.tilesGeometryIds) {
                                primitiveInfo.tilesGeometryIds = {};
                            }
                            var tileGeometryIds = primitiveInfo.tilesGeometryIds[tileId];
                            if (!tileGeometryIds) {
                                tileGeometryIds = primitiveInfo.tilesGeometryIds[tileId] = {};
                            }
                            if (tileGeometryIds[geometryId] === undefined) { // Ensures we only load each primitive mesh once
                                tileGeometryIds[geometryId] = geometryId;
                                const geometryCfg = {
                                    id: geometryId,
                                    tileId: tileId
                                };
                                loadPrimitiveGeometry(ctx, primitiveInfo, geometryCfg);
                                performanceModel.createGeometry(geometryCfg);
                            }

                            meshCfg.geometryId = geometryId;

                            performanceModel.createMesh(meshCfg);
                            meshIds.push(meshCfg.id);

                        } else {

                            //------------------------------------------------------------------
                            // Batching
                            //------------------------------------------------------------------

                            loadPrimitiveGeometry(ctx, primitiveInfo, meshCfg);

                            performanceModel.createMesh(meshCfg);
                            meshIds.push(meshCfg.id);
                        }
                    }

                    if (createEntity) {
                        performanceModel.createEntity(utils.apply(createEntity, {
                            tileId: tileId,
                            meshIds: meshIds
                        }));
                    } else {
                        performanceModel.createEntity({
                            tileId: tileId,
                            meshIds: meshIds
                        });
                    }
                }
            }
        }
    }

    function loadPrimitiveGeometry(ctx, primitiveInfo, geometryCfg) {
        var attributes = primitiveInfo.attributes;
        if (!attributes) {
            return;
        }
        geometryCfg.primitive = "triangles";
        var indicesIndex = primitiveInfo.indices;
        if (indicesIndex !== null && indicesIndex !== undefined) {
            const accessorInfo = ctx.json.accessors[indicesIndex];
            geometryCfg.indices = loadAccessorTypedArray(ctx, accessorInfo);
        }
        var positionsIndex = attributes.POSITION;
        if (positionsIndex !== null && positionsIndex !== undefined) {
            const accessorInfo = ctx.json.accessors[positionsIndex];
            geometryCfg.positions = loadAccessorTypedArray(ctx, accessorInfo);
            //  scalePositionsArray(geometryCfg.positions);
        }
        var normalsIndex = attributes.NORMAL;
        if (normalsIndex !== null && normalsIndex !== undefined) {
            const accessorInfo = ctx.json.accessors[normalsIndex];
            geometryCfg.normals = loadAccessorTypedArray(ctx, accessorInfo);
        }
        if (geometryCfg.indices) {
            geometryCfg.edgeIndices = buildEdgeIndices(geometryCfg.positions, geometryCfg.indices, null, 10); // Save PerformanceModel from building edges
        }
    }

    function loadAccessorTypedArray(ctx, accessorInfo) {
        var bufferViewInfo = ctx.json.bufferViews[accessorInfo.bufferView];
        var itemSize = WEBGL_TYPE_SIZES[accessorInfo.type];
        var TypedArray = WEBGL_COMPONENT_TYPES[accessorInfo.componentType];
        var elementBytes = TypedArray.BYTES_PER_ELEMENT; // For VEC3: itemSize is 3, elementBytes is 4, itemBytes is 12.
        var itemBytes = elementBytes * itemSize;
        if (accessorInfo.byteStride && accessorInfo.byteStride !== itemBytes) { // The buffer is not interleaved if the stride is the item size in bytes.
            error("interleaved buffer!"); // TODO
        } else {
            return new TypedArray(bufferViewInfo._buffer, accessorInfo.byteOffset || 0, accessorInfo.count * itemSize);
        }
    }

    function error(ctx, msg) {
        ctx.plugin.error(msg);
    }
})();

export {GLTFPerformanceLoader}
