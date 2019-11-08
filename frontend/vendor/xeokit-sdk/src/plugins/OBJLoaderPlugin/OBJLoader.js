import {Mesh} from "../../viewer/scene/mesh/Mesh.js";
import {ReadableGeometry} from "../../viewer/scene/geometry/ReadableGeometry.js";
import {PhongMaterial} from "../../viewer/scene/materials/PhongMaterial.js";
import {Texture} from "../../viewer/scene/materials/Texture.js";
import {core} from "../../viewer/scene/core.js";

/**
 * @private
 */
class OBJLoader  {

    /**
     * Loads OBJ and MTL from file(s) into a {@link Node}.
     *
     * @static
     * @param {Node} modelNode Node to load into.
     * @param {String} src Path to OBJ file.
     * @param {Object} params Loading options.
     */
    load(modelNode, src, params = {}) {

        var spinner = modelNode.scene.canvas.spinner;
        spinner.processes++;

        loadOBJ(modelNode, src, function (state) {
            loadMTLs(modelNode, state, function () {

                createMeshes(modelNode, state);

                spinner.processes--;

                core.scheduleTask(function () {
                    modelNode.fire("loaded", true);
                });
            });
        });
    }

    /**
     * Parses OBJ and MTL text strings into a {@link Node}.
     *
     * @static
     * @param {Node} modelNode Node to load into.
     * @param {String} objText OBJ text string.
     * @param {String} [mtlText] MTL text string.
     * @param {String} [basePath] Base path for external resources.
     */
    parse(modelNode, objText, mtlText, basePath) {
        if (!objText) {
            this.warn("load() param expected: objText");
            return;
        }
        var state = parseOBJ(modelNode, objText, null);
        if (mtlText) {
            parseMTL(modelNode, mtlText, basePath);
        }
        createMeshes(modelNode, state);
        modelNode.src = null;
        modelNode.fire("loaded", true, true);
    }
}

//--------------------------------------------------------------------------------------------
// Loads OBJ
//
// Parses OBJ into an intermediate state object. The object will contain geometry data
// and material IDs from which meshes can be created later. The object will also
// contain a list of filenames of the MTL files referenced by the OBJ, is any.
//
// Originally based on the THREE.js OBJ and MTL loaders:
//
// https://github.com/mrdoob/three.js/blob/dev/examples/js/loaders/OBJLoader.js
// https://github.com/mrdoob/three.js/blob/dev/examples/js/loaders/MTLLoader.js
//--------------------------------------------------------------------------------------------

var loadOBJ = function (modelNode, url, ok) {
    loadFile(url, function (text) {
            var state = parseOBJ(modelNode, text, url);
            ok(state);
        },
        function (error) {
            modelNode.error(error);
        });
};

var parseOBJ = (function () {

    const regexp = {
        // v float float float
        vertex_pattern: /^v\s+([\d|\.|\+|\-|e|E]+)\s+([\d|\.|\+|\-|e|E]+)\s+([\d|\.|\+|\-|e|E]+)/,
        // vn float float float
        normal_pattern: /^vn\s+([\d|\.|\+|\-|e|E]+)\s+([\d|\.|\+|\-|e|E]+)\s+([\d|\.|\+|\-|e|E]+)/,
        // vt float float
        uv_pattern: /^vt\s+([\d|\.|\+|\-|e|E]+)\s+([\d|\.|\+|\-|e|E]+)/,
        // f vertex vertex vertex
        face_vertex: /^f\s+(-?\d+)\s+(-?\d+)\s+(-?\d+)(?:\s+(-?\d+))?/,
        // f vertex/uv vertex/uv vertex/uv
        face_vertex_uv: /^f\s+(-?\d+)\/(-?\d+)\s+(-?\d+)\/(-?\d+)\s+(-?\d+)\/(-?\d+)(?:\s+(-?\d+)\/(-?\d+))?/,
        // f vertex/uv/normal vertex/uv/normal vertex/uv/normal
        face_vertex_uv_normal: /^f\s+(-?\d+)\/(-?\d+)\/(-?\d+)\s+(-?\d+)\/(-?\d+)\/(-?\d+)\s+(-?\d+)\/(-?\d+)\/(-?\d+)(?:\s+(-?\d+)\/(-?\d+)\/(-?\d+))?/,
        // f vertex//normal vertex//normal vertex//normal
        face_vertex_normal: /^f\s+(-?\d+)\/\/(-?\d+)\s+(-?\d+)\/\/(-?\d+)\s+(-?\d+)\/\/(-?\d+)(?:\s+(-?\d+)\/\/(-?\d+))?/,
        // o object_name | g group_name
        object_pattern: /^[og]\s*(.+)?/,
        // s boolean
        smoothing_pattern: /^s\s+(\d+|on|off)/,
        // mtllib file_reference
        material_library_pattern: /^mtllib /,
        // usemtl material_name
        material_use_pattern: /^usemtl /
    };

    return function (modelNode, text, url) {

        url = url || "";

        var state = {
            src: url,
            basePath: getBasePath(url),
            objects: [],
            object: {},
            positions: [],
            normals: [],
            uv: [],
            materialLibraries: {}
        };

        startObject(state, "", false);

        // Parts of this parser logic are derived from the THREE.js OBJ loader:
        // https://github.com/mrdoob/three.js/blob/dev/examples/js/loaders/OBJLoader.js

        if (text.indexOf('\r\n') !== -1) {
            // This is faster than String.split with regex that splits on both
            text = text.replace('\r\n', '\n');
        }

        var lines = text.split('\n');
        var line = '', lineFirstChar = '', lineSecondChar = '';
        var lineLength = 0;
        var result = [];

        // Faster to just trim left side of the line. Use if available.
        var trimLeft = (typeof ''.trimLeft === 'function');

        for (var i = 0, l = lines.length; i < l; i++) {

            line = lines[i];

            line = trimLeft ? line.trimLeft() : line.trim();

            lineLength = line.length;

            if (lineLength === 0) {
                continue;
            }

            lineFirstChar = line.charAt(0);

            if (lineFirstChar === '#') {
                continue;
            }

            if (lineFirstChar === 'v') {

                lineSecondChar = line.charAt(1);

                if (lineSecondChar === ' ' && (result = regexp.vertex_pattern.exec(line)) !== null) {

                    // 0                  1      2      3
                    // ['v 1.0 2.0 3.0', '1.0', '2.0', '3.0']

                    state.positions.push(
                        parseFloat(result[1]),
                        parseFloat(result[2]),
                        parseFloat(result[3])
                    );

                } else if (lineSecondChar === 'n' && (result = regexp.normal_pattern.exec(line)) !== null) {

                    // 0                   1      2      3
                    // ['vn 1.0 2.0 3.0', '1.0', '2.0', '3.0']

                    state.normals.push(
                        parseFloat(result[1]),
                        parseFloat(result[2]),
                        parseFloat(result[3])
                    );

                } else if (lineSecondChar === 't' && (result = regexp.uv_pattern.exec(line)) !== null) {

                    // 0               1      2
                    // ['vt 0.1 0.2', '0.1', '0.2']

                    state.uv.push(
                        parseFloat(result[1]),
                        parseFloat(result[2])
                    );

                } else {

                    modelNode.error('Unexpected vertex/normal/uv line: \'' + line + '\'');
                    return;
                }

            } else if (lineFirstChar === 'f') {

                if ((result = regexp.face_vertex_uv_normal.exec(line)) !== null) {

                    // f vertex/uv/normal vertex/uv/normal vertex/uv/normal
                    // 0                        1    2    3    4    5    6    7    8    9   10         11         12
                    // ['f 1/1/1 2/2/2 3/3/3', '1', '1', '1', '2', '2', '2', '3', '3', '3', undefined, undefined, undefined]

                    addFace(state,
                        result[1], result[4], result[7], result[10],
                        result[2], result[5], result[8], result[11],
                        result[3], result[6], result[9], result[12]
                    );

                } else if ((result = regexp.face_vertex_uv.exec(line)) !== null) {

                    // f vertex/uv vertex/uv vertex/uv
                    // 0                  1    2    3    4    5    6   7          8
                    // ['f 1/1 2/2 3/3', '1', '1', '2', '2', '3', '3', undefined, undefined]

                    addFace(state,
                        result[1], result[3], result[5], result[7],
                        result[2], result[4], result[6], result[8]
                    );

                } else if ((result = regexp.face_vertex_normal.exec(line)) !== null) {

                    // f vertex//normal vertex//normal vertex//normal
                    // 0                     1    2    3    4    5    6   7          8
                    // ['f 1//1 2//2 3//3', '1', '1', '2', '2', '3', '3', undefined, undefined]

                    addFace(state,
                        result[1], result[3], result[5], result[7],
                        undefined, undefined, undefined, undefined,
                        result[2], result[4], result[6], result[8]
                    );

                } else if ((result = regexp.face_vertex.exec(line)) !== null) {

                    // f vertex vertex vertex
                    // 0            1    2    3   4
                    // ['f 1 2 3', '1', '2', '3', undefined]

                    addFace(state, result[1], result[2], result[3], result[4]);
                } else {
                    modelNode.error('Unexpected face line: \'' + line + '\'');
                    return;
                }

            } else if (lineFirstChar === 'l') {

                var lineParts = line.substring(1).trim().split(' ');
                var lineVertices = [], lineUVs = [];

                if (line.indexOf('/') === -1) {

                    lineVertices = lineParts;

                } else {
                    for (var li = 0, llen = lineParts.length; li < llen; li++) {
                        var parts = lineParts[li].split('/');
                        if (parts[0] !== '') {
                            lineVertices.push(parts[0]);
                        }
                        if (parts[1] !== '') {
                            lineUVs.push(parts[1]);
                        }
                    }
                }
                addLineGeometry(state, lineVertices, lineUVs);

            } else if ((result = regexp.object_pattern.exec(line)) !== null) {

                // o object_name
                // or
                // g group_name

                var id = result[0].substr(1).trim();
                startObject(state, id, true);

            } else if (regexp.material_use_pattern.test(line)) {

                // material

                var id = line.substring(7).trim();
                state.object.material.id = id;

            } else if (regexp.material_library_pattern.test(line)) {

                // mtl file

                state.materialLibraries[line.substring(7).trim()] = true;

            } else if ((result = regexp.smoothing_pattern.exec(line)) !== null) {

                // smooth shading

                var value = result[1].trim().toLowerCase();
                state.object.material.smooth = (value === '1' || value === 'on');

            } else {

                // Handle null terminated files without exception
                if (line === '\0') {
                    continue;
                }

                modelNode.error('Unexpected line: \'' + line + '\'');
                return;
            }
        }

        return state;
    };

    function getBasePath(src) {
        var n = src.lastIndexOf('/');
        return (n === -1) ? src : src.substring(0, n + 1);
    }

    function startObject(state, id, fromDeclaration) {
        if (state.object && state.object.fromDeclaration === false) {
            state.object.id = id;
            state.object.fromDeclaration = (fromDeclaration !== false);
            return;
        }
        state.object = {
            id: id || '',
            geometry: {
                positions: [],
                normals: [],
                uv: []
            },
            material: {
                id: '',
                smooth: true
            },
            fromDeclaration: (fromDeclaration !== false)
        };
        state.objects.push(state.object);
    }

    function parseVertexIndex(value, len) {
        var index = parseInt(value, 10);
        return (index >= 0 ? index - 1 : index + len / 3) * 3;
    }

    function parseNormalIndex(value, len) {
        var index = parseInt(value, 10);
        return (index >= 0 ? index - 1 : index + len / 3) * 3;
    }

    function parseUVIndex(value, len) {
        var index = parseInt(value, 10);
        return (index >= 0 ? index - 1 : index + len / 2) * 2;
    }

    function addVertex(state, a, b, c) {
        var src = state.positions;
        var dst = state.object.geometry.positions;
        dst.push(src[a + 0]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
        dst.push(src[b + 0]);
        dst.push(src[b + 1]);
        dst.push(src[b + 2]);
        dst.push(src[c + 0]);
        dst.push(src[c + 1]);
        dst.push(src[c + 2]);
    }

    function addVertexLine(state, a) {
        var src = state.positions;
        var dst = state.object.geometry.positions;
        dst.push(src[a + 0]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
    }

    function addNormal(state, a, b, c) {
        var src = state.normals;
        var dst = state.object.geometry.normals;
        dst.push(src[a + 0]);
        dst.push(src[a + 1]);
        dst.push(src[a + 2]);
        dst.push(src[b + 0]);
        dst.push(src[b + 1]);
        dst.push(src[b + 2]);
        dst.push(src[c + 0]);
        dst.push(src[c + 1]);
        dst.push(src[c + 2]);
    }

    function addUV(state, a, b, c) {
        var src = state.uv;
        var dst = state.object.geometry.uv;
        dst.push(src[a + 0]);
        dst.push(src[a + 1]);
        dst.push(src[b + 0]);
        dst.push(src[b + 1]);
        dst.push(src[c + 0]);
        dst.push(src[c + 1]);
    }

    function addUVLine(state, a) {
        var src = state.uv;
        var dst = state.object.geometry.uv;
        dst.push(src[a + 0]);
        dst.push(src[a + 1]);
    }

    function addFace(state, a, b, c, d, ua, ub, uc, ud, na, nb, nc, nd) {
        var vLen = state.positions.length;
        var ia = parseVertexIndex(a, vLen);
        var ib = parseVertexIndex(b, vLen);
        var ic = parseVertexIndex(c, vLen);
        var id;
        if (d === undefined) {
            addVertex(state, ia, ib, ic);

        } else {
            id = parseVertexIndex(d, vLen);
            addVertex(state, ia, ib, id);
            addVertex(state, ib, ic, id);
        }

        if (ua !== undefined) {

            var uvLen = state.uv.length;

            ia = parseUVIndex(ua, uvLen);
            ib = parseUVIndex(ub, uvLen);
            ic = parseUVIndex(uc, uvLen);

            if (d === undefined) {
                addUV(state, ia, ib, ic);

            } else {
                id = parseUVIndex(ud, uvLen);
                addUV(state, ia, ib, id);
                addUV(state, ib, ic, id);
            }
        }

        if (na !== undefined) {

            // Normals are many times the same. If so, skip function call and parseInt.

            var nLen = state.normals.length;

            ia = parseNormalIndex(na, nLen);
            ib = na === nb ? ia : parseNormalIndex(nb, nLen);
            ic = na === nc ? ia : parseNormalIndex(nc, nLen);

            if (d === undefined) {
                addNormal(state, ia, ib, ic);

            } else {

                id = parseNormalIndex(nd, nLen);
                addNormal(state, ia, ib, id);
                addNormal(state, ib, ic, id);
            }
        }
    }

    function addLineGeometry(state, positions, uv) {

        state.object.geometry.type = 'Line';

        var vLen = state.positions.length;
        var uvLen = state.uv.length;

        for (var vi = 0, l = positions.length; vi < l; vi++) {
            addVertexLine(state, parseVertexIndex(positions[vi], vLen));
        }

        for (var uvi = 0, uvl = uv.length; uvi < uvl; uvi++) {
            addUVLine(state, parseUVIndex(uv[uvi], uvLen));
        }
    }
})();

//--------------------------------------------------------------------------------------------
// Loads MTL files listed in parsed state
//--------------------------------------------------------------------------------------------

function loadMTLs(modelNode, state, ok) {
    var basePath = state.basePath;
    var srcList = Object.keys(state.materialLibraries);
    var numToLoad = srcList.length;
    for (var i = 0, len = numToLoad; i < len; i++) {
        loadMTL(modelNode, basePath, basePath + srcList[i], function () {
            if (--numToLoad === 0) {
                ok();
            }
        });
    }
}

//--------------------------------------------------------------------------------------------
// Loads an MTL file
//--------------------------------------------------------------------------------------------

var loadMTL = function (modelNode, basePath, src, ok) {
    loadFile(src, function (text) {
            parseMTL(modelNode, text, basePath);
            ok();
        },
        function (error) {
            modelNode.error(error);
            ok();
        });
};

var parseMTL = (function () {

    var delimiter_pattern = /\s+/;

    return function (modelNode, mtlText, basePath) {

        var lines = mtlText.split('\n');
        var materialCfg = {
            id: "Default"
        };
        var needCreate = false;
        var line;
        var pos;
        var key;
        var value;
        var alpha;

        basePath = basePath || "";

        for (var i = 0; i < lines.length; i++) {

            line = lines[i].trim();

            if (line.length === 0 || line.charAt(0) === '#') { // Blank line or comment ignore
                continue;
            }

            pos = line.indexOf(' ');

            key = (pos >= 0) ? line.substring(0, pos) : line;
            key = key.toLowerCase();

            value = (pos >= 0) ? line.substring(pos + 1) : '';
            value = value.trim();

            switch (key.toLowerCase()) {

                case "newmtl": // New material
                    //if (needCreate) {
                    createMaterial(modelNode, materialCfg);
                    //}
                    materialCfg = {
                        id: value
                    };
                    needCreate = true;
                    break;

                case 'ka':
                    materialCfg.ambient = parseRGB(value);
                    break;

                case 'kd':
                    materialCfg.diffuse = parseRGB(value);
                    break;

                case 'ks':
                    materialCfg.specular = parseRGB(value);
                    break;

                case 'map_kd':
                    if (!materialCfg.diffuseMap) {
                        materialCfg.diffuseMap = createTexture(modelNode, basePath, value, "sRGB");
                    }
                    break;

                case 'map_ks':
                    if (!materialCfg.specularMap) {
                        materialCfg.specularMap = createTexture(modelNode, basePath, value, "linear");
                    }
                    break;

                case 'map_bump':
                case 'bump':
                    if (!materialCfg.normalMap) {
                        materialCfg.normalMap = createTexture(modelNode, basePath, value);
                    }
                    break;

                case 'ns':
                    materialCfg.shininess = parseFloat(value);
                    break;

                case 'd':
                    alpha = parseFloat(value);
                    if (alpha < 1) {
                        materialCfg.alpha = alpha;
                        materialCfg.alphaMode = "blend";
                    }
                    break;

                case 'tr':
                    alpha = parseFloat(value);
                    if (alpha > 0) {
                        materialCfg.alpha = 1 - alpha;
                        materialCfg.alphaMode = "blend";
                    }
                    break;

                default:
                // modelNode.error("Unrecognized token: " + key);
            }
        }

        if (needCreate) {
            createMaterial(modelNode, materialCfg);
        }
    };

    function createTexture(modelNode, basePath, value, encoding) {
        var textureCfg = {};
        var items = value.split(/\s+/);
        var pos = items.indexOf('-bm');
        if (pos >= 0) {
            //matParams.bumpScale = parseFloat(items[pos + 1]);
            items.splice(pos, 2);
        }
        pos = items.indexOf('-s');
        if (pos >= 0) {
            textureCfg.scale = [parseFloat(items[pos + 1]), parseFloat(items[pos + 2])];
            items.splice(pos, 4); // we expect 3 parameters here!
        }
        pos = items.indexOf('-o');
        if (pos >= 0) {
            textureCfg.translate = [parseFloat(items[pos + 1]), parseFloat(items[pos + 2])];
            items.splice(pos, 4); // we expect 3 parameters here!
        }
        textureCfg.src = basePath + items.join(' ').trim();
        textureCfg.flipY = true;
        textureCfg.encoding = encoding || "linear";
        //textureCfg.wrapS = self.wrap;
        //textureCfg.wrapT = self.wrap;
        var texture = new Texture(modelNode, textureCfg);
        return texture.id;
    }

    function createMaterial(modelNode, materialCfg) {
       new PhongMaterial(modelNode, materialCfg);
    }

    function parseRGB(value) {
        var ss = value.split(delimiter_pattern, 3);
        return [parseFloat(ss[0]), parseFloat(ss[1]), parseFloat(ss[2])];
    }

})();
//--------------------------------------------------------------------------------------------
// Creates meshes from parsed state
//--------------------------------------------------------------------------------------------

var createMeshes = (function () {

    return function (modelNode, state) {

        for (var j = 0, k = state.objects.length; j < k; j++) {

            var object = state.objects[j];
            var geometry = object.geometry;
            var isLine = (geometry.type === 'Line');

            if (geometry.positions.length === 0) {
                // Skip o/g line declarations that did not follow with any faces
                continue;
            }

            var geometryCfg = {
                primitive: "triangles",
                compressGeometry: false
            };

            geometryCfg.positions = geometry.positions;

            if (geometry.normals.length > 0) {
                geometryCfg.normals = geometry.normals;
            }

            if (geometry.uv.length > 0) {
                geometryCfg.uv = geometry.uv;
            }

            var indices = new Array(geometryCfg.positions.length / 3); // Triangle soup
            for (var idx = 0; idx < indices.length; idx++) {
                indices[idx] = idx;
            }
            geometryCfg.indices = indices;

            //var geometry = new ReadableGeometry(modelNode, geometryCfg);
            var geometry = new ReadableGeometry(modelNode, geometryCfg);

            var materialId = object.material.id;
            var material;
            if (materialId && materialId !== "") {
                material = modelNode.scene.components[materialId];
                if (!material) {
                    modelNode.error("Material not found: " + materialId);
                }
            } else {
                material = new PhongMaterial(modelNode, {
                    //emissive: [0.6, 0.6, 0.0],
                    diffuse: [0.6, 0.6, 0.6],
                    backfaces: true
                });

            }

            // material.emissive = [Math.random(), Math.random(), Math.random()];

            var mesh = new Mesh(modelNode, {
                id: modelNode.id + "#" + object.id,
                isObject: true,
                geometry: geometry,
                material: material,
                pickable: true
            });

            modelNode.addChild(mesh);
        }
    };
})();

function loadFile(url, ok, err) {
    var request = new XMLHttpRequest();
    request.open('GET', url, true);
    request.addEventListener('load', function (event) {
        var response = event.target.response;
        if (this.status === 200) {
            if (ok) {
                ok(response);
            }
        } else if (this.status === 0) {
            // Some browsers return HTTP Status 0 when using non-http protocol
            // e.g. 'file://' or 'data://'. Handle as success.
            console.warn('loadFile: HTTP Status 0 received.');
            if (ok) {
                ok(response);
            }
        } else {
            if (err) {
                err(event);
            }
        }
    }, false);

    request.addEventListener('error', function (event) {
        if (err) {
            err(event);
        }
    }, false);
    request.send(null);
}

export {OBJLoader};