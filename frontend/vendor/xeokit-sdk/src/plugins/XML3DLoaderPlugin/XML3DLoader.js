import {Node} from "../../viewer/scene/nodes/Node.js";
import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {MetallicMaterial} from "../../viewer/scene/materials/MetallicMaterial.js";
import {SpecularMaterial} from "../../viewer/scene/materials/SpecularMaterial.js";
import {LambertMaterial} from "../../viewer/scene/materials/LambertMaterial.js";
import {utils} from "../../viewer/scene/utils.js";
import {math} from "../../viewer/scene/math/math.js";

import {zipLib} from "./zipjs/zip.js";
import {zipExt} from "./zipjs/zip-ext.js";

const zip = zipLib.zip;
zipExt(zip);

const supportedSchemas = ["4.2"];

/**
 * @private
 */
class XML3DLoader {

    constructor(owner, cfg={}) {

        /**
         * Supported 3DXML schema versions
         * @property supportedSchemas
         * @type {string[]}
         */
        this.supportedSchemas = supportedSchemas;

        this._xrayOpacity = 0.7;
        this._src = null;
        this._options = cfg;

        /**
         * Default viewpoint, containing eye, look and up vectors.
         * Only defined if found in the 3DXML file.
         * @property viewpoint
         * @type {Number[]}
         */
        this.viewpoint = null;

        if (!cfg.workerScriptsPath) {
            this.error("Config expected: workerScriptsPath");
            return
        }
        zip.workerScriptsPath = cfg.workerScriptsPath;

        this.src = cfg.src;
        this.xrayOpacity = 0.7;
        this.displayEffect = cfg.displayEffect;
    }

    load(plugin, modelNode, src, options, ok, error) {

        modelNode._defaultMaterial = new MetallicMaterial(modelNode, {
            baseColor: [1, 1, 1],
            metallic: 0.6,
            roughness: 0.6
        });

        // Material shared by all Meshes that have "lines" Geometry
        // Overrides whatever material 3DXML would apply.
        modelNode._wireframeMaterial = new LambertMaterial(modelNode, {
            color: [0, 0, 0],
            lineWidth: 2
        });

        var spinner = modelNode.scene.canvas.spinner;
        spinner.processes++;

        load3DXML(plugin, modelNode, src, options, function () {
                spinner.processes--;
                if (ok) {
                    ok();
                }
                modelNode.fire("loaded", true, true);
            },
            function (msg) {
                spinner.processes--;
                modelNode.error(msg);
                if (error) {
                    error(msg);
                }
                /**
                 Fired whenever this XML3D fails to load the 3DXML file
                 specified by {@link XML3D/src}.
                 @event error
                 @param msg {String} Description of the error
                 */
                modelNode.fire("error", msg);
            },
            function (err) {
                console.log("Error, Will Robinson: " + err);
            });
    }
}

var load3DXML = (function () {
    return function (plugin, modelNode, src, options, ok, error) {
        loadZIP(src, function (zip) { // OK
                parse3DXML(plugin, zip, options, modelNode, ok, error);
            },
            error);
    };
})();

var parse3DXML = (function () {
    return function (plugin, zip, options, modelNode, ok) {
        var ctx = {
            plugin: plugin,
            zip: zip,
            edgeThreshold: 30, // Guess at degrees of normal deviation between adjacent tris below which we remove edge between them
            materialWorkflow: options.materialWorkflow,
            scene: modelNode.scene,
            modelNode: modelNode,
            info: {
                references: {}
            },
            materials: {}
        };
        modelNode.scene.loading++; // Disables (re)compilation


        // Now parse 3DXML

        parseDocument(ctx, function () {
            modelNode.scene.loading--; // Re-enables (re)compilation
            //console.log("3DXML parsed.");
            ok();
        });
    };

    function parseDocument(ctx, ok) {
        ctx.zip.getFile("Manifest.xml", function (xmlDoc, json) {
            var node = json;
            var children = node.children;
            for (var i = 0, len = children.length; i < len; i++) {
                var child = children[i];
                switch (child.type) {
                    case "Manifest":
                        parseManifest(ctx, child, ok);
                        break;
                }
            }
        });
    }

    function parseManifest(ctx, manifest, ok) {
        var children = manifest.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Root":
                    var rootFileSrc = child.children[0];
                    ctx.zip.getFile(rootFileSrc, function (xmlDoc, json) {
                        parseRoot(ctx, json, ok);
                    });
                    break;
            }
        }
    }

    function parseRoot(ctx, node, ok) {
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Model_3dxml":
                    parseModel(ctx, child, ok);
                    break;
            }
        }
    }

    function parseModel(ctx, node, ok) {
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Header":
                    parseHeader(ctx, child);
                    break;
                case "ProductStructure":
                    parseProductStructure(ctx, child, ok);
                    break;
                case "DefaultView":
                    parseDefaultView(ctx, child);
                    break;
            }
        }
    }

    function parseHeader(ctx, node) {
        var children = node.children;
        var metaData = {};
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "SchemaVersion":
                    metaData.schemaVersion = child.children[0];
                    if (!isSchemaVersionSupported(ctx, metaData.schemaVersion)) {
                        ctx.plugin.error("Schema version not supported: " + metaData.schemaVersion + " - supported versions are: " + ctx.modelNode.supportedSchemas.join(","));
                    } else {
                        //ctx.plugin.log("Parsing schema version: " + metaData.schemaVersion);
                    }
                    break;
                case "Title":
                    metaData.title = child.children[0];
                    break;
                case "Author":
                    metaData.author = child.children[0];
                    break;
                case "Created":
                    metaData.created = child.children[0];
                    break;
            }
        }
        ctx.modelNode.meta = metaData;
    }

    function isSchemaVersionSupported(ctx, schemaVersion) {
        for (var i = 0, len = supportedSchemas.length; i < len; i++) {
            if (schemaVersion === supportedSchemas[i]) {
                return true;
            }
        }
        return false;
    }

    function parseProductStructure(ctx, productStructureNode, ok) {

        parseReferenceReps(ctx, productStructureNode, function (referenceReps) {

            //----------------------------------------------------------------------------------
            // Parse out an intermediate scene DAG representation, that we can then
            // recursive descend through to build a xeokit Object hierarchy.
            //----------------------------------------------------------------------------------

            var children = productStructureNode.children;

            var reference3Ds = {};
            var instanceReps = {};
            var instance3Ds = {};

            var rootNode;
            var nodes = {};

            // Map all the elements

            for (var i = 0, len = children.length; i < len; i++) {
                var child = children[i];
                switch (child.type) {

                    case "Reference3D":
                        reference3Ds[child.id] = {
                            type: "Reference3D",
                            id: child.id,
                            name: child.name,
                            instance3Ds: {},
                            instanceReps: {}
                        };
                        break;

                    case "InstanceRep":
                        var isAggregatedBy;
                        var isInstanceOf;
                        var relativeMatrix;
                        for (var j = 0, lenj = child.children.length; j < lenj; j++) {
                            var child2 = child.children[j];
                            switch (child2.type) {
                                case "IsAggregatedBy":
                                    isAggregatedBy = child2.children[0];
                                    break;
                                case "IsInstanceOf":
                                    isInstanceOf = child2.children[0];
                                    break;
                            }
                        }
                        instanceReps[child.id] = {
                            type: "InstanceRep",
                            id: child.id,
                            isAggregatedBy: isAggregatedBy,
                            isInstanceOf: isInstanceOf,
                            referenceReps: {}
                        };
                        break;

                    case "Instance3D":
                        var isAggregatedBy;
                        var isInstanceOf;
                        var relativeMatrix;
                        for (var j = 0, lenj = child.children.length; j < lenj; j++) {
                            var child2 = child.children[j];
                            switch (child2.type) {
                                case "IsAggregatedBy":
                                    isAggregatedBy = child2.children[0];
                                    break;
                                case "IsInstanceOf":
                                    isInstanceOf = child2.children[0];
                                    break;
                                case "RelativeMatrix":
                                    relativeMatrix = child2.children[0];
                                    break;
                            }
                        }
                        instance3Ds[child.id] = {
                            type: "Instance3D",
                            id: child.id,
                            isAggregatedBy: isAggregatedBy,
                            isInstanceOf: isInstanceOf,
                            relativeMatrix: relativeMatrix,
                            reference3Ds: {}
                        };
                        break;
                }
            }

            // Connect Reference3Ds to the Instance3Ds they aggregate

            for (var id in instance3Ds) {
                var instance3D = instance3Ds[id];
                var reference3D = reference3Ds[instance3D.isAggregatedBy];
                if (reference3D) {
                    reference3D.instance3Ds[instance3D.id] = instance3D;
                } else {
                    alert("foo")
                }
            }

            // Connect Instance3Ds to the Reference3Ds they instantiate

            for (var id in instance3Ds) {
                var instance3D = instance3Ds[id];
                var reference3D = reference3Ds[instance3D.isInstanceOf];
                instance3D.reference3Ds[reference3D.id] = reference3D;
                reference3D.instance3D = instance3D;
            }

            // Connect InstanceReps to the ReferenceReps they instantiate

            for (var id in instanceReps) {
                var instanceRep = instanceReps[id];
                var referenceRep = referenceReps[instanceRep.isInstanceOf];
                if (referenceRep) {
                    instanceRep.referenceReps[referenceRep.id] = referenceRep;
                }
            }

            // Connect Reference3Ds to the InstanceReps they aggregate

            for (var id in instanceReps) {
                var instanceRep = instanceReps[id];
                var reference3D = reference3Ds[instanceRep.isAggregatedBy];
                if (reference3D) {
                    reference3D.instanceReps[instanceRep.id] = instanceRep;
                }
            }

            function parseReference3D(ctx, reference3D, group) {
                //ctx.plugin.log("parseReference3D( " + reference3D.id + " )");
                for (var id in reference3D.instance3Ds) {
                    parseInstance3D(ctx, reference3D.instance3Ds[id], group);
                }
                for (var id in reference3D.instanceReps) {
                    parseInstanceRep(ctx, reference3D.instanceReps[id], group);
                }
            }

            function parseInstance3D(ctx, instance3D, group) {
                //ctx.plugin.log("parseInstance3D( " + instance3D.id + " )");

                if (instance3D.relativeMatrix) {
                    var matrix = parseFloatArray(instance3D.relativeMatrix, 12);
                    var translate = [matrix[9], matrix[10], matrix[11]];
                    var mat3 = matrix.slice(0, 9); // Rotation matrix
                    var mat4 = math.mat3ToMat4(mat3, math.identityMat4()); // Convert rotation matrix to 4x4
                    var childGroup = new Node(ctx.modelNode, {
                        position: translate
                    });
                    if (group) {
                        group.addChild(childGroup, true);
                    } else {
                        ctx.modelNode.addChild(childGroup, true);
                    }
                    group = childGroup;
                    childGroup = new Node(ctx.modelNode, {
                        matrix: mat4
                    });
                    group.addChild(childGroup, true);
                    group = childGroup;
                } else {
                    var childGroup = new Node(ctx.modelNode, {});
                    if (group) {
                        group.addChild(childGroup, true);
                    } else {
                        ctx.modelNode.addChild(childGroup, true);
                    }
                    group = childGroup;
                }
                for (var id in instance3D.reference3Ds) {
                    parseReference3D(ctx, instance3D.reference3Ds[id], group);
                }
            }

            function parseInstanceRep(ctx, instanceRep, group) {
                //ctx.plugin.log("parseInstanceRep( " + instanceRep.id + " )");
                if (instanceRep.referenceReps) {
                    for (var id in instanceRep.referenceReps) {
                        var referenceRep = instanceRep.referenceReps[id];
                        for (var id2 in referenceRep) {
                            if (id2 === "id") {
                                continue; // HACK
                            }
                            var meshCfg = referenceRep[id2];
                            var lines = meshCfg.geometry.primitive === "lines";
                            var material = lines ? ctx.modelNode._wireframeMaterial : (meshCfg.materialId ? ctx.materials[meshCfg.materialId] : null);
                            var colorize = meshCfg.color;
                            var mesh = new Mesh(ctx.modelNode, {
                                geometry: meshCfg.geometry,
                                material: material || ctx.modelNode._defaultMaterial,
                                colorize: colorize,
                                backfaces: false
                            });
                            if (group) {
                                group.addChild(mesh, true);
                            } else {
                                ctx.modelNode.addChild(mesh, true);
                            }
                            mesh.colorize = colorize; // HACK: Mesh has inherited modelNode's colorize state, so we need to restore it (we'd better not modify colorize on the modelNode).
                        }
                    }
                }
            }

            // Find the root Reference3D

            for (var id in reference3Ds) {
                var reference3D = reference3Ds[id];
                if (!reference3D.instance3D) {
                    parseReference3D(ctx, reference3D, null); // HACK: Assuming that root has id == "1"
                    ok();
                    return;
                }
            }

            alert("No root Reference3D element found in this modelNode - can't load.");

            ok();
        });
    }

    function parseIntArray(str) {
        var parts = str.trim().split(" ");
        var result = new Int32Array(parts.length);
        for (var i = 0; i < parts.length; i++) {
            result[i] = parseInt(parts[i]);
        }
        return result;
    }

    function parseReferenceReps(ctx, node, ok) {
        var referenceReps = {};
        var children = node.children;
        var numToLoad = 0;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            if (child.type === "ReferenceRep") {
                numToLoad++;
            }
        }
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "ReferenceRep":
                    if (child.associatedFile) {
                        var src = stripURN(child.associatedFile);
                        (function () {
                            var childId = child.id;
                            ctx.zip.getFile(src, function (xmlDoc, json) {

                                    var materialIds = xmlDoc.getElementsByTagName("MaterialId");

                                    loadCATMaterialRefDocuments(ctx, materialIds, function () {

                                        // ctx.plugin.log("reference loaded: " + src);
                                        var referenceRep = {
                                            id: childId
                                        };
                                        parse3DRepDocument(ctx, json, referenceRep);
                                        referenceReps[childId] = referenceRep;
                                        if (--numToLoad === 0) {
                                            ok(referenceReps);
                                        }
                                    });
                                },
                                function (error) {
                                    // TODO:
                                });
                        })();
                    }
                    break;
            }
        }
    }


    function parseDefaultView(ctx, node) {
        // ctx.plugin.log("parseDefaultView");
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Viewpoint":
                    var children2 = child.children;
                    ctx.modelNode.viewpoint = {};
                    for (var i2 = 0, len2 = children2.length; i2 < len2; i2++) {
                        var child2 = children2[i];
                        switch (child2.type) {
                            case "Position":
                                ctx.modelNode.viewpoint.eye = parseFloatArray(child2.children[0], 3);
                                break;
                            case "Sight":
                                ctx.modelNode.viewpoint.look = parseFloatArray(child2.children[0], 3);
                                break;
                            case "Up":
                                ctx.modelNode.viewpoint.up = parseFloatArray(child2.children[0], 3);
                                break;
                        }
                    }
                    break;
                case "DefaultViewProperty":
                    break;
            }
        }
    }

    function parse3DRepDocument(ctx, node, result) {
        // ctx.plugin.log("parse3DRepDocument");
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "XMLRepresentation":
                    parseXMLRepresentation(ctx, child, result);
                    break;
            }
        }
    }

    function parseXMLRepresentation(ctx, node, result) {
        // ctx.plugin.log("parseXMLRepresentation");
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Root":
                    parse3DRepRoot(ctx, child, result);
                    break;
            }
        }
    }

    function parse3DRepRoot(ctx, node, result) {
        // ctx.plugin.log("parse3DRepRoot");
        switch (node["xsi:type"]) {
            case "BagRepType":
                break;
            case "PolygonalRepType":
                break;
        }
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Rep":
                    parse3DRepRep(ctx, child, result);
                    break;
            }
        }
    }

    function parse3DRepRep(ctx, node, result) {
        // ctx.plugin.log("parse3DRep");
        switch (node["xsi:type"]) {
            case "BagRepType":
                break;
            case "PolygonalRepType":
                break;
        }
        var meshesResult = {
            edgeThreshold: ctx.edgeThreshold || 30,
            compressGeometry: true
        };
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Rep":
                    parse3DRepRep(ctx, child, result);
                    break;
                case "Edges":

                    //----------------------------------------------------------------------
                    // NOTE: Ignoring edges because we auto-generate our own using xeokit
                    //----------------------------------------------------------------------

                    // meshesResult.primitive = "lines";
                    // parseEdges(ctx, child, meshesResult);
                    break;
                case "Faces":
                    meshesResult.primitive = "triangles";
                    parseFaces(ctx, child, meshesResult);
                    break;
                case "VertexBuffer":
                    parseVertexBuffer(ctx, child, meshesResult);
                    break;
                case "SurfaceAttributes":
                    parseSurfaceAttributes(ctx, child, meshesResult);
                    break;
            }
        }
        if (meshesResult.positions) {
            var geometry = new ReadableGeometry(ctx.modelNode, meshesResult);
            result[geometry.id] = {
                geometry: geometry,
                color: meshesResult.color || [1.0, 1.0, 1.0, 1.0],
                materialId: meshesResult.materialId
            };
        }
    }

    function parseEdges(ctx, node, result) {
        // ctx.plugin.log("parseEdges");
        result.positions = [];
        result.indices = [];
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Polyline":
                    parsePolyline(ctx, child, result);
                    break;
            }
        }
    }

    function parsePolyline(ctx, node, result) {
        //ctx.plugin.log("parsePolyline");
        var vertices = node.vertices;
        if (vertices) {
            var positions = parseFloatArray(vertices, 3);
            if (positions.length > 0) {
                var positionsOffset = result.positions.length / 3;
                for (var i = 0, len = positions.length; i < len; i++) {
                    result.positions.push(positions[i]);
                }
                for (var i = 0, len = (positions.length / 3) - 1; i < len; i++) {
                    result.indices.push(positionsOffset + i);
                    result.indices.push(positionsOffset + i + 1);
                }
            }
        }
    }

    function parseFaces(ctx, node, result) {
        // ctx.plugin.log("parseFaces");
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Face":
                    parseFace(ctx, child, result);
                    break;
            }
        }
    }

    function parseFace(ctx, node, result) {
        // ctx.plugin.log("parseFace");

        var strips = node.strips;
        if (strips) {

            // Triangle strips

            var arrays = parseIntArrays(strips);
            if (arrays.length > 0) {
                result.primitive = "triangles";
                var indices = [];
                for (var i = 0, len = arrays.length; i < len; i++) {
                    var array = convertTriangleStrip(arrays[i]);
                    for (var j = 0, lenj = array.length; j < lenj; j++) {
                        indices.push(array[j]);
                    }
                }
                result.indices = indices; // TODO
            }
        } else {

            // Triangle meshes

            var triangles = node.triangles;
            if (triangles) {
                result.primitive = "triangles";
                result.indices = parseIntArray(triangles);
            }
        }

        // Material

        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "SurfaceAttributes":
                    parseSurfaceAttributes(ctx, child, result);
                    break;
            }
        }
    }

    function convertTriangleStrip(indices) {
        var ccw = false;
        var indices2 = [];
        for (var i = 0, len = indices.length; i < len - 2; i++) {
            if (ccw) {
                if (i & 1) { //
                    indices2.push(indices[i]);
                    indices2.push(indices[i + 1]);
                    indices2.push(indices[i + 2]);
                } else {
                    indices2.push(indices[i]);
                    indices2.push(indices[i + 2]);
                    indices2.push(indices[i + 1]);
                }
            } else {
                if (i & 1) { //
                    indices2.push(indices[i]);
                    indices2.push(indices[i + 2]);
                    indices2.push(indices[i + 1]);
                } else {
                    indices2.push(indices[i]);
                    indices2.push(indices[i + 1]);
                    indices2.push(indices[i + 2]);
                }
            }
        }
        return indices2;
    }

    function parseVertexBuffer(ctx, node, result) {
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Positions":
                    result.positions = parseFloatArray(child.children[0], 3);
                    break;
                case "Normals":
                    result.normals = parseFloatArray(child.children[0], 3);
                    break;
                case "TextureCoordinates": // TODO: Support dimension and channel?
                    result.uv = parseFloatArray(child.children[0], 2);
                    break;
            }
        }
    }

    function parseIntArrays(str) {
        var coordStrings = str.split(",");
        var array = [];
        for (var i = 0, len = coordStrings.length; i < len; i++) {
            var coordStr = coordStrings[i].trim();
            if (coordStr.length > 0) {
                var elemStrings = coordStr.trim().split(" ");
                var arr = new Int16Array(elemStrings.length);
                var arrIdx = 0;
                for (var j = 0, lenj = elemStrings.length; j < lenj; j++) {
                    if (elemStrings[j] !== "") {
                        arr[arrIdx++] = parseInt(elemStrings[j]);
                    }
                }
                array.push(arr);
            }
        }
        return array;
    }

    function parseFloatArray(str, numElems) {
        str = str.split(",");
        var arr = new Float32Array(str.length * numElems);
        var arrIdx = 0;
        for (var i = 0, len = str.length; i < len; i++) {
            var value = str[i];
            value = value.split(" ");
            for (var j = 0, lenj = value.length; j < lenj; j++) {
                if (value[j] !== "") {
                    arr[arrIdx++] = parseFloat(value[j]);
                }
            }
        }
        return arr;
    }

    function parseIntArray(str) {
        str = str.trim().split(" ");
        var arr = new Int32Array(str.length);
        var arrIdx = 0;
        for (var i = 0, len = str.length; i < len; i++) {
            var value = str[i];
            arr[i] = parseInt(value);
        }
        return arr;
    }

    function parseSurfaceAttributes(ctx, node, result) {
        result.color = [1, 1, 1, 1];
        var children = node.children;
        for (var i = 0, len = children.length; i < len; i++) {
            var child = children[i];
            switch (child.type) {
                case "Color":
                    result.color[0] = child.red;
                    result.color[1] = child.green;
                    result.color[2] = child.blue;
                    result.color[3] = child.alpha;
                    break;
                case "MaterialApplication":
                    var children2 = child.children;
                    for (var j = 0, lenj = children2.length; j < lenj; j++) {
                        var child2 = children2[j];
                        switch (child2.type) {
                            case "MaterialId":
                                var materialId = getIDFromURI(child2.id);
                                var material = ctx.materials[materialId];
                                if (!material) {
                                    ctx.plugin.error("material  not found: " + materialId);
                                }
                                result.materialId = materialId;
                                break;
                        }
                    }
                    break;
            }
        }
    }
})();

//----------------------------------------------------------------------------------------------------
// Materials
//----------------------------------------------------------------------------------------------------

function loadCATMaterialRefDocuments(ctx, materialIds, ok) {
    var loaded = {};

    function load(i, done) {
        if (i >= materialIds.length) {
            ok();
            return;
        }
        var materialId = materialIds[i];
        var src = materialId.id;
        var colonIdx = src.lastIndexOf(":");
        if (colonIdx > 0) {
            src = src.substring(colonIdx + 1);
        }
        var hashIdx = src.lastIndexOf("#");
        if (hashIdx > 0) {
            src = src.substring(0, hashIdx);
        }
        if (!loaded[src]) {
            loadCATMaterialRefDocument(ctx, src, function () {
                loaded[src] = true;
                load(i + 1, done);
            });
        } else {
            load(i + 1, done);
        }
    }

    load(0, ok);
}

function

loadCATMaterialRefDocument(ctx, src, ok) { // Loads CATMaterialRef.3dxml
    ctx.zip.getFile(src, function (xmlDoc, json) {
        parseCATMaterialRefDocument(ctx, json, ok);
    });
}

function parseCATMaterialRefDocument(ctx, node, ok) { // Parse CATMaterialRef.3dxml
    // ctx.plugin.log("parseCATMaterialRefDocument");
    var children = node.children;
    var child;
    for (var i = 0, len = children.length; i < len; i++) {
        child = children[i];
        if (child.type === "Model_3dxml") {
            parseModel_3dxml(ctx, child, ok);
        }
    }
}

function parseModel_3dxml(ctx, node, ok) { // Parse CATMaterialRef.3dxml
    // ctx.plugin.log("parseModel_3dxml");
    var children = node.children;
    var child;
    for (var i = 0, len = children.length; i < len; i++) {
        child = children[i];
        if (child.type === "CATMaterialRef") {
            parseCATMaterialRef(ctx, child, ok);
        }
    }
}

function parseCATMaterialRef(ctx, node, ok) {

    // ctx.plugin.log("parseCATMaterialRef");

    var domainToReferenceMap = {};
    var materials = {};

    var result = {};
    var children = node.children;
    var child;
    var numToLoad = 0;

    for (var j = 0, lenj = children.length; j < lenj; j++) {
        var child2 = children[j];
        switch (child2.type) {
            case "MaterialDomainInstance":
                var isAggregatedBy;
                var isInstanceOf;
                for (var k = 0, lenk = child2.children.length; k < lenk; k++) {
                    var child3 = child2.children[k];
                    switch (child3.type) {
                        case "IsAggregatedBy":
                            isAggregatedBy = child3.children[0];
                            break;
                        case "IsInstanceOf":
                            isInstanceOf = child3.children[0];
                            break;
                    }
                }
                domainToReferenceMap[isInstanceOf] = isAggregatedBy;
                break;
        }
    }

    for (var j = 0, lenj = children.length; j < lenj; j++) {
        var child2 = children[j];
        switch (child2.type) {
            case "MaterialDomain":
                numToLoad++;
                break;
        }
    }

    // Now load them

    for (var j = 0, lenj = children.length; j < lenj; j++) {
        var child2 = children[j];
        switch (child2.type) {
            case "MaterialDomain":
                if (child2.associatedFile) {
                    (function () {
                        var childId = child2.id;
                        var src = stripURN(child2.associatedFile);
                        ctx.zip.getFile(src, function (xmlDoc, json) {
                                // ctx.plugin.log("Material def loaded: " + src);
                                ctx.materials[domainToReferenceMap[childId]] = parseMaterialDefDocument(ctx, json);

                                if (--numToLoad === 0) {
                                    //       console.log("All ReferenceReps loaded.");
                                    ok();
                                }
                            },
                            function (error) {
                                // TODO:
                            });
                    })();
                }
                break;
        }
    }
}

function parseMaterialDefDocument(ctx, node) {
    // ctx.plugin.log("parseMaterialDefDocumentOsm");
    var children = node.children;
    for (var i = 0, len = children.length; i < len; i++) {
        var child = children[i];
        switch (child.type) {
            case "Osm":
                return parseMaterialDefDocumentOsm(ctx, child);
                break;
        }
    }
}

function parseMaterialDefDocumentOsm(ctx, node) {
    var children = node.children;
    for (var i = 0, len = children.length; i < len; i++) {
        var child = children[i];
        switch (child.type) {
            case "RenderingRootFeature":
                //..
                break;
            case "Feature":

                if (child.Alias === "RenderingFeature") {
                    // Parse the coefficients, then parse the colors, scaling those by their coefficients.

                    var coeffs = {};
                    var materialCfg = {};
                    var children2 = child.children;
                    var j;
                    var lenj;
                    var child2;
                    for (j = 0, lenj = children2.length; j < lenj; j++) {
                        child2 = children2[j];
                        switch (child2.Name) {
                            case "AmbientCoef":
                                coeffs.ambient = parseFloat(child2.Value);
                                break;
                            case "DiffuseCoef":
                                coeffs.diffuse = parseFloat(child2.Value);
                                break;
                            case "EmissiveCoef":
                                coeffs.emissive = parseFloat(child2.Value);
                                break;
                            case "SpecularExponent":
                                coeffs.specular = parseFloat(child2.Value);
                                break;
                        }
                    }
                    for (j = 0, lenj = children2.length; j < lenj; j++) {
                        child2 = children2[j];
                        switch (child2.Name) {
                            case "AmbientColor":
                                materialCfg.ambient = parseRGB(child2.Value, coeffs.ambient);
                                break;
                            case "DiffuseColor":
                                materialCfg.diffuse = parseRGB(child2.Value, coeffs.diffuse);
                                break;
                            case "EmissiveColor":
                                materialCfg.emissive = parseRGB(child2.Value, coeffs.emissive);
                                break;
                            case "SpecularColor":
                                materialCfg.specular = parseRGB(child2.Value, coeffs.specular);
                                break;
                            case "Transparency":
                                var alpha = 1.0 - parseFloat(child2.Value); // GOTCHA: Degree of transparency, not degree of opacity
                                if (alpha < 1.0) {
                                    materialCfg.alpha = alpha;
                                    materialCfg.alphaMode = "blend";
                                }
                                break;
                        }
                    }

                    var material;

                    switch (ctx.materialWorkflow) {
                        case "MetallicMaterial":
                            material = new MetallicMaterial(ctx.modelNode, {
                                baseColor: materialCfg.diffuse,
                                metallic: 0.7,
                                roughness: 0.5,
                                emissive: materialCfg.emissive,
                                alpha: materialCfg.alpha,
                                alphaMode: materialCfg.alphaMode
                            });
                            break;

                        case "SpecularMaterial":
                            material = new SpecularMaterial(ctx.modelNode, {
                                diffuse: materialCfg.diffuse,
                                specular: materialCfg.specular,
                                glossiness: 0.5,
                                emissive: materialCfg.emissive,
                                alpha: materialCfg.alpha,
                                alphaMode: materialCfg.alphaMode
                            });
                            break;

                        default:
                            material = new PhongMaterial(ctx.modelNode, {
                                reflectivity: 0.5,
                                ambient: materialCfg.ambient,
                                diffuse: materialCfg.diffuse,
                                specular: materialCfg.specular,
                                // shininess: node.shine,
                                emissive: materialCfg.emissive,
                                alphaMode: materialCfg.alphaMode,
                                alpha: node.alpha
                            });
                    }
                    return material;
                }
                break;
        }
    }
}

function parseRGB(str, coeff) {
    coeff = (coeff !== undefined) ? coeff : 0.5;
    var openBracketIndex = str.indexOf("[");
    var closeBracketIndex = str.indexOf("]");
    str = str.substring(openBracketIndex + 1, closeBracketIndex - openBracketIndex);
    str = str.split(",");
    var arr = new Float32Array(str.length);
    var arrIdx = 0;
    for (var i = 0, len = str.length; i < len; i++) {
        var value = str[i];
        value = value.trim().split(" ");
        for (var j = 0, lenj = value.length; j < lenj; j++) {
            if (value[j] !== "") {
                arr[arrIdx++] = parseFloat(value[j]) * coeff;
            }
        }
    }
    return arr;
}


//----------------------------------------------------------------------------------------------------

/**
 * Wraps zip.js to provide an in-memory ZIP archive representing the 3DXML file bundle.
 *
 * Allows us to pluck each file from it as XML and JSON.
 *
 * @constructor
 */
var ZIP = function () {

    var reader;
    var files = {};

    /**
     Loads this ZIP

     @param src
     @param ok
     @param error
     */
    this.load = function (src, ok, error) {
        var self = this;
        zip.createReader(new zip.HttpReader(src), function (reader) {
            reader.getEntries(function (entries) {
                if (entries.length > 0) {
                    for (var i = 0, len = entries.length; i < len; i++) {
                        var entry = entries[i];
                        files[entry.filename] = entry;
                    }
                }
                ok();
            });
        }, error);
    };

    /**
     Gets a file as XML and JSON from this ZIP
     @param src
     @param ok
     @param error
     */
    this.getFile = function (src, ok, error) {
        var entry = files[src];
        if (!entry) {
            var errMsg = "ZIP entry not found: " + src;
            console.error(errMsg);
            if (error) {
                error(errMsg);
            }
            return;
        }
        entry.getData(new zip.TextWriter(), function (text) {

            // Parse to XML
            var parser = new DOMParser();
            var xmlDoc = parser.parseFromString(text, "text/xml");

            // Parse to JSON
            var json = xmlToJSON(xmlDoc, {});

            ok(xmlDoc, json);
        });
    };

    function xmlToJSON(node, attributeRenamer) {
        if (node.nodeType === node.TEXT_NODE) {
            var v = node.nodeValue;
            if (v.match(/^\s+$/) === null) {
                return v;
            }
        } else if (node.nodeType === node.ELEMENT_NODE ||
            node.nodeType === node.DOCUMENT_NODE) {
            var json = {type: node.nodeName, children: []};
            if (node.nodeType === node.ELEMENT_NODE) {
                for (var j = 0; j < node.attributes.length; j++) {
                    var attribute = node.attributes[j];
                    var nm = attributeRenamer[attribute.nodeName] || attribute.nodeName;
                    json[nm] = attribute.nodeValue;
                }
            }
            for (var i = 0; i < node.childNodes.length; i++) {
                var item = node.childNodes[i];
                var j = xmlToJSON(item, attributeRenamer);
                if (j) json.children.push(j);
            }
            return json;
        }
    }

    /**
     Disposes of this ZIP
     */
    this.destroy = function () {
        reader.close(function () {
            // onclose callback
        });
    };
};

function

loadZIP(src, ok, err) {
    var zip = new ZIP();
    zip.load(src, function () {
        ok(zip);
    }, function (errMsg) {
        err("Error loading ZIP archive: " + errMsg);
    })
}

function

stripURN(str) {
    var subStr = "urn:3DXML:";
    return (str.indexOf(subStr) === 0) ? str.substring(subStr.length) : str;
}


function

getIDFromURI(str) {
    var hashIdx = str.lastIndexOf("#");
    return hashIdx != -1 ? str.substring(hashIdx + 1) : str;
}

export {XML3DLoader};
