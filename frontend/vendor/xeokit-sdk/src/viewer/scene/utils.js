/**
 * @private
 */
function xmlToJson(node, attributeRenamer) {
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
            var j = xmlToJson(item, attributeRenamer);
            if (j) json.children.push(j);
        }

        return json;
    }
}

/**
 * @private
 */
function clone(ob) {
    return JSON.parse(JSON.stringify(ob));
}

/**
 * @private
 */
var guidChars = [["0", 10], ["A", 26], ["a", 26], ["_", 1], ["$", 1]].map(function (a) {
    var li = [];
    var st = a[0].charCodeAt(0);
    var en = st + a[1];
    for (var i = st; i < en; ++i) {
        li.push(i);
    }
    return String.fromCharCode.apply(null, li);
}).join("");

/**
 * @private
 */
function b64(v, len) {
    var r = (!len || len === 4) ? [0, 6, 12, 18] : [0, 6];
    return r.map(function (i) {
        return guidChars.substr(parseInt(v / (1 << i)) % 64, 1)
    }).reverse().join("");
}

/**
 * @private
 */
function compressGuid(g) {
    var bs = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30].map(function (i) {
        return parseInt(g.substr(i, 2), 16);
    });
    return b64(bs[0], 2) + [1, 4, 7, 10, 13].map(function (i) {
        return b64((bs[i] << 16) + (bs[i + 1] << 8) + bs[i + 2]);
    }).join("");
}

/**
 * @private
 */
function findNodeOfType(m, t) {
    var li = [];
    var _ = function (n) {
        if (n.type === t) li.push(n);
        (n.children || []).forEach(function (c) {
            _(c);
        });
    };
    _(m);
    return li;
}

/**
 * @private
 */
function timeout(dt) {
    return new Promise(function (resolve, reject) {
        setTimeout(resolve, dt);
    });
}

/**
 * @private
 */
function httpRequest(args) {
    return new Promise(function (resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.open(args.method || "GET", args.url, true);
        xhr.onload = function (e) {
            console.log(args.url, xhr.readyState, xhr.status);
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    resolve(xhr.responseXML);
                } else {
                    reject(xhr.statusText);
                }
            }
        };
        xhr.send(null);
    });
}

/**
 * @private
 */
const queryString = function () {
    // This function is anonymous, is executed immediately and
    // the return value is assigned to QueryString!
    var query_string = {};
    var query = window.location.search.substring(1);
    var vars = query.split("&");
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split("=");
        // If first entry with this name
        if (typeof query_string[pair[0]] === "undefined") {
            query_string[pair[0]] = decodeURIComponent(pair[1]);
            // If second entry with this name
        } else if (typeof query_string[pair[0]] === "string") {
            var arr = [query_string[pair[0]], decodeURIComponent(pair[1])];
            query_string[pair[0]] = arr;
            // If third or later entry with this name
        } else {
            query_string[pair[0]].push(decodeURIComponent(pair[1]));
        }
    }
    return query_string;
}();

/**
 * @private
 */
function loadJSON(url, ok, err) {
    // Avoid checking ok and err on each use.
    var defaultCallback = (_value) => undefined;
    ok = ok || defaultCallback;
    err = err || defaultCallback;

    var request = new XMLHttpRequest();
    request.overrideMimeType("application/json");
    request.open('GET', url, true);
    request.addEventListener('load', function (event) {
        var response = event.target.response;
        if (this.status === 200) {
            var json;
            try {
                json = JSON.parse(response);
            } catch (e) {
                err(`utils.loadJSON(): Failed to parse JSON response - ${e}`);
            }
            ok(json);
        } else if (this.status === 0) {
            // Some browsers return HTTP Status 0 when using non-http protocol
            // e.g. 'file://' or 'data://'. Handle as success.
            console.warn('loadFile: HTTP Status 0 received.');
            try {
                ok(JSON.parse(response));
            } catch (e) {
                err(`utils.loadJSON(): Failed to parse JSON response - ${e}`);
            }
        } else {
            err(event);
        }
    }, false);

    request.addEventListener('error', function (event) {
        err(event);
    }, false);
    request.send(null);
}

/**
 * @private
 */
function loadArraybuffer(url, ok, err) {
    // Check for data: URI
    var defaultCallback = (_value) => undefined;
    ok = ok || defaultCallback;
    err = err || defaultCallback;
    const dataUriRegex = /^data:(.*?)(;base64)?,(.*)$/;
    const dataUriRegexResult = url.match(dataUriRegex);
    if (dataUriRegexResult) { // Safari can't handle data URIs through XMLHttpRequest
        const isBase64 = !!dataUriRegexResult[2];
        var data = dataUriRegexResult[3];
        data = window.decodeURIComponent(data);
        if (isBase64) {
            data = window.atob(data);
        }
        try {
            const buffer = new ArrayBuffer(data.length);
            const view = new Uint8Array(buffer);
            for (var i = 0; i < data.length; i++) {
                view[i] = data.charCodeAt(i);
            }
            window.setTimeout(function () {
                ok(buffer);
            }, 0);
        } catch (error) {
            window.setTimeout(function () {
                err(error);
            }, 0);
        }
    } else {
        const request = new XMLHttpRequest();
        request.open('GET', url, true);
        request.responseType = 'arraybuffer';
        request.onreadystatechange = function () {
            if (request.readyState === 4) {
                if (request.status === 200) {
                    ok(request.response);
                } else {
                    err('loadArrayBuffer error : ' + request.response);
                }
            }
        };
        request.send(null);
    }
}

/**
 Tests if the given object is an array
 @private
 */
function isArray(testMesh) {
    return testMesh && !(testMesh.propertyIsEnumerable('length')) && typeof testMesh === 'object' && typeof testMesh.length === 'number';
}

/**
 Tests if the given value is a string
 @param value
 @returns {boolean}
 @private
 */
function isString(value) {
    return (typeof value === 'string' || value instanceof String);
}

/**
 Tests if the given value is a number
 @param value
 @returns {boolean}
 @private
 */
function isNumeric(value) {
    return !isNaN(parseFloat(value)) && isFinite(value);
}

/**
 Tests if the given value is an ID
 @param value
 @returns {boolean}
 @private
 */
function isID(value) {
    return utils.isString(value) || utils.isNumeric(value);
}

/**
 Tests if the given components are the same, where the components can be either IDs or instances.
 @param c1
 @param c2
 @returns {boolean}
 @private
 */
function isSameComponent(c1, c2) {
    if (!c1 || !c2) {
        return false;
    }
    const id1 = (utils.isNumeric(c1) || utils.isString(c1)) ? `${c1}` : c1.id;
    const id2 = (utils.isNumeric(c2) || utils.isString(c2)) ? `${c2}` : c2.id;
    return id1 === id2;
}

/**
 Tests if the given value is a function
 @param value
 @returns {boolean}
 @private
 */
function isFunction(value) {
    return (typeof value === "function");
}

/**
 Tests if the given value is a JavaScript JSON object, eg, ````{ foo: "bar" }````.
 @param value
 @returns {boolean}
 @private
 */
function isObject(value) {
    const objectConstructor = {}.constructor;
    return (!!value && value.constructor === objectConstructor);
}

/** Returns a shallow copy
 */
function copy(o) {
    return utils.apply(o, {});
}

/** Add properties of o to o2, overwriting them on o2 if already there
 */
function apply(o, o2) {
    for (const name in o) {
        if (o.hasOwnProperty(name)) {
            o2[name] = o[name];
        }
    }
    return o2;
}

/**
 Add non-null/defined properties of o to o2
 @private
 */
function apply2(o, o2) {
    for (const name in o) {
        if (o.hasOwnProperty(name)) {
            if (o[name] !== undefined && o[name] !== null) {
                o2[name] = o[name];
            }
        }
    }
    return o2;
}

/**
 Add properties of o to o2 where undefined or null on o2
 @private
 */
function applyIf(o, o2) {
    for (const name in o) {
        if (o.hasOwnProperty(name)) {
            if (o2[name] === undefined || o2[name] === null) {
                o2[name] = o[name];
            }
        }
    }
    return o2;
}

/**
 Returns true if the given map is empty.
 @param obj
 @returns {boolean}
 @private
 */
function isEmptyObject(obj) {
    for (const name in obj) {
        if (obj.hasOwnProperty(name)) {
            return false;
        }
    }
    return true;
}

/**
 Returns the given ID as a string, in quotes if the ID was a string to begin with.

 This is useful for logging IDs.

 @param {Number| String} id The ID
 @returns {String}
 @private
 */
function inQuotes(id) {
    return utils.isNumeric(id) ? (`${id}`) : (`'${id}'`);
}

/**
 Returns the concatenation of two typed arrays.
 @param a
 @param b
 @returns {*|a}
 @private
 */
function concat(a, b) {
    const c = new a.constructor(a.length + b.length);
    c.set(a);
    c.set(b, a.length);
    return c;
}

function flattenParentChildHierarchy(root) {
    var list = [];

    function visit(node) {
        node.id = node.uuid;
        delete node.oid;
        list.push(node);
        var children = node.children;

        if (children) {
            for (var i = 0, len = children.length; i < len; i++) {
                const child = children[i];
                child.parent = node.id;
                visit(children[i]);
            }
        }
        node.children = [];
    }

    visit(root);
    console.log(JSON.stringify(list, null, "\t"));
    return list;
}

/**
 * @private
 */
const utils = {
    xmlToJson: xmlToJson,
    clone: clone,
    compressGuid: compressGuid,
    findNodeOfType: findNodeOfType,
    timeout: timeout,
    httpRequest: httpRequest,
    loadJSON: loadJSON,
    loadArraybuffer: loadArraybuffer,
    queryString: queryString,
    isArray: isArray,
    isString: isString,
    isNumeric: isNumeric,
    isID: isID,
    isSameComponent: isSameComponent,
    isFunction: isFunction,
    isObject: isObject,
    copy: copy,
    apply: apply,
    apply2: apply2,
    applyIf: applyIf,
    isEmptyObject: isEmptyObject,
    inQuotes: inQuotes,
    concat: concat,
    flattenParentChildHierarchy: flattenParentChildHierarchy
};

export {utils};
