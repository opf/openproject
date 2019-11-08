import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {MetallicMaterial} from "../../viewer/scene/materials/MetallicMaterial.js";
import {math} from "../../viewer/scene/math/math.js";
import {core} from "../../viewer/scene/core.js";


/**
 * @private
 */
class STLLoader {

    load(plugin, modelNode, src, options, ok, error) {
        options = options || {};
        var spinner = plugin.viewer.scene.canvas.spinner;
        spinner.processes++;
        load(plugin, modelNode, src, options, function () {
                spinner.processes--;
                core.scheduleTask(function () {
                    modelNode.fire("loaded", true, true);
                });
                if (ok) {
                    ok();
                }
            },
            function (msg) {
                spinner.processes--;
                plugin.error(msg);
                if (error) {
                    error(msg);
                }
                modelNode.fire("error", msg);
            });
    }
}

var load = (function () {
    function loadData(src, ok, error) {
        var request = new XMLHttpRequest();
        request.overrideMimeType("application/json");
        request.open('GET', src, true);
        request.responseType = 'arraybuffer';
        request.onreadystatechange = function () {
            if (request.readyState == 4 && request.status == "200") {
                ok(request.response, this);
            }
        };
        request.send(null);
    }

    return function (plugin, model, src, options, ok, error) {
        loadData(src, function (data) { // OK
                parse(data, plugin, model, options);
                ok();
            },
            error);
    };
})();

function parse(data, plugin, modelNode, options) {

    var entityCount = 0;

    function isBinary(data) {
        var reader = new DataView(data);
        var numFaces = reader.getUint32(80, true);
        var faceSize = (32 / 8 * 3) + ((32 / 8 * 3) * 3) + (16 / 8);
        var numExpectedBytes = 80 + (32 / 8) + (numFaces * faceSize);
        if (numExpectedBytes === reader.byteLength) {
            return true;
        }
        var solid = [115, 111, 108, 105, 100];
        for (var i = 0; i < 5; i++) {
            if (solid[i] !== reader.getUint8(i, false)) {
                return true;
            }
        }
        return false;
    }

    function parseBinary(data, plugin, modelNode, options) {
        var reader = new DataView(data);
        var faces = reader.getUint32(80, true);
        var r;
        var g;
        var b;
        var hasColors = false;
        var colors;
        var defaultR;
        var defaultG;
        var defaultB;
        var lastR = null;
        var lastG = null;
        var lastB = null;
        var newMesh = false;
        var alpha;
        for (var index = 0; index < 80 - 10; index++) {
            if ((reader.getUint32(index, false) == 0x434F4C4F /*COLO*/) &&
                (reader.getUint8(index + 4) == 0x52 /*'R'*/) &&
                (reader.getUint8(index + 5) == 0x3D /*'='*/)) {
                hasColors = true;
                colors = [];
                defaultR = reader.getUint8(index + 6) / 255;
                defaultG = reader.getUint8(index + 7) / 255;
                defaultB = reader.getUint8(index + 8) / 255;
                alpha = reader.getUint8(index + 9) / 255;
            }
        }
        var material = new MetallicMaterial(modelNode, { // Share material with all meshes
            roughness: 0.5
        });
        // var material = new PhongMaterial(modelNode, { // Share material with all meshes
        //     diffuse: [0.4, 0.4, 0.4],
        //     reflectivity: 1,
        //     specular: [0.5, 0.5, 1.0]
        // });
        var dataOffset = 84;
        var faceLength = 12 * 4 + 2;
        var positions = [];
        var normals = [];
        var splitMeshes = options.splitMeshes;
        for (var face = 0; face < faces; face++) {
            var start = dataOffset + face * faceLength;
            var normalX = reader.getFloat32(start, true);
            var normalY = reader.getFloat32(start + 4, true);
            var normalZ = reader.getFloat32(start + 8, true);
            if (hasColors) {
                var packedColor = reader.getUint16(start + 48, true);
                if ((packedColor & 0x8000) === 0) {
                    r = (packedColor & 0x1F) / 31;
                    g = ((packedColor >> 5) & 0x1F) / 31;
                    b = ((packedColor >> 10) & 0x1F) / 31;
                } else {
                    r = defaultR;
                    g = defaultG;
                    b = defaultB;
                }
                if (splitMeshes && r !== lastR || g !== lastG || b !== lastB) {
                    if (lastR !== null) {
                        newMesh = true;
                    }
                    lastR = r;
                    lastG = g;
                    lastB = b;
                }
            }
            for (var i = 1; i <= 3; i++) {
                var vertexstart = start + i * 12;
                positions.push(reader.getFloat32(vertexstart, true));
                positions.push(reader.getFloat32(vertexstart + 4, true));
                positions.push(reader.getFloat32(vertexstart + 8, true));
                normals.push(normalX, normalY, normalZ);
                if (hasColors) {
                    colors.push(r, g, b, 1); // TODO: handle alpha
                }
            }
            if (splitMeshes && newMesh) {
                addMesh(modelNode, positions, normals, colors, material, options);
                positions = [];
                normals = [];
                colors = colors ? [] : null;
                newMesh = false;
            }
        }
        if (positions.length > 0) {
            addMesh(modelNode, positions, normals, colors, material, options);
        }
    }

    function parseASCII(data, plugin, modelNode, options) {
        var faceRegex = /facet([\s\S]*?)endfacet/g;
        var faceCounter = 0;
        var floatRegex = /[\s]+([+-]?(?:\d+.\d+|\d+.|\d+|.\d+)(?:[eE][+-]?\d+)?)/.source;
        var vertexRegex = new RegExp('vertex' + floatRegex + floatRegex + floatRegex, 'g');
        var normalRegex = new RegExp('normal' + floatRegex + floatRegex + floatRegex, 'g');
        var positions = [];
        var normals = [];
        var colors = null;
        var normalx;
        var normaly;
        var normalz;
        var result;
        var verticesPerFace;
        var normalsPerFace;
        var text;
        while ((result = faceRegex.exec(data)) !== null) {
            verticesPerFace = 0;
            normalsPerFace = 0;
            text = result[0];
            while ((result = normalRegex.exec(text)) !== null) {
                normalx = parseFloat(result[1]);
                normaly = parseFloat(result[2]);
                normalz = parseFloat(result[3]);
                normalsPerFace++;
            }
            while ((result = vertexRegex.exec(text)) !== null) {
                positions.push(parseFloat(result[1]), parseFloat(result[2]), parseFloat(result[3]));
                normals.push(normalx, normaly, normalz);
                verticesPerFace++;
            }
            if (normalsPerFace !== 1) {
                plugin.error("Error in normal of face " + faceCounter);
            }
            if (verticesPerFace !== 3) {
                plugin.error("Error in positions of face " + faceCounter);
            }
            faceCounter++;
        }
        var material = new MetallicMaterial(modelNode, {
            roughness: 0.5
        });
        // var material = new PhongMaterial(modelNode, {
        //     diffuse: [0.4, 0.4, 0.4],
        //     reflectivity: 1,
        //     specular: [0.5, 0.5, 1.0]
        // });
        addMesh(modelNode, positions, normals, colors, material, options);
    }

    function addMesh(modelNode, positions, normals, colors, material, options) {

        var indices = new Int32Array(positions.length / 3);
        for (var ni = 0, len = indices.length; ni < len; ni++) {
            indices[ni] = ni;
        }

        normals = normals && normals.length > 0 ? normals : null;
        colors = colors && colors.length > 0 ? colors : null;

        if (options.smoothNormals) {
            math.faceToVertexNormals(positions, normals, options);
        }

        var geometry = new ReadableGeometry(modelNode, {
            primitive: "triangles",
            positions: positions,
            normals: normals,
            colors: colors,
            indices: indices
        });

        var mesh = new Mesh(modelNode, {
            id: modelNode.id + "#" + entityCount++,
            geometry: geometry,
            material: material,
            edges: options.edges
        });

        modelNode.addChild(mesh);
    }

    function ensureString(buffer) {
        if (typeof buffer !== 'string') {
            return decodeText(new Uint8Array(buffer));
        }
        return buffer;
    }

    function ensureBinary(buffer) {
        if (typeof buffer === 'string') {
            var arrayBuffer = new Uint8Array(buffer.length);
            for (var i = 0; i < buffer.length; i++) {
                arrayBuffer[i] = buffer.charCodeAt(i) & 0xff; // implicitly assumes little-endian
            }
            return arrayBuffer.buffer || arrayBuffer;
        } else {
            return buffer;
        }
    }

    function decodeText(array) {
        if (typeof TextDecoder !== 'undefined') {
            return new TextDecoder().decode(array);
        }
        var s = '';
        for (var i = 0, il = array.length; i < il; i++) {
            s += String.fromCharCode(array[i]); // Implicitly assumes little-endian.
        }
        return decodeURIComponent(escape(s));
    }

    var binData = ensureBinary(data);

    return isBinary(binData) ? parseBinary(binData, plugin, modelNode, options) : parseASCII(ensureString(data), plugin, modelNode, options);
}

export {STLLoader}