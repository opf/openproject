// Some temporary vars to help avoid garbage collection

const tempMat1 = new Float32Array(16);
const tempMat2 = new Float32Array(16);
const tempVec4 = new Float32Array(4);


/**
 * @private
 */
const math = {

    MAX_DOUBLE: Number.MAX_VALUE,
    MIN_DOUBLE: Number.MIN_VALUE,

    /**
     * The number of radiians in a degree (0.0174532925).
     * @property DEGTORAD
     * @type {Number}
     */
    DEGTORAD: 0.0174532925,

    /**
     * The number of degrees in a radian.
     * @property RADTODEG
     * @type {Number}
     */
    RADTODEG: 57.295779513,

    /**
     * Returns a new, uninitialized two-element vector.
     * @method vec2
     * @param [values] Initial values.
     * @static
     * @returns {Number[]}
     */
    vec2(values) {
        return new Float32Array(values || 2);
    },

    /**
     * Returns a new, uninitialized three-element vector.
     * @method vec3
     * @param [values] Initial values.
     * @static
     * @returns {Number[]}
     */
    vec3(values) {
        return new Float32Array(values || 3);
    },

    /**
     * Returns a new, uninitialized four-element vector.
     * @method vec4
     * @param [values] Initial values.
     * @static
     * @returns {Number[]}
     */
    vec4(values) {
        return new Float32Array(values || 4);
    },

    /**
     * Returns a new, uninitialized 3x3 matrix.
     * @method mat3
     * @param [values] Initial values.
     * @static
     * @returns {Number[]}
     */
    mat3(values) {
        return new Float32Array(values || 9);
    },

    /**
     * Converts a 3x3 matrix to 4x4
     * @method mat3ToMat4
     * @param mat3 3x3 matrix.
     * @param mat4 4x4 matrix
     * @static
     * @returns {Number[]}
     */
    mat3ToMat4(mat3, mat4 = new Float32Array(16)) {
        mat4[0] = mat3[0];
        mat4[1] = mat3[1];
        mat4[2] = mat3[2];
        mat4[3] = 0;
        mat4[4] = mat3[3];
        mat4[5] = mat3[4];
        mat4[6] = mat3[5];
        mat4[7] = 0;
        mat4[8] = mat3[6];
        mat4[9] = mat3[7];
        mat4[10] = mat3[8];
        mat4[11] = 0;
        mat4[12] = 0;
        mat4[13] = 0;
        mat4[14] = 0;
        mat4[15] = 1;
        return mat4;
    },

    /**
     * Returns a new, uninitialized 4x4 matrix.
     * @method mat4
     * @param [values] Initial values.
     * @static
     * @returns {Number[]}
     */
    mat4(values) {
        return new Float32Array(values || 16);
    },

    /**
     * Converts a 4x4 matrix to 3x3
     * @method mat4ToMat3
     * @param mat4 4x4 matrix.
     * @param mat3 3x3 matrix
     * @static
     * @returns {Number[]}
     */
    mat4ToMat3(mat4, mat3) { // TODO
        //return new Float32Array(values || 9);
    },

    /**
     * Returns a new UUID.
     * @method createUUID
     * @static
     * @return string The new UUID
     */
    //createUUID: function () {
    //    // http://www.broofa.com/Tools/Math.uuid.htm
    //    var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('');
    //    var uuid = new Array(36);
    //    var rnd = 0;
    //    var r;
    //    return function () {
    //        for (var i = 0; i < 36; i++) {
    //            if (i === 8 || i === 13 || i === 18 || i === 23) {
    //                uuid[i] = '-';
    //            } else if (i === 14) {
    //                uuid[i] = '4';
    //            } else {
    //                if (rnd <= 0x02) {
    //                    rnd = 0x2000000 + ( Math.random() * 0x1000000 ) | 0;
    //                }
    //                r = rnd & 0xf;
    //                rnd = rnd >> 4;
    //                uuid[i] = chars[( i === 19 ) ? ( r & 0x3 ) | 0x8 : r];
    //            }
    //        }
    //        return uuid.join('');
    //    };
    //}(),
    //
    createUUID: ((() => {
        const self = {};
        const lut = [];
        for (let i = 0; i < 256; i++) {
            lut[i] = (i < 16 ? '0' : '') + (i).toString(16);
        }
        return () => {
            const d0 = Math.random() * 0xffffffff | 0;
            const d1 = Math.random() * 0xffffffff | 0;
            const d2 = Math.random() * 0xffffffff | 0;
            const d3 = Math.random() * 0xffffffff | 0;
            return `${lut[d0 & 0xff] + lut[d0 >> 8 & 0xff] + lut[d0 >> 16 & 0xff] + lut[d0 >> 24 & 0xff]}-${lut[d1 & 0xff]}${lut[d1 >> 8 & 0xff]}-${lut[d1 >> 16 & 0x0f | 0x40]}${lut[d1 >> 24 & 0xff]}-${lut[d2 & 0x3f | 0x80]}${lut[d2 >> 8 & 0xff]}-${lut[d2 >> 16 & 0xff]}${lut[d2 >> 24 & 0xff]}${lut[d3 & 0xff]}${lut[d3 >> 8 & 0xff]}${lut[d3 >> 16 & 0xff]}${lut[d3 >> 24 & 0xff]}`;
        };
    }))(),

    /**
     * Clamps a value to the given range.
     * @param {Number} value Value to clamp.
     * @param {Number} min Lower bound.
     * @param {Number} max Upper bound.
     * @returns {Number} Clamped result.
     */
    clamp(value, min, max) {
        return Math.max(min, Math.min(max, value));
    },

    /**
     * Floating-point modulus
     * @method fmod
     * @static
     * @param {Number} a
     * @param {Number} b
     * @returns {*}
     */
    fmod(a, b) {
        if (a < b) {
            console.error("math.fmod : Attempting to find modulus within negative range - would be infinite loop - ignoring");
            return a;
        }
        while (b <= a) {
            a -= b;
        }
        return a;
    },

    /**
     * Negates a four-element vector.
     * @method negateVec4
     * @static
     * @param {Array(Number)} v Vector to negate
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    negateVec4(v, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = -v[0];
        dest[1] = -v[1];
        dest[2] = -v[2];
        dest[3] = -v[3];
        return dest;
    },

    /**
     * Adds one four-element vector to another.
     * @method addVec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    addVec4(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] + v[0];
        dest[1] = u[1] + v[1];
        dest[2] = u[2] + v[2];
        dest[3] = u[3] + v[3];
        return dest;
    },

    /**
     * Adds a scalar value to each element of a four-element vector.
     * @method addVec4Scalar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    addVec4Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] + s;
        dest[1] = v[1] + s;
        dest[2] = v[2] + s;
        dest[3] = v[3] + s;
        return dest;
    },

    /**
     * Adds one three-element vector to another.
     * @method addVec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    addVec3(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] + v[0];
        dest[1] = u[1] + v[1];
        dest[2] = u[2] + v[2];
        return dest;
    },

    /**
     * Adds a scalar value to each element of a three-element vector.
     * @method addVec4Scalar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    addVec3Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] + s;
        dest[1] = v[1] + s;
        dest[2] = v[2] + s;
        return dest;
    },

    /**
     * Subtracts one four-element vector from another.
     * @method subVec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Vector to subtract
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    subVec4(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] - v[0];
        dest[1] = u[1] - v[1];
        dest[2] = u[2] - v[2];
        dest[3] = u[3] - v[3];
        return dest;
    },

    /**
     * Subtracts one three-element vector from another.
     * @method subVec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Vector to subtract
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    subVec3(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] - v[0];
        dest[1] = u[1] - v[1];
        dest[2] = u[2] - v[2];
        return dest;
    },

    /**
     * Subtracts one two-element vector from another.
     * @method subVec2
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Vector to subtract
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    subVec2(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] - v[0];
        dest[1] = u[1] - v[1];
        return dest;
    },

    /**
     * Subtracts a scalar value from each element of a four-element vector.
     * @method subVec4Scalar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    subVec4Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] - s;
        dest[1] = v[1] - s;
        dest[2] = v[2] - s;
        dest[3] = v[3] - s;
        return dest;
    },

    /**
     * Sets each element of a 4-element vector to a scalar value minus the value of that element.
     * @method subScalarVec4
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    subScalarVec4(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = s - v[0];
        dest[1] = s - v[1];
        dest[2] = s - v[2];
        dest[3] = s - v[3];
        return dest;
    },

    /**
     * Multiplies one three-element vector by another.
     * @method mulVec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    mulVec4(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] * v[0];
        dest[1] = u[1] * v[1];
        dest[2] = u[2] * v[2];
        dest[3] = u[3] * v[3];
        return dest;
    },

    /**
     * Multiplies each element of a four-element vector by a scalar.
     * @method mulVec34calar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    mulVec4Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] * s;
        dest[1] = v[1] * s;
        dest[2] = v[2] * s;
        dest[3] = v[3] * s;
        return dest;
    },

    /**
     * Multiplies each element of a three-element vector by a scalar.
     * @method mulVec3Scalar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    mulVec3Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] * s;
        dest[1] = v[1] * s;
        dest[2] = v[2] * s;
        return dest;
    },

    /**
     * Multiplies each element of a two-element vector by a scalar.
     * @method mulVec2Scalar
     * @static
     * @param {Array(Number)} v The vector
     * @param {Number} s The scalar
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, v otherwise
     */
    mulVec2Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] * s;
        dest[1] = v[1] * s;
        return dest;
    },

    /**
     * Divides one three-element vector by another.
     * @method divVec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    divVec3(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] / v[0];
        dest[1] = u[1] / v[1];
        dest[2] = u[2] / v[2];
        return dest;
    },

    /**
     * Divides one four-element vector by another.
     * @method divVec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @param  {Array(Number)} [dest] Destination vector
     * @return {Array(Number)} dest if specified, u otherwise
     */
    divVec4(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        dest[0] = u[0] / v[0];
        dest[1] = u[1] / v[1];
        dest[2] = u[2] / v[2];
        dest[3] = u[3] / v[3];
        return dest;
    },

    /**
     * Divides a scalar by a three-element vector, returning a new vector.
     * @method divScalarVec3
     * @static
     * @param v vec3
     * @param s scalar
     * @param dest vec3 - optional destination
     * @return [] dest if specified, v otherwise
     */
    divScalarVec3(s, v, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = s / v[0];
        dest[1] = s / v[1];
        dest[2] = s / v[2];
        return dest;
    },

    /**
     * Divides a three-element vector by a scalar.
     * @method divVec3Scalar
     * @static
     * @param v vec3
     * @param s scalar
     * @param dest vec3 - optional destination
     * @return [] dest if specified, v otherwise
     */
    divVec3Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] / s;
        dest[1] = v[1] / s;
        dest[2] = v[2] / s;
        return dest;
    },

    /**
     * Divides a four-element vector by a scalar.
     * @method divVec4Scalar
     * @static
     * @param v vec4
     * @param s scalar
     * @param dest vec4 - optional destination
     * @return [] dest if specified, v otherwise
     */
    divVec4Scalar(v, s, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = v[0] / s;
        dest[1] = v[1] / s;
        dest[2] = v[2] / s;
        dest[3] = v[3] / s;
        return dest;
    },


    /**
     * Divides a scalar by a four-element vector, returning a new vector.
     * @method divScalarVec4
     * @static
     * @param s scalar
     * @param v vec4
     * @param dest vec4 - optional destination
     * @return [] dest if specified, v otherwise
     */
    divScalarVec4(s, v, dest) {
        if (!dest) {
            dest = v;
        }
        dest[0] = s / v[0];
        dest[1] = s / v[1];
        dest[2] = s / v[2];
        dest[3] = s / v[3];
        return dest;
    },

    /**
     * Returns the dot product of two four-element vectors.
     * @method dotVec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @return The dot product
     */
    dotVec4(u, v) {
        return (u[0] * v[0] + u[1] * v[1] + u[2] * v[2] + u[3] * v[3]);
    },

    /**
     * Returns the cross product of two four-element vectors.
     * @method cross3Vec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @return The cross product
     */
    cross3Vec4(u, v) {
        const u0 = u[0];
        const u1 = u[1];
        const u2 = u[2];
        const v0 = v[0];
        const v1 = v[1];
        const v2 = v[2];
        return [
            u1 * v2 - u2 * v1,
            u2 * v0 - u0 * v2,
            u0 * v1 - u1 * v0,
            0.0];
    },

    /**
     * Returns the cross product of two three-element vectors.
     * @method cross3Vec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @return The cross product
     */
    cross3Vec3(u, v, dest) {
        if (!dest) {
            dest = u;
        }
        const x = u[0];
        const y = u[1];
        const z = u[2];
        const x2 = v[0];
        const y2 = v[1];
        const z2 = v[2];
        dest[0] = y * z2 - z * y2;
        dest[1] = z * x2 - x * z2;
        dest[2] = x * y2 - y * x2;
        return dest;
    },


    sqLenVec4(v) { // TODO
        return math.dotVec4(v, v);
    },

    /**
     * Returns the length of a four-element vector.
     * @method lenVec4
     * @static
     * @param {Array(Number)} v The vector
     * @return The length
     */
    lenVec4(v) {
        return Math.sqrt(math.sqLenVec4(v));
    },

    /**
     * Returns the dot product of two three-element vectors.
     * @method dotVec3
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @return The dot product
     */
    dotVec3(u, v) {
        return (u[0] * v[0] + u[1] * v[1] + u[2] * v[2]);
    },

    /**
     * Returns the dot product of two two-element vectors.
     * @method dotVec4
     * @static
     * @param {Array(Number)} u First vector
     * @param {Array(Number)} v Second vector
     * @return The dot product
     */
    dotVec2(u, v) {
        return (u[0] * v[0] + u[1] * v[1]);
    },


    sqLenVec3(v) {
        return math.dotVec3(v, v);
    },


    sqLenVec2(v) {
        return math.dotVec2(v, v);
    },

    /**
     * Returns the length of a three-element vector.
     * @method lenVec3
     * @static
     * @param {Array(Number)} v The vector
     * @return The length
     */
    lenVec3(v) {
        return Math.sqrt(math.sqLenVec3(v));
    },

    distVec3: ((() => {
        const vec = new Float32Array(3);
        return (v, w) => math.lenVec3(math.subVec3(v, w, vec));
    }))(),

    /**
     * Returns the length of a two-element vector.
     * @method lenVec2
     * @static
     * @param {Array(Number)} v The vector
     * @return The length
     */
    lenVec2(v) {
        return Math.sqrt(math.sqLenVec2(v));
    },

    distVec2: ((() => {
        const vec = new Float32Array(2);
        return (v, w) => math.lenVec2(math.subVec2(v, w, vec));
    }))(),

    /**
     * @method rcpVec3
     * @static
     * @param v vec3
     * @param dest vec3 - optional destination
     * @return [] dest if specified, v otherwise
     *
     */
    rcpVec3(v, dest) {
        return math.divScalarVec3(1.0, v, dest);
    },

    /**
     * Normalizes a four-element vector
     * @method normalizeVec4
     * @static
     * @param v vec4
     * @param dest vec4 - optional destination
     * @return [] dest if specified, v otherwise
     *
     */
    normalizeVec4(v, dest) {
        const f = 1.0 / math.lenVec4(v);
        return math.mulVec4Scalar(v, f, dest);
    },

    /**
     * Normalizes a three-element vector
     * @method normalizeVec4
     * @static
     */
    normalizeVec3(v, dest) {
        const f = 1.0 / math.lenVec3(v);
        return math.mulVec3Scalar(v, f, dest);
    },

    /**
     * Normalizes a two-element vector
     * @method normalizeVec2
     * @static
     */
    normalizeVec2(v, dest) {
        const f = 1.0 / math.lenVec2(v);
        return math.mulVec2Scalar(v, f, dest);
    },

    /**
     * Gets the angle between two vectors
     * @method angleVec3
     * @param v
     * @param w
     * @returns {number}
     */
    angleVec3(v, w) {
        let theta = math.dotVec3(v, w) / (Math.sqrt(math.sqLenVec3(v) * math.sqLenVec3(w)));
        theta = theta < -1 ? -1 : (theta > 1 ? 1 : theta);  // Clamp to handle numerical problems
        return Math.acos(theta);
    },

    /**
     * Creates a three-element vector from the rotation part of a sixteen-element matrix.
     * @param m
     * @param dest
     */
    vec3FromMat4Scale: ((() => {

        const tempVec3 = new Float32Array(3);

        return (m, dest) => {

            tempVec3[0] = m[0];
            tempVec3[1] = m[1];
            tempVec3[2] = m[2];

            dest[0] = math.lenVec3(tempVec3);

            tempVec3[0] = m[4];
            tempVec3[1] = m[5];
            tempVec3[2] = m[6];

            dest[1] = math.lenVec3(tempVec3);

            tempVec3[0] = m[8];
            tempVec3[1] = m[9];
            tempVec3[2] = m[10];

            dest[2] = math.lenVec3(tempVec3);

            return dest;
        };
    }))(),

    /**
     * Converts an n-element vector to a JSON-serializable
     * array with values rounded to two decimal places.
     */
    vecToArray: ((() => {
        function trunc(v) {
            return Math.round(v * 100000) / 100000
        }

        return v => {
            v = Array.prototype.slice.call(v);
            for (let i = 0, len = v.length; i < len; i++) {
                v[i] = trunc(v[i]);
            }
            return v;
        };
    }))(),

    /**
     * Converts a 3-element vector from an array to an object of the form ````{x:999, y:999, z:999}````.
     * @param arr
     * @returns {{x: *, y: *, z: *}}
     */
    xyzArrayToObject(arr) {
        return {"x": arr[0], "y": arr[1], "z": arr[2]};
    },

    /**
     * Converts a 3-element vector object of the form ````{x:999, y:999, z:999}```` to an array.
     * @param xyz
     * @param  [arry]
     * @returns {*[]}
     */
    xyzObjectToArray(xyz, arry) {
        arry = arry || new Float32Array(3);
        arry[0] = xyz.x;
        arry[1] = xyz.y;
        arry[2] = xyz.z;
        return arry;
    },

    /**
     * Duplicates a 4x4 identity matrix.
     * @method dupMat4
     * @static
     */
    dupMat4(m) {
        return m.slice(0, 16);
    },

    /**
     * Extracts a 3x3 matrix from a 4x4 matrix.
     * @method mat4To3
     * @static
     */
    mat4To3(m) {
        return [
            m[0], m[1], m[2],
            m[4], m[5], m[6],
            m[8], m[9], m[10]
        ];
    },

    /**
     * Returns a 4x4 matrix with each element set to the given scalar value.
     * @method m4s
     * @static
     */
    m4s(s) {
        return [
            s, s, s, s,
            s, s, s, s,
            s, s, s, s,
            s, s, s, s
        ];
    },

    /**
     * Returns a 4x4 matrix with each element set to zero.
     * @method setMat4ToZeroes
     * @static
     */
    setMat4ToZeroes() {
        return math.m4s(0.0);
    },

    /**
     * Returns a 4x4 matrix with each element set to 1.0.
     * @method setMat4ToOnes
     * @static
     */
    setMat4ToOnes() {
        return math.m4s(1.0);
    },

    /**
     * Returns a 4x4 matrix with each element set to 1.0.
     * @method setMat4ToOnes
     * @static
     */
    diagonalMat4v(v) {
        return new Float32Array([
            v[0], 0.0, 0.0, 0.0,
            0.0, v[1], 0.0, 0.0,
            0.0, 0.0, v[2], 0.0,
            0.0, 0.0, 0.0, v[3]
        ]);
    },

    /**
     * Returns a 4x4 matrix with diagonal elements set to the given vector.
     * @method diagonalMat4c
     * @static
     */
    diagonalMat4c(x, y, z, w) {
        return math.diagonalMat4v([x, y, z, w]);
    },

    /**
     * Returns a 4x4 matrix with diagonal elements set to the given scalar.
     * @method diagonalMat4s
     * @static
     */
    diagonalMat4s(s) {
        return math.diagonalMat4c(s, s, s, s);
    },

    /**
     * Returns a 4x4 identity matrix.
     * @method identityMat4
     * @static
     */
    identityMat4(mat = new Float32Array(16)) {
        mat[0] = 1.0;
        mat[1] = 0.0;
        mat[2] = 0.0;
        mat[3] = 0.0;

        mat[4] = 0.0;
        mat[5] = 1.0;
        mat[6] = 0.0;
        mat[7] = 0.0;

        mat[8] = 0.0;
        mat[9] = 0.0;
        mat[10] = 1.0;
        mat[11] = 0.0;

        mat[12] = 0.0;
        mat[13] = 0.0;
        mat[14] = 0.0;
        mat[15] = 1.0;

        return mat;
    },

    /**
     * Returns a 3x3 identity matrix.
     * @method identityMat3
     * @static
     */
    identityMat3(mat = new Float32Array(9)) {
        mat[0] = 1.0;
        mat[1] = 0.0;
        mat[2] = 0.0;

        mat[3] = 0.0;
        mat[4] = 1.0;
        mat[5] = 0.0;

        mat[6] = 0.0;
        mat[7] = 0.0;
        mat[8] = 1.0;

        return mat;
    },

    /**
     * Tests if the given 4x4 matrix is the identity matrix.
     * @method isIdentityMat4
     * @static
     */
    isIdentityMat4(m) {
        if (m[0] !== 1.0 || m[1] !== 0.0 || m[2] !== 0.0 || m[3] !== 0.0 ||
            m[4] !== 0.0 || m[5] !== 1.0 || m[6] !== 0.0 || m[7] !== 0.0 ||
            m[8] !== 0.0 || m[9] !== 0.0 || m[10] !== 1.0 || m[11] !== 0.0 ||
            m[12] !== 0.0 || m[13] !== 0.0 || m[14] !== 0.0 || m[15] !== 1.0) {
            return false;
        }
        return true;
    },

    /**
     * Negates the given 4x4 matrix.
     * @method negateMat4
     * @static
     */
    negateMat4(m, dest) {
        if (!dest) {
            dest = m;
        }
        dest[0] = -m[0];
        dest[1] = -m[1];
        dest[2] = -m[2];
        dest[3] = -m[3];
        dest[4] = -m[4];
        dest[5] = -m[5];
        dest[6] = -m[6];
        dest[7] = -m[7];
        dest[8] = -m[8];
        dest[9] = -m[9];
        dest[10] = -m[10];
        dest[11] = -m[11];
        dest[12] = -m[12];
        dest[13] = -m[13];
        dest[14] = -m[14];
        dest[15] = -m[15];
        return dest;
    },

    /**
     * Adds the given 4x4 matrices together.
     * @method addMat4
     * @static
     */
    addMat4(a, b, dest) {
        if (!dest) {
            dest = a;
        }
        dest[0] = a[0] + b[0];
        dest[1] = a[1] + b[1];
        dest[2] = a[2] + b[2];
        dest[3] = a[3] + b[3];
        dest[4] = a[4] + b[4];
        dest[5] = a[5] + b[5];
        dest[6] = a[6] + b[6];
        dest[7] = a[7] + b[7];
        dest[8] = a[8] + b[8];
        dest[9] = a[9] + b[9];
        dest[10] = a[10] + b[10];
        dest[11] = a[11] + b[11];
        dest[12] = a[12] + b[12];
        dest[13] = a[13] + b[13];
        dest[14] = a[14] + b[14];
        dest[15] = a[15] + b[15];
        return dest;
    },

    /**
     * Adds the given scalar to each element of the given 4x4 matrix.
     * @method addMat4Scalar
     * @static
     */
    addMat4Scalar(m, s, dest) {
        if (!dest) {
            dest = m;
        }
        dest[0] = m[0] + s;
        dest[1] = m[1] + s;
        dest[2] = m[2] + s;
        dest[3] = m[3] + s;
        dest[4] = m[4] + s;
        dest[5] = m[5] + s;
        dest[6] = m[6] + s;
        dest[7] = m[7] + s;
        dest[8] = m[8] + s;
        dest[9] = m[9] + s;
        dest[10] = m[10] + s;
        dest[11] = m[11] + s;
        dest[12] = m[12] + s;
        dest[13] = m[13] + s;
        dest[14] = m[14] + s;
        dest[15] = m[15] + s;
        return dest;
    },

    /**
     * Adds the given scalar to each element of the given 4x4 matrix.
     * @method addScalarMat4
     * @static
     */
    addScalarMat4(s, m, dest) {
        return math.addMat4Scalar(m, s, dest);
    },

    /**
     * Subtracts the second 4x4 matrix from the first.
     * @method subMat4
     * @static
     */
    subMat4(a, b, dest) {
        if (!dest) {
            dest = a;
        }
        dest[0] = a[0] - b[0];
        dest[1] = a[1] - b[1];
        dest[2] = a[2] - b[2];
        dest[3] = a[3] - b[3];
        dest[4] = a[4] - b[4];
        dest[5] = a[5] - b[5];
        dest[6] = a[6] - b[6];
        dest[7] = a[7] - b[7];
        dest[8] = a[8] - b[8];
        dest[9] = a[9] - b[9];
        dest[10] = a[10] - b[10];
        dest[11] = a[11] - b[11];
        dest[12] = a[12] - b[12];
        dest[13] = a[13] - b[13];
        dest[14] = a[14] - b[14];
        dest[15] = a[15] - b[15];
        return dest;
    },

    /**
     * Subtracts the given scalar from each element of the given 4x4 matrix.
     * @method subMat4Scalar
     * @static
     */
    subMat4Scalar(m, s, dest) {
        if (!dest) {
            dest = m;
        }
        dest[0] = m[0] - s;
        dest[1] = m[1] - s;
        dest[2] = m[2] - s;
        dest[3] = m[3] - s;
        dest[4] = m[4] - s;
        dest[5] = m[5] - s;
        dest[6] = m[6] - s;
        dest[7] = m[7] - s;
        dest[8] = m[8] - s;
        dest[9] = m[9] - s;
        dest[10] = m[10] - s;
        dest[11] = m[11] - s;
        dest[12] = m[12] - s;
        dest[13] = m[13] - s;
        dest[14] = m[14] - s;
        dest[15] = m[15] - s;
        return dest;
    },

    /**
     * Subtracts the given scalar from each element of the given 4x4 matrix.
     * @method subScalarMat4
     * @static
     */
    subScalarMat4(s, m, dest) {
        if (!dest) {
            dest = m;
        }
        dest[0] = s - m[0];
        dest[1] = s - m[1];
        dest[2] = s - m[2];
        dest[3] = s - m[3];
        dest[4] = s - m[4];
        dest[5] = s - m[5];
        dest[6] = s - m[6];
        dest[7] = s - m[7];
        dest[8] = s - m[8];
        dest[9] = s - m[9];
        dest[10] = s - m[10];
        dest[11] = s - m[11];
        dest[12] = s - m[12];
        dest[13] = s - m[13];
        dest[14] = s - m[14];
        dest[15] = s - m[15];
        return dest;
    },

    /**
     * Multiplies the two given 4x4 matrix by each other.
     * @method mulMat4
     * @static
     */
    mulMat4(a, b, dest) {
        if (!dest) {
            dest = a;
        }

        // Cache the matrix values (makes for huge speed increases!)
        const a00 = a[0];

        const a01 = a[1];
        const a02 = a[2];
        const a03 = a[3];
        const a10 = a[4];
        const a11 = a[5];
        const a12 = a[6];
        const a13 = a[7];
        const a20 = a[8];
        const a21 = a[9];
        const a22 = a[10];
        const a23 = a[11];
        const a30 = a[12];
        const a31 = a[13];
        const a32 = a[14];
        const a33 = a[15];
        const b00 = b[0];
        const b01 = b[1];
        const b02 = b[2];
        const b03 = b[3];
        const b10 = b[4];
        const b11 = b[5];
        const b12 = b[6];
        const b13 = b[7];
        const b20 = b[8];
        const b21 = b[9];
        const b22 = b[10];
        const b23 = b[11];
        const b30 = b[12];
        const b31 = b[13];
        const b32 = b[14];
        const b33 = b[15];

        dest[0] = b00 * a00 + b01 * a10 + b02 * a20 + b03 * a30;
        dest[1] = b00 * a01 + b01 * a11 + b02 * a21 + b03 * a31;
        dest[2] = b00 * a02 + b01 * a12 + b02 * a22 + b03 * a32;
        dest[3] = b00 * a03 + b01 * a13 + b02 * a23 + b03 * a33;
        dest[4] = b10 * a00 + b11 * a10 + b12 * a20 + b13 * a30;
        dest[5] = b10 * a01 + b11 * a11 + b12 * a21 + b13 * a31;
        dest[6] = b10 * a02 + b11 * a12 + b12 * a22 + b13 * a32;
        dest[7] = b10 * a03 + b11 * a13 + b12 * a23 + b13 * a33;
        dest[8] = b20 * a00 + b21 * a10 + b22 * a20 + b23 * a30;
        dest[9] = b20 * a01 + b21 * a11 + b22 * a21 + b23 * a31;
        dest[10] = b20 * a02 + b21 * a12 + b22 * a22 + b23 * a32;
        dest[11] = b20 * a03 + b21 * a13 + b22 * a23 + b23 * a33;
        dest[12] = b30 * a00 + b31 * a10 + b32 * a20 + b33 * a30;
        dest[13] = b30 * a01 + b31 * a11 + b32 * a21 + b33 * a31;
        dest[14] = b30 * a02 + b31 * a12 + b32 * a22 + b33 * a32;
        dest[15] = b30 * a03 + b31 * a13 + b32 * a23 + b33 * a33;

        return dest;
    },

    /**
     * Multiplies the two given 3x3 matrices by each other.
     * @method mulMat4
     * @static
     */
    mulMat3(a, b, dest) {
        if (!dest) {
            dest = new Float32Array(9);
        }

        const a11 = a[0];
        const a12 = a[3];
        const a13 = a[6];
        const a21 = a[1];
        const a22 = a[4];
        const a23 = a[7];
        const a31 = a[2];
        const a32 = a[5];
        const a33 = a[8];
        const b11 = b[0];
        const b12 = b[3];
        const b13 = b[6];
        const b21 = b[1];
        const b22 = b[4];
        const b23 = b[7];
        const b31 = b[2];
        const b32 = b[5];
        const b33 = b[8];

        dest[0] = a11 * b11 + a12 * b21 + a13 * b31;
        dest[3] = a11 * b12 + a12 * b22 + a13 * b32;
        dest[6] = a11 * b13 + a12 * b23 + a13 * b33;

        dest[1] = a21 * b11 + a22 * b21 + a23 * b31;
        dest[4] = a21 * b12 + a22 * b22 + a23 * b32;
        dest[7] = a21 * b13 + a22 * b23 + a23 * b33;

        dest[2] = a31 * b11 + a32 * b21 + a33 * b31;
        dest[5] = a31 * b12 + a32 * b22 + a33 * b32;
        dest[8] = a31 * b13 + a32 * b23 + a33 * b33;

        return dest;
    },

    /**
     * Multiplies each element of the given 4x4 matrix by the given scalar.
     * @method mulMat4Scalar
     * @static
     */
    mulMat4Scalar(m, s, dest) {
        if (!dest) {
            dest = m;
        }
        dest[0] = m[0] * s;
        dest[1] = m[1] * s;
        dest[2] = m[2] * s;
        dest[3] = m[3] * s;
        dest[4] = m[4] * s;
        dest[5] = m[5] * s;
        dest[6] = m[6] * s;
        dest[7] = m[7] * s;
        dest[8] = m[8] * s;
        dest[9] = m[9] * s;
        dest[10] = m[10] * s;
        dest[11] = m[11] * s;
        dest[12] = m[12] * s;
        dest[13] = m[13] * s;
        dest[14] = m[14] * s;
        dest[15] = m[15] * s;
        return dest;
    },

    /**
     * Multiplies the given 4x4 matrix by the given four-element vector.
     * @method mulMat4v4
     * @static
     */
    mulMat4v4(m, v, dest = math.vec4()) {
        const v0 = v[0];
        const v1 = v[1];
        const v2 = v[2];
        const v3 = v[3];
        dest[0] = m[0] * v0 + m[4] * v1 + m[8] * v2 + m[12] * v3;
        dest[1] = m[1] * v0 + m[5] * v1 + m[9] * v2 + m[13] * v3;
        dest[2] = m[2] * v0 + m[6] * v1 + m[10] * v2 + m[14] * v3;
        dest[3] = m[3] * v0 + m[7] * v1 + m[11] * v2 + m[15] * v3;
        return dest;
    },

    /**
     * Transposes the given 4x4 matrix.
     * @method transposeMat4
     * @static
     */
    transposeMat4(mat, dest) {
        // If we are transposing ourselves we can skip a few steps but have to cache some values
        const m4 = mat[4];

        const m14 = mat[14];
        const m8 = mat[8];
        const m13 = mat[13];
        const m12 = mat[12];
        const m9 = mat[9];
        if (!dest || mat === dest) {
            const a01 = mat[1];
            const a02 = mat[2];
            const a03 = mat[3];
            const a12 = mat[6];
            const a13 = mat[7];
            const a23 = mat[11];
            mat[1] = m4;
            mat[2] = m8;
            mat[3] = m12;
            mat[4] = a01;
            mat[6] = m9;
            mat[7] = m13;
            mat[8] = a02;
            mat[9] = a12;
            mat[11] = m14;
            mat[12] = a03;
            mat[13] = a13;
            mat[14] = a23;
            return mat;
        }
        dest[0] = mat[0];
        dest[1] = m4;
        dest[2] = m8;
        dest[3] = m12;
        dest[4] = mat[1];
        dest[5] = mat[5];
        dest[6] = m9;
        dest[7] = m13;
        dest[8] = mat[2];
        dest[9] = mat[6];
        dest[10] = mat[10];
        dest[11] = m14;
        dest[12] = mat[3];
        dest[13] = mat[7];
        dest[14] = mat[11];
        dest[15] = mat[15];
        return dest;
    },

    /**
     * Transposes the given 3x3 matrix.
     *
     * @method transposeMat3
     * @static
     */
    transposeMat3(mat, dest) {
        if (dest === mat) {
            const a01 = mat[1];
            const a02 = mat[2];
            const a12 = mat[5];
            dest[1] = mat[3];
            dest[2] = mat[6];
            dest[3] = a01;
            dest[5] = mat[7];
            dest[6] = a02;
            dest[7] = a12;
        } else {
            dest[0] = mat[0];
            dest[1] = mat[3];
            dest[2] = mat[6];
            dest[3] = mat[1];
            dest[4] = mat[4];
            dest[5] = mat[7];
            dest[6] = mat[2];
            dest[7] = mat[5];
            dest[8] = mat[8];
        }
        return dest;
    },

    /**
     * Returns the determinant of the given 4x4 matrix.
     * @method determinantMat4
     * @static
     */
    determinantMat4(mat) {
        // Cache the matrix values (makes for huge speed increases!)
        const a00 = mat[0];

        const a01 = mat[1];
        const a02 = mat[2];
        const a03 = mat[3];
        const a10 = mat[4];
        const a11 = mat[5];
        const a12 = mat[6];
        const a13 = mat[7];
        const a20 = mat[8];
        const a21 = mat[9];
        const a22 = mat[10];
        const a23 = mat[11];
        const a30 = mat[12];
        const a31 = mat[13];
        const a32 = mat[14];
        const a33 = mat[15];
        return a30 * a21 * a12 * a03 - a20 * a31 * a12 * a03 - a30 * a11 * a22 * a03 + a10 * a31 * a22 * a03 +
            a20 * a11 * a32 * a03 - a10 * a21 * a32 * a03 - a30 * a21 * a02 * a13 + a20 * a31 * a02 * a13 +
            a30 * a01 * a22 * a13 - a00 * a31 * a22 * a13 - a20 * a01 * a32 * a13 + a00 * a21 * a32 * a13 +
            a30 * a11 * a02 * a23 - a10 * a31 * a02 * a23 - a30 * a01 * a12 * a23 + a00 * a31 * a12 * a23 +
            a10 * a01 * a32 * a23 - a00 * a11 * a32 * a23 - a20 * a11 * a02 * a33 + a10 * a21 * a02 * a33 +
            a20 * a01 * a12 * a33 - a00 * a21 * a12 * a33 - a10 * a01 * a22 * a33 + a00 * a11 * a22 * a33;
    },

    /**
     * Returns the inverse of the given 4x4 matrix.
     * @method inverseMat4
     * @static
     */
    inverseMat4(mat, dest) {
        if (!dest) {
            dest = mat;
        }

        // Cache the matrix values (makes for huge speed increases!)
        const a00 = mat[0];

        const a01 = mat[1];
        const a02 = mat[2];
        const a03 = mat[3];
        const a10 = mat[4];
        const a11 = mat[5];
        const a12 = mat[6];
        const a13 = mat[7];
        const a20 = mat[8];
        const a21 = mat[9];
        const a22 = mat[10];
        const a23 = mat[11];
        const a30 = mat[12];
        const a31 = mat[13];
        const a32 = mat[14];
        const a33 = mat[15];
        const b00 = a00 * a11 - a01 * a10;
        const b01 = a00 * a12 - a02 * a10;
        const b02 = a00 * a13 - a03 * a10;
        const b03 = a01 * a12 - a02 * a11;
        const b04 = a01 * a13 - a03 * a11;
        const b05 = a02 * a13 - a03 * a12;
        const b06 = a20 * a31 - a21 * a30;
        const b07 = a20 * a32 - a22 * a30;
        const b08 = a20 * a33 - a23 * a30;
        const b09 = a21 * a32 - a22 * a31;
        const b10 = a21 * a33 - a23 * a31;
        const b11 = a22 * a33 - a23 * a32;

        // Calculate the determinant (inlined to avoid double-caching)
        const invDet = 1 / (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);

        dest[0] = (a11 * b11 - a12 * b10 + a13 * b09) * invDet;
        dest[1] = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
        dest[2] = (a31 * b05 - a32 * b04 + a33 * b03) * invDet;
        dest[3] = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
        dest[4] = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
        dest[5] = (a00 * b11 - a02 * b08 + a03 * b07) * invDet;
        dest[6] = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
        dest[7] = (a20 * b05 - a22 * b02 + a23 * b01) * invDet;
        dest[8] = (a10 * b10 - a11 * b08 + a13 * b06) * invDet;
        dest[9] = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
        dest[10] = (a30 * b04 - a31 * b02 + a33 * b00) * invDet;
        dest[11] = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
        dest[12] = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
        dest[13] = (a00 * b09 - a01 * b07 + a02 * b06) * invDet;
        dest[14] = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
        dest[15] = (a20 * b03 - a21 * b01 + a22 * b00) * invDet;

        return dest;
    },

    /**
     * Returns the trace of the given 4x4 matrix.
     * @method traceMat4
     * @static
     */
    traceMat4(m) {
        return (m[0] + m[5] + m[10] + m[15]);
    },

    /**
     * Returns 4x4 translation matrix.
     * @method translationMat4
     * @static
     */
    translationMat4v(v, dest) {
        const m = dest || math.identityMat4();
        m[12] = v[0];
        m[13] = v[1];
        m[14] = v[2];
        return m;
    },

    /**
     * Returns 3x3 translation matrix.
     * @method translationMat3
     * @static
     */
    translationMat3v(v, dest) {
        const m = dest || math.identityMat3();
        m[6] = v[0];
        m[7] = v[1];
        return m;
    },

    /**
     * Returns 4x4 translation matrix.
     * @method translationMat4c
     * @static
     */
    translationMat4c: ((() => {
        const xyz = new Float32Array(3);
        return (x, y, z, dest) => {
            xyz[0] = x;
            xyz[1] = y;
            xyz[2] = z;
            return math.translationMat4v(xyz, dest);
        };
    }))(),

    /**
     * Returns 4x4 translation matrix.
     * @method translationMat4s
     * @static
     */
    translationMat4s(s, dest) {
        return math.translationMat4c(s, s, s, dest);
    },

    /**
     * Efficiently post-concatenates a translation to the given matrix.
     * @param v
     * @param m
     */
    translateMat4v(xyz, m) {
        return math.translateMat4c(xyz[0], xyz[1], xyz[2], m);
    },

    /**
     * Efficiently post-concatenates a translation to the given matrix.
     * @param x
     * @param y
     * @param z
     * @param m
     */
    OLDtranslateMat4c(x, y, z, m) {

        const m12 = m[12];
        m[0] += m12 * x;
        m[4] += m12 * y;
        m[8] += m12 * z;

        const m13 = m[13];
        m[1] += m13 * x;
        m[5] += m13 * y;
        m[9] += m13 * z;

        const m14 = m[14];
        m[2] += m14 * x;
        m[6] += m14 * y;
        m[10] += m14 * z;

        const m15 = m[15];
        m[3] += m15 * x;
        m[7] += m15 * y;
        m[11] += m15 * z;

        return m;
    },

    translateMat4c(x, y, z, m) {

        const m3 = m[3];
        m[0] += m3 * x;
        m[1] += m3 * y;
        m[2] += m3 * z;

        const m7 = m[7];
        m[4] += m7 * x;
        m[5] += m7 * y;
        m[6] += m7 * z;

        const m11 = m[11];
        m[8] += m11 * x;
        m[9] += m11 * y;
        m[10] += m11 * z;

        const m15 = m[15];
        m[12] += m15 * x;
        m[13] += m15 * y;
        m[14] += m15 * z;

        return m;
    },
    /**
     * Returns 4x4 rotation matrix.
     * @method rotationMat4v
     * @static
     */
    rotationMat4v(anglerad, axis, m) {
        const ax = math.normalizeVec4([axis[0], axis[1], axis[2], 0.0], []);
        const s = Math.sin(anglerad);
        const c = Math.cos(anglerad);
        const q = 1.0 - c;

        const x = ax[0];
        const y = ax[1];
        const z = ax[2];

        let xy;
        let yz;
        let zx;
        let xs;
        let ys;
        let zs;

        //xx = x * x; used once
        //yy = y * y; used once
        //zz = z * z; used once
        xy = x * y;
        yz = y * z;
        zx = z * x;
        xs = x * s;
        ys = y * s;
        zs = z * s;

        m = m || math.mat4();

        m[0] = (q * x * x) + c;
        m[1] = (q * xy) + zs;
        m[2] = (q * zx) - ys;
        m[3] = 0.0;

        m[4] = (q * xy) - zs;
        m[5] = (q * y * y) + c;
        m[6] = (q * yz) + xs;
        m[7] = 0.0;

        m[8] = (q * zx) + ys;
        m[9] = (q * yz) - xs;
        m[10] = (q * z * z) + c;
        m[11] = 0.0;

        m[12] = 0.0;
        m[13] = 0.0;
        m[14] = 0.0;
        m[15] = 1.0;

        return m;
    },

    /**
     * Returns 4x4 rotation matrix.
     * @method rotationMat4c
     * @static
     */
    rotationMat4c(anglerad, x, y, z, mat) {
        return math.rotationMat4v(anglerad, [x, y, z], mat);
    },

    /**
     * Returns 4x4 scale matrix.
     * @method scalingMat4v
     * @static
     */
    scalingMat4v(v, m = math.identityMat4()) {
        m[0] = v[0];
        m[5] = v[1];
        m[10] = v[2];
        return m;
    },

    /**
     * Returns 3x3 scale matrix.
     * @method scalingMat3v
     * @static
     */
    scalingMat3v(v, m = math.identityMat3()) {
        m[0] = v[0];
        m[4] = v[1];
        return m;
    },

    /**
     * Returns 4x4 scale matrix.
     * @method scalingMat4c
     * @static
     */
    scalingMat4c: ((() => {
        const xyz = new Float32Array(3);
        return (x, y, z, dest) => {
            xyz[0] = x;
            xyz[1] = y;
            xyz[2] = z;
            return math.scalingMat4v(xyz, dest);
        };
    }))(),

    /**
     * Efficiently post-concatenates a scaling to the given matrix.
     * @method scaleMat4c
     * @param x
     * @param y
     * @param z
     * @param m
     */
    scaleMat4c(x, y, z, m) {

        m[0] *= x;
        m[4] *= y;
        m[8] *= z;

        m[1] *= x;
        m[5] *= y;
        m[9] *= z;

        m[2] *= x;
        m[6] *= y;
        m[10] *= z;

        m[3] *= x;
        m[7] *= y;
        m[11] *= z;
        return m;
    },

    /**
     * Efficiently post-concatenates a scaling to the given matrix.
     * @method scaleMat4c
     * @param xyz
     * @param m
     */
    scaleMat4v(xyz, m) {

        const x = xyz[0];
        const y = xyz[1];
        const z = xyz[2];

        m[0] *= x;
        m[4] *= y;
        m[8] *= z;
        m[1] *= x;
        m[5] *= y;
        m[9] *= z;
        m[2] *= x;
        m[6] *= y;
        m[10] *= z;
        m[3] *= x;
        m[7] *= y;
        m[11] *= z;

        return m;
    },

    /**
     * Returns 4x4 scale matrix.
     * @method scalingMat4s
     * @static
     */
    scalingMat4s(s) {
        return math.scalingMat4c(s, s, s);
    },

    /**
     * Creates a matrix from a quaternion rotation and vector translation
     *
     * @param {Number[]} q Rotation quaternion
     * @param {Number[]} v Translation vector
     * @param {Number[]} dest Destination matrix
     * @returns {Number[]} dest
     */
    rotationTranslationMat4(q, v, dest = math.mat4()) {
        const x = q[0];
        const y = q[1];
        const z = q[2];
        const w = q[3];

        const x2 = x + x;
        const y2 = y + y;
        const z2 = z + z;
        const xx = x * x2;
        const xy = x * y2;
        const xz = x * z2;
        const yy = y * y2;
        const yz = y * z2;
        const zz = z * z2;
        const wx = w * x2;
        const wy = w * y2;
        const wz = w * z2;

        dest[0] = 1 - (yy + zz);
        dest[1] = xy + wz;
        dest[2] = xz - wy;
        dest[3] = 0;
        dest[4] = xy - wz;
        dest[5] = 1 - (xx + zz);
        dest[6] = yz + wx;
        dest[7] = 0;
        dest[8] = xz + wy;
        dest[9] = yz - wx;
        dest[10] = 1 - (xx + yy);
        dest[11] = 0;
        dest[12] = v[0];
        dest[13] = v[1];
        dest[14] = v[2];
        dest[15] = 1;

        return dest;
    },

    /**
     * Gets Euler angles from a 4x4 matrix.
     *
     * @param {Number[]} mat The 4x4 matrix.
     * @param {String} order Desired Euler angle order: "XYZ", "YXZ", "ZXY" etc.
     * @param {Number[]} [dest] Destination Euler angles, created by default.
     * @returns {Number[]} The Euler angles.
     */
    mat4ToEuler(mat, order, dest = math.vec4()) {
        const clamp = math.clamp;

        // Assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

        const m11 = mat[0];

        const m12 = mat[4];
        const m13 = mat[8];
        const m21 = mat[1];
        const m22 = mat[5];
        const m23 = mat[9];
        const m31 = mat[2];
        const m32 = mat[6];
        const m33 = mat[10];

        if (order === 'XYZ') {

            dest[1] = Math.asin(clamp(m13, -1, 1));

            if (Math.abs(m13) < 0.99999) {
                dest[0] = Math.atan2(-m23, m33);
                dest[2] = Math.atan2(-m12, m11);
            } else {
                dest[0] = Math.atan2(m32, m22);
                dest[2] = 0;

            }

        } else if (order === 'YXZ') {

            dest[0] = Math.asin(-clamp(m23, -1, 1));

            if (Math.abs(m23) < 0.99999) {
                dest[1] = Math.atan2(m13, m33);
                dest[2] = Math.atan2(m21, m22);
            } else {
                dest[1] = Math.atan2(-m31, m11);
                dest[2] = 0;
            }

        } else if (order === 'ZXY') {

            dest[0] = Math.asin(clamp(m32, -1, 1));

            if (Math.abs(m32) < 0.99999) {
                dest[1] = Math.atan2(-m31, m33);
                dest[2] = Math.atan2(-m12, m22);
            } else {
                dest[1] = 0;
                dest[2] = Math.atan2(m21, m11);
            }

        } else if (order === 'ZYX') {

            dest[1] = Math.asin(-clamp(m31, -1, 1));

            if (Math.abs(m31) < 0.99999) {
                dest[0] = Math.atan2(m32, m33);
                dest[2] = Math.atan2(m21, m11);
            } else {
                dest[0] = 0;
                dest[2] = Math.atan2(-m12, m22);
            }

        } else if (order === 'YZX') {

            dest[2] = Math.asin(clamp(m21, -1, 1));

            if (Math.abs(m21) < 0.99999) {
                dest[0] = Math.atan2(-m23, m22);
                dest[1] = Math.atan2(-m31, m11);
            } else {
                dest[0] = 0;
                dest[1] = Math.atan2(m13, m33);
            }

        } else if (order === 'XZY') {

            dest[2] = Math.asin(-clamp(m12, -1, 1));

            if (Math.abs(m12) < 0.99999) {
                dest[0] = Math.atan2(m32, m22);
                dest[1] = Math.atan2(m13, m11);
            } else {
                dest[0] = Math.atan2(-m23, m33);
                dest[1] = 0;
            }
        }

        return dest;
    },

    composeMat4(position, quaternion, scale, mat = math.mat4()) {
        math.quaternionToRotationMat4(quaternion, mat);
        math.scaleMat4v(scale, mat);
        math.translateMat4v(position, mat);

        return mat;
    },

    decomposeMat4: (() => {

        const vec = new Float32Array(3);
        const matrix = new Float32Array(16);

        return function decompose(mat, position, quaternion, scale) {

            vec[0] = mat[0];
            vec[1] = mat[1];
            vec[2] = mat[2];

            let sx = math.lenVec3(vec);

            vec[0] = mat[4];
            vec[1] = mat[5];
            vec[2] = mat[6];

            const sy = math.lenVec3(vec);

            vec[8] = mat[8];
            vec[9] = mat[9];
            vec[10] = mat[10];

            const sz = math.lenVec3(vec);

            // if determine is negative, we need to invert one scale
            const det = math.determinantMat4(mat);

            if (det < 0) {
                sx = -sx;
            }

            position[0] = mat[12];
            position[1] = mat[13];
            position[2] = mat[14];

            // scale the rotation part
            matrix.set(mat);

            const invSX = 1 / sx;
            const invSY = 1 / sy;
            const invSZ = 1 / sz;

            matrix[0] *= invSX;
            matrix[1] *= invSX;
            matrix[2] *= invSX;

            matrix[4] *= invSY;
            matrix[5] *= invSY;
            matrix[6] *= invSY;

            matrix[8] *= invSZ;
            matrix[9] *= invSZ;
            matrix[10] *= invSZ;

            math.mat4ToQuaternion(matrix, quaternion);

            scale[0] = sx;
            scale[1] = sy;
            scale[2] = sz;

            return this;

        };

    })(),

    /**
     * Returns a 4x4 'lookat' viewing transform matrix.
     * @method lookAtMat4v
     * @param pos vec3 position of the viewer
     * @param target vec3 point the viewer is looking at
     * @param up vec3 pointing "up"
     * @param dest mat4 Optional, mat4 matrix will be written into
     *
     * @return {mat4} dest if specified, a new mat4 otherwise
     */
    lookAtMat4v(pos, target, up, dest) {
        if (!dest) {
            dest = math.mat4();
        }

        const posx = pos[0];
        const posy = pos[1];
        const posz = pos[2];
        const upx = up[0];
        const upy = up[1];
        const upz = up[2];
        const targetx = target[0];
        const targety = target[1];
        const targetz = target[2];

        if (posx === targetx && posy === targety && posz === targetz) {
            return math.identityMat4();
        }

        let z0;
        let z1;
        let z2;
        let x0;
        let x1;
        let x2;
        let y0;
        let y1;
        let y2;
        let len;

        //vec3.direction(eye, center, z);
        z0 = posx - targetx;
        z1 = posy - targety;
        z2 = posz - targetz;

        // normalize (no check needed for 0 because of early return)
        len = 1 / Math.sqrt(z0 * z0 + z1 * z1 + z2 * z2);
        z0 *= len;
        z1 *= len;
        z2 *= len;

        //vec3.normalize(vec3.cross(up, z, x));
        x0 = upy * z2 - upz * z1;
        x1 = upz * z0 - upx * z2;
        x2 = upx * z1 - upy * z0;
        len = Math.sqrt(x0 * x0 + x1 * x1 + x2 * x2);
        if (!len) {
            x0 = 0;
            x1 = 0;
            x2 = 0;
        } else {
            len = 1 / len;
            x0 *= len;
            x1 *= len;
            x2 *= len;
        }

        //vec3.normalize(vec3.cross(z, x, y));
        y0 = z1 * x2 - z2 * x1;
        y1 = z2 * x0 - z0 * x2;
        y2 = z0 * x1 - z1 * x0;

        len = Math.sqrt(y0 * y0 + y1 * y1 + y2 * y2);
        if (!len) {
            y0 = 0;
            y1 = 0;
            y2 = 0;
        } else {
            len = 1 / len;
            y0 *= len;
            y1 *= len;
            y2 *= len;
        }

        dest[0] = x0;
        dest[1] = y0;
        dest[2] = z0;
        dest[3] = 0;
        dest[4] = x1;
        dest[5] = y1;
        dest[6] = z1;
        dest[7] = 0;
        dest[8] = x2;
        dest[9] = y2;
        dest[10] = z2;
        dest[11] = 0;
        dest[12] = -(x0 * posx + x1 * posy + x2 * posz);
        dest[13] = -(y0 * posx + y1 * posy + y2 * posz);
        dest[14] = -(z0 * posx + z1 * posy + z2 * posz);
        dest[15] = 1;

        return dest;
    },

    /**
     * Returns a 4x4 'lookat' viewing transform matrix.
     * @method lookAtMat4c
     * @static
     */
    lookAtMat4c(posx, posy, posz, targetx, targety, targetz, upx, upy, upz) {
        return math.lookAtMat4v([posx, posy, posz], [targetx, targety, targetz], [upx, upy, upz], []);
    },

    /**
     * Returns a 4x4 orthographic projection matrix.
     * @method orthoMat4c
     * @static
     */
    orthoMat4c(left, right, bottom, top, near, far, dest) {
        if (!dest) {
            dest = math.mat4();
        }
        const rl = (right - left);
        const tb = (top - bottom);
        const fn = (far - near);

        dest[0] = 2.0 / rl;
        dest[1] = 0.0;
        dest[2] = 0.0;
        dest[3] = 0.0;

        dest[4] = 0.0;
        dest[5] = 2.0 / tb;
        dest[6] = 0.0;
        dest[7] = 0.0;

        dest[8] = 0.0;
        dest[9] = 0.0;
        dest[10] = -2.0 / fn;
        dest[11] = 0.0;

        dest[12] = -(left + right) / rl;
        dest[13] = -(top + bottom) / tb;
        dest[14] = -(far + near) / fn;
        dest[15] = 1.0;

        return dest;
    },

    /**
     * Returns a 4x4 perspective projection matrix.
     * @method frustumMat4v
     * @static
     */
    frustumMat4v(fmin, fmax, m) {
        if (!m) {
            m = math.mat4();
        }

        const fmin4 = [fmin[0], fmin[1], fmin[2], 0.0];
        const fmax4 = [fmax[0], fmax[1], fmax[2], 0.0];

        math.addVec4(fmax4, fmin4, tempMat1);
        math.subVec4(fmax4, fmin4, tempMat2);

        const t = 2.0 * fmin4[2];

        const tempMat20 = tempMat2[0];
        const tempMat21 = tempMat2[1];
        const tempMat22 = tempMat2[2];

        m[0] = t / tempMat20;
        m[1] = 0.0;
        m[2] = 0.0;
        m[3] = 0.0;

        m[4] = 0.0;
        m[5] = t / tempMat21;
        m[6] = 0.0;
        m[7] = 0.0;

        m[8] = tempMat1[0] / tempMat20;
        m[9] = tempMat1[1] / tempMat21;
        m[10] = -tempMat1[2] / tempMat22;
        m[11] = -1.0;

        m[12] = 0.0;
        m[13] = 0.0;
        m[14] = -t * fmax4[2] / tempMat22;
        m[15] = 0.0;

        return m;
    },

    /**
     * Returns a 4x4 perspective projection matrix.
     * @method frustumMat4v
     * @static
     */
    frustumMat4(left, right, bottom, top, near, far, dest) {
        if (!dest) {
            dest = math.mat4();
        }
        const rl = (right - left);
        const tb = (top - bottom);
        const fn = (far - near);
        dest[0] = (near * 2) / rl;
        dest[1] = 0;
        dest[2] = 0;
        dest[3] = 0;
        dest[4] = 0;
        dest[5] = (near * 2) / tb;
        dest[6] = 0;
        dest[7] = 0;
        dest[8] = (right + left) / rl;
        dest[9] = (top + bottom) / tb;
        dest[10] = -(far + near) / fn;
        dest[11] = -1;
        dest[12] = 0;
        dest[13] = 0;
        dest[14] = -(far * near * 2) / fn;
        dest[15] = 0;
        return dest;
    },

    /**
     * Returns a 4x4 perspective projection matrix.
     * @method perspectiveMat4v
     * @static
     */
    perspectiveMat4(fovyrad, aspectratio, znear, zfar, m) {
        const pmin = [];
        const pmax = [];

        pmin[2] = znear;
        pmax[2] = zfar;

        pmax[1] = pmin[2] * Math.tan(fovyrad / 2.0);
        pmin[1] = -pmax[1];

        pmax[0] = pmax[1] * aspectratio;
        pmin[0] = -pmax[0];

        return math.frustumMat4v(pmin, pmax, m);
    },

    /**
     * Transforms a three-element position by a 4x4 matrix.
     * @method transformPoint3
     * @static
     */
    transformPoint3(m, p, dest = math.vec3()) {

        const x = p[0];
        const y = p[1];
        const z = p[2];

        dest[0] = (m[0] * x) + (m[4] * y) + (m[8] * z) + m[12];
        dest[1] = (m[1] * x) + (m[5] * y) + (m[9] * z) + m[13];
        dest[2] = (m[2] * x) + (m[6] * y) + (m[10] * z) + m[14];

        return dest;
    },

    /**
     * Transforms a homogeneous coordinate by a 4x4 matrix.
     * @method transformPoint3
     * @static
     */
    transformPoint4(m, v, dest = math.vec4()) {
        dest[0] = m[0] * v[0] + m[4] * v[1] + m[8] * v[2] + m[12] * v[3];
        dest[1] = m[1] * v[0] + m[5] * v[1] + m[9] * v[2] + m[13] * v[3];
        dest[2] = m[2] * v[0] + m[6] * v[1] + m[10] * v[2] + m[14] * v[3];
        dest[3] = m[3] * v[0] + m[7] * v[1] + m[11] * v[2] + m[15] * v[3];

        return dest;
    },


    /**
     * Transforms an array of three-element positions by a 4x4 matrix.
     * @method transformPoints3
     * @static
     */
    transformPoints3(m, points, points2) {
        const result = points2 || [];
        const len = points.length;
        let p0;
        let p1;
        let p2;
        let pi;

        // cache values
        const m0 = m[0];

        const m1 = m[1];
        const m2 = m[2];
        const m3 = m[3];
        const m4 = m[4];
        const m5 = m[5];
        const m6 = m[6];
        const m7 = m[7];
        const m8 = m[8];
        const m9 = m[9];
        const m10 = m[10];
        const m11 = m[11];
        const m12 = m[12];
        const m13 = m[13];
        const m14 = m[14];
        const m15 = m[15];

        let r;

        for (let i = 0; i < len; ++i) {

            // cache values
            pi = points[i];

            p0 = pi[0];
            p1 = pi[1];
            p2 = pi[2];

            r = result[i] || (result[i] = [0, 0, 0]);

            r[0] = (m0 * p0) + (m4 * p1) + (m8 * p2) + m12;
            r[1] = (m1 * p0) + (m5 * p1) + (m9 * p2) + m13;
            r[2] = (m2 * p0) + (m6 * p1) + (m10 * p2) + m14;
            r[3] = (m3 * p0) + (m7 * p1) + (m11 * p2) + m15;
        }

        result.length = len;

        return result;
    },

    /**
     * Transforms an array of positions by a 4x4 matrix.
     * @method transformPositions3
     * @static
     */
    transformPositions3(m, p, p2 = p) {
        let i;
        const len = p.length;

        let x;
        let y;
        let z;

        const m0 = m[0];
        const m1 = m[1];
        const m2 = m[2];
        const m3 = m[3];
        const m4 = m[4];
        const m5 = m[5];
        const m6 = m[6];
        const m7 = m[7];
        const m8 = m[8];
        const m9 = m[9];
        const m10 = m[10];
        const m11 = m[11];
        const m12 = m[12];
        const m13 = m[13];
        const m14 = m[14];
        const m15 = m[15];

        for (i = 0; i < len; i += 3) {

            x = p[i + 0];
            y = p[i + 1];
            z = p[i + 2];

            p2[i + 0] = (m0 * x) + (m4 * y) + (m8 * z) + m12;
            p2[i + 1] = (m1 * x) + (m5 * y) + (m9 * z) + m13;
            p2[i + 2] = (m2 * x) + (m6 * y) + (m10 * z) + m14;
            p2[i + 3] = (m3 * x) + (m7 * y) + (m11 * z) + m15;
        }

        return p2;
    },

    /**
     * Transforms an array of positions by a 4x4 matrix.
     * @method transformPositions4
     * @static
     */
    transformPositions4(m, p, p2 = p) {
        let i;
        const len = p.length;

        let x;
        let y;
        let z;

        const m0 = m[0];
        const m1 = m[1];
        const m2 = m[2];
        const m3 = m[3];
        const m4 = m[4];
        const m5 = m[5];
        const m6 = m[6];
        const m7 = m[7];
        const m8 = m[8];
        const m9 = m[9];
        const m10 = m[10];
        const m11 = m[11];
        const m12 = m[12];
        const m13 = m[13];
        const m14 = m[14];
        const m15 = m[15];

        for (i = 0; i < len; i += 4) {

            x = p[i + 0];
            y = p[i + 1];
            z = p[i + 2];

            p2[i + 0] = (m0 * x) + (m4 * y) + (m8 * z) + m12;
            p2[i + 1] = (m1 * x) + (m5 * y) + (m9 * z) + m13;
            p2[i + 2] = (m2 * x) + (m6 * y) + (m10 * z) + m14;
            p2[i + 3] = (m3 * x) + (m7 * y) + (m11 * z) + m15;
        }

        return p2;
    },

    /**
     * Transforms a three-element vector by a 4x4 matrix.
     * @method transformVec3
     * @static
     */
    transformVec3(m, v, dest) {
        const v0 = v[0];
        const v1 = v[1];
        const v2 = v[2];
        dest = dest || this.vec3();
        dest[0] = (m[0] * v0) + (m[4] * v1) + (m[8] * v2);
        dest[1] = (m[1] * v0) + (m[5] * v1) + (m[9] * v2);
        dest[2] = (m[2] * v0) + (m[6] * v1) + (m[10] * v2);
        return dest;
    },

    /**
     * Transforms a four-element vector by a 4x4 matrix.
     * @method transformVec4
     * @static
     */
    transformVec4(m, v, dest) {
        const v0 = v[0];
        const v1 = v[1];
        const v2 = v[2];
        const v3 = v[3];
        dest = dest || math.vec4();
        dest[0] = m[0] * v0 + m[4] * v1 + m[8] * v2 + m[12] * v3;
        dest[1] = m[1] * v0 + m[5] * v1 + m[9] * v2 + m[13] * v3;
        dest[2] = m[2] * v0 + m[6] * v1 + m[10] * v2 + m[14] * v3;
        dest[3] = m[3] * v0 + m[7] * v1 + m[11] * v2 + m[15] * v3;
        return dest;
    },

    /**
     * Rotate a 3D vector around the x-axis
     *
     * @method rotateVec3X
     * @param {Number[]} a The vec3 point to rotate
     * @param {Number[]} b The origin of the rotation
     * @param {Number} c The angle of rotation
     * @param {Number[]} dest The receiving vec3
     * @returns {Number[]} dest
     * @static
     */
    rotateVec3X(a, b, c, dest) {
        const p = [];
        const r = [];

        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[0];
        r[1] = p[1] * Math.cos(c) - p[2] * Math.sin(c);
        r[2] = p[1] * Math.sin(c) + p[2] * Math.cos(c);

        //translate to correct position
        dest[0] = r[0] + b[0];
        dest[1] = r[1] + b[1];
        dest[2] = r[2] + b[2];

        return dest;
    },

    /**
     * Rotate a 3D vector around the y-axis
     *
     * @method rotateVec3Y
     * @param {Number[]} a The vec3 point to rotate
     * @param {Number[]} b The origin of the rotation
     * @param {Number} c The angle of rotation
     * @param {Number[]} dest The receiving vec3
     * @returns {Number[]} dest
     * @static
     */
    rotateVec3Y(a, b, c, dest) {
        const p = [];
        const r = [];

        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[2] * Math.sin(c) + p[0] * Math.cos(c);
        r[1] = p[1];
        r[2] = p[2] * Math.cos(c) - p[0] * Math.sin(c);

        //translate to correct position
        dest[0] = r[0] + b[0];
        dest[1] = r[1] + b[1];
        dest[2] = r[2] + b[2];

        return dest;
    },

    /**
     * Rotate a 3D vector around the z-axis
     *
     * @method rotateVec3Z
     * @param {Number[]} a The vec3 point to rotate
     * @param {Number[]} b The origin of the rotation
     * @param {Number} c The angle of rotation
     * @param {Number[]} dest The receiving vec3
     * @returns {Number[]} dest
     * @static
     */
    rotateVec3Z(a, b, c, dest) {
        const p = [];
        const r = [];

        //Translate point to the origin
        p[0] = a[0] - b[0];
        p[1] = a[1] - b[1];
        p[2] = a[2] - b[2];

        //perform rotation
        r[0] = p[0] * Math.cos(c) - p[1] * Math.sin(c);
        r[1] = p[0] * Math.sin(c) + p[1] * Math.cos(c);
        r[2] = p[2];

        //translate to correct position
        dest[0] = r[0] + b[0];
        dest[1] = r[1] + b[1];
        dest[2] = r[2] + b[2];

        return dest;
    },

    /**
     * Transforms a four-element vector by a 4x4 projection matrix.
     *
     * @method projectVec4
     * @param {Number[]} p 3D View-space coordinate
     * @param {Number[]} q 2D Projected coordinate
     * @returns {Number[]} 2D Projected coordinate
     * @static
     */
    projectVec4(p, q) {
        const f = 1.0 / p[3];
        q = q || math.vec2();
        q[0] = p[0] * f;
        q[1] = p[1] * f;
        return q;
    },

    /**
     * Unprojects a three-element vector.
     *
     * @method unprojectVec3
     * @param {Number[]} p 3D Projected coordinate
     * @param {Number[]} viewMat View matrix
     * @returns {Number[]} projMat Projection matrix
     * @static
     */
    unprojectVec3: ((() => {
        const mat = new Float32Array(16);
        const mat2 = new Float32Array(16);
        const mat3 = new Float32Array(16);
        return function (p, viewMat, projMat, q) {
            return this.transformVec3(this.mulMat4(this.inverseMat4(viewMat, mat), this.inverseMat4(projMat, mat2), mat3), p, q)
        };
    }))(),

    /**
     * Linearly interpolates between two 3D vectors.
     * @method lerpVec3
     * @static
     */
    lerpVec3(t, t1, t2, p1, p2, dest) {
        const result = dest || math.vec3();
        const f = (t - t1) / (t2 - t1);
        result[0] = p1[0] + (f * (p2[0] - p1[0]));
        result[1] = p1[1] + (f * (p2[1] - p1[1]));
        result[2] = p1[2] + (f * (p2[2] - p1[2]));
        return result;
    },

    /**
     * Linearly interpolates between two 4x4 matrices.
     * @method lerpMat4
     * @static
     */
    lerpMat4(t, t1, t2, m1, m2, dest) {
        const result = dest || math.mat4();
        const f = (t - t1) / (t2 - t1);
        result[0] = m1[0] + (f * (m2[0] - m1[0]));
        result[1] = m1[1] + (f * (m2[1] - m1[1]));
        result[2] = m1[2] + (f * (m2[2] - m1[2]));
        result[3] = m1[3] + (f * (m2[3] - m1[3]));
        result[4] = m1[4] + (f * (m2[4] - m1[4]));
        result[5] = m1[5] + (f * (m2[5] - m1[5]));
        result[6] = m1[6] + (f * (m2[6] - m1[6]));
        result[7] = m1[7] + (f * (m2[7] - m1[7]));
        result[8] = m1[8] + (f * (m2[8] - m1[8]));
        result[9] = m1[9] + (f * (m2[9] - m1[9]));
        result[10] = m1[10] + (f * (m2[10] - m1[10]));
        result[11] = m1[11] + (f * (m2[11] - m1[11]));
        result[12] = m1[12] + (f * (m2[12] - m1[12]));
        result[13] = m1[13] + (f * (m2[13] - m1[13]));
        result[14] = m1[14] + (f * (m2[14] - m1[14]));
        result[15] = m1[15] + (f * (m2[15] - m1[15]));
        return result;
    },


    /**
     * Flattens a two-dimensional array into a one-dimensional array.
     *
     * @method flatten
     * @static
     * @param {Array of Arrays} a A 2D array
     * @returns Flattened 1D array
     */
    flatten(a) {

        const result = [];

        let i;
        let leni;
        let j;
        let lenj;
        let item;

        for (i = 0, leni = a.length; i < leni; i++) {
            item = a[i];
            for (j = 0, lenj = item.length; j < lenj; j++) {
                result.push(item[j]);
            }
        }

        return result;
    },


    identityQuaternion(dest = math.vec4()) {
        dest[0] = 0.0;
        dest[1] = 0.0;
        dest[2] = 0.0;
        dest[3] = 1.0;
        return dest;
    },

    /**
     * Initializes a quaternion from Euler angles.
     *
     * @param {Number[]} euler The Euler angles.
     * @param {String} order Euler angle order: "XYZ", "YXZ", "ZXY" etc.
     * @param {Number[]} [dest] Destination quaternion, created by default.
     * @returns {Number[]} The quaternion.
     */
    eulerToQuaternion(euler, order, dest = math.vec4()) {
        // http://www.mathworks.com/matlabcentral/fileexchange/
        // 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
        //	content/SpinCalc.m

        const a = (euler[0] * math.DEGTORAD) / 2;
        const b = (euler[1] * math.DEGTORAD) / 2;
        const c = (euler[2] * math.DEGTORAD) / 2;

        const c1 = Math.cos(a);
        const c2 = Math.cos(b);
        const c3 = Math.cos(c);
        const s1 = Math.sin(a);
        const s2 = Math.sin(b);
        const s3 = Math.sin(c);

        if (order === 'XYZ') {

            dest[0] = s1 * c2 * c3 + c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 - s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 + s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 - s1 * s2 * s3;

        } else if (order === 'YXZ') {

            dest[0] = s1 * c2 * c3 + c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 - s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 - s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 + s1 * s2 * s3;

        } else if (order === 'ZXY') {

            dest[0] = s1 * c2 * c3 - c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 + s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 + s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 - s1 * s2 * s3;

        } else if (order === 'ZYX') {

            dest[0] = s1 * c2 * c3 - c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 + s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 - s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 + s1 * s2 * s3;

        } else if (order === 'YZX') {

            dest[0] = s1 * c2 * c3 + c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 + s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 - s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 - s1 * s2 * s3;

        } else if (order === 'XZY') {

            dest[0] = s1 * c2 * c3 - c1 * s2 * s3;
            dest[1] = c1 * s2 * c3 - s1 * c2 * s3;
            dest[2] = c1 * c2 * s3 + s1 * s2 * c3;
            dest[3] = c1 * c2 * c3 + s1 * s2 * s3;
        }

        return dest;
    },

    mat4ToQuaternion(m, dest = math.vec4()) {
        // http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm

        // Assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

        const m11 = m[0];
        const m12 = m[4];
        const m13 = m[8];
        const m21 = m[1];
        const m22 = m[5];
        const m23 = m[9];
        const m31 = m[2];
        const m32 = m[6];
        const m33 = m[10];
        let s;

        const trace = m11 + m22 + m33;

        if (trace > 0) {

            s = 0.5 / Math.sqrt(trace + 1.0);

            dest[3] = 0.25 / s;
            dest[0] = (m32 - m23) * s;
            dest[1] = (m13 - m31) * s;
            dest[2] = (m21 - m12) * s;

        } else if (m11 > m22 && m11 > m33) {

            s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);

            dest[3] = (m32 - m23) / s;
            dest[0] = 0.25 * s;
            dest[1] = (m12 + m21) / s;
            dest[2] = (m13 + m31) / s;

        } else if (m22 > m33) {

            s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);

            dest[3] = (m13 - m31) / s;
            dest[0] = (m12 + m21) / s;
            dest[1] = 0.25 * s;
            dest[2] = (m23 + m32) / s;

        } else {

            s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);

            dest[3] = (m21 - m12) / s;
            dest[0] = (m13 + m31) / s;
            dest[1] = (m23 + m32) / s;
            dest[2] = 0.25 * s;
        }

        return dest;
    },

    vec3PairToQuaternion(u, v, dest = math.vec4()) {
        const norm_u_norm_v = Math.sqrt(math.dotVec3(u, u) * math.dotVec3(v, v));
        let real_part = norm_u_norm_v + math.dotVec3(u, v);

        if (real_part < 0.00000001 * norm_u_norm_v) {

            // If u and v are exactly opposite, rotate 180 degrees
            // around an arbitrary orthogonal axis. Axis normalisation
            // can happen later, when we normalise the quaternion.

            real_part = 0.0;

            if (Math.abs(u[0]) > Math.abs(u[2])) {

                dest[0] = -u[1];
                dest[1] = u[0];
                dest[2] = 0;

            } else {
                dest[0] = 0;
                dest[1] = -u[2];
                dest[2] = u[1]
            }

        } else {

            // Otherwise, build quaternion the standard way.
            math.cross3Vec3(u, v, dest);
        }

        dest[3] = real_part;

        return math.normalizeQuaternion(dest);
    },

    angleAxisToQuaternion(angleAxis, dest = math.vec4()) {
        const halfAngle = angleAxis[3] / 2.0;
        const fsin = Math.sin(halfAngle);
        dest[0] = fsin * angleAxis[0];
        dest[1] = fsin * angleAxis[1];
        dest[2] = fsin * angleAxis[2];
        dest[3] = Math.cos(halfAngle);
        return dest;
    },

    quaternionToEuler: ((() => {
        const mat = new Float32Array(16);
        return (q, order, dest) => {
            dest = dest || math.vec3();
            math.quaternionToRotationMat4(q, mat);
            math.mat4ToEuler(mat, order, dest);
            return dest;
        };
    }))(),

    mulQuaternions(p, q, dest = math.vec4()) {
        const p0 = p[0];
        const p1 = p[1];
        const p2 = p[2];
        const p3 = p[3];
        const q0 = q[0];
        const q1 = q[1];
        const q2 = q[2];
        const q3 = q[3];
        dest[0] = p3 * q0 + p0 * q3 + p1 * q2 - p2 * q1;
        dest[1] = p3 * q1 + p1 * q3 + p2 * q0 - p0 * q2;
        dest[2] = p3 * q2 + p2 * q3 + p0 * q1 - p1 * q0;
        dest[3] = p3 * q3 - p0 * q0 - p1 * q1 - p2 * q2;
        return dest;
    },

    vec3ApplyQuaternion(q, vec, dest = math.vec3()) {
        const x = vec[0];
        const y = vec[1];
        const z = vec[2];

        const qx = q[0];
        const qy = q[1];
        const qz = q[2];
        const qw = q[3];

        // calculate quat * vector

        const ix = qw * x + qy * z - qz * y;
        const iy = qw * y + qz * x - qx * z;
        const iz = qw * z + qx * y - qy * x;
        const iw = -qx * x - qy * y - qz * z;

        // calculate result * inverse quat

        dest[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        dest[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        dest[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;

        return dest;
    },

    quaternionToMat4(q, dest) {

        dest = math.identityMat4(dest);

        const q0 = q[0];  //x
        const q1 = q[1];  //y
        const q2 = q[2];  //z
        const q3 = q[3];  //w

        const tx = 2.0 * q0;
        const ty = 2.0 * q1;
        const tz = 2.0 * q2;

        const twx = tx * q3;
        const twy = ty * q3;
        const twz = tz * q3;

        const txx = tx * q0;
        const txy = ty * q0;
        const txz = tz * q0;

        const tyy = ty * q1;
        const tyz = tz * q1;
        const tzz = tz * q2;

        dest[0] = 1.0 - (tyy + tzz);
        dest[1] = txy + twz;
        dest[2] = txz - twy;

        dest[4] = txy - twz;
        dest[5] = 1.0 - (txx + tzz);
        dest[6] = tyz + twx;

        dest[8] = txz + twy;
        dest[9] = tyz - twx;

        dest[10] = 1.0 - (txx + tyy);

        return dest;
    },

    quaternionToRotationMat4(q, m) {
        const x = q[0];
        const y = q[1];
        const z = q[2];
        const w = q[3];

        const x2 = x + x;
        const y2 = y + y;
        const z2 = z + z;
        const xx = x * x2;
        const xy = x * y2;
        const xz = x * z2;
        const yy = y * y2;
        const yz = y * z2;
        const zz = z * z2;
        const wx = w * x2;
        const wy = w * y2;
        const wz = w * z2;

        m[0] = 1 - (yy + zz);
        m[4] = xy - wz;
        m[8] = xz + wy;

        m[1] = xy + wz;
        m[5] = 1 - (xx + zz);
        m[9] = yz - wx;

        m[2] = xz - wy;
        m[6] = yz + wx;
        m[10] = 1 - (xx + yy);

        // last column
        m[3] = 0;
        m[7] = 0;
        m[11] = 0;

        // bottom row
        m[12] = 0;
        m[13] = 0;
        m[14] = 0;
        m[15] = 1;

        return m;
    },

    normalizeQuaternion(q, dest = q) {
        const len = math.lenVec4([q[0], q[1], q[2], q[3]]);
        dest[0] = q[0] / len;
        dest[1] = q[1] / len;
        dest[2] = q[2] / len;
        dest[3] = q[3] / len;
        return dest;
    },

    conjugateQuaternion(q, dest = q) {
        dest[0] = -q[0];
        dest[1] = -q[1];
        dest[2] = -q[2];
        dest[3] = q[3];
        return dest;
    },

    inverseQuaternion(q, dest) {
        return math.normalizeQuaternion(math.conjugateQuaternion(q, dest));
    },

    quaternionToAngleAxis(q, angleAxis = math.vec4()) {
        q = math.normalizeQuaternion(q, tempVec4);
        const q3 = q[3];
        const angle = 2 * Math.acos(q3);
        const s = Math.sqrt(1 - q3 * q3);
        if (s < 0.001) { // test to avoid divide by zero, s is always positive due to sqrt
            angleAxis[0] = q[0];
            angleAxis[1] = q[1];
            angleAxis[2] = q[2];
        } else {
            angleAxis[0] = q[0] / s;
            angleAxis[1] = q[1] / s;
            angleAxis[2] = q[2] / s;
        }
        angleAxis[3] = angle; // * 57.295779579;
        return angleAxis;
    },

    //------------------------------------------------------------------------------------------------------------------
    // Boundaries
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Returns a new, uninitialized 3D axis-aligned bounding box.
     *
     * @private
     */
    AABB3(values) {
        return new Float32Array(values || 6);
    },

    /**
     * Returns a new, uninitialized 2D axis-aligned bounding box.
     *
     * @private
     */
    AABB2(values) {
        return new Float32Array(values || 4);
    },

    /**
     * Returns a new, uninitialized 3D oriented bounding box (OBB).
     *
     * @private
     */
    OBB3(values) {
        return new Float32Array(values || 32);
    },

    /**
     * Returns a new, uninitialized 2D oriented bounding box (OBB).
     *
     * @private
     */
    OBB2(values) {
        return new Float32Array(values || 16);
    },

    /** Returns a new 3D bounding sphere */
    Sphere3(x, y, z, r) {
        return new Float32Array([x, y, z, r]);
    },

    /**
     * Transforms an OBB3 by a 4x4 matrix.
     *
     * @private
     */
    transformOBB3(m, p, p2 = p) {
        let i;
        const len = p.length;

        let x;
        let y;
        let z;

        const m0 = m[0];
        const m1 = m[1];
        const m2 = m[2];
        const m3 = m[3];
        const m4 = m[4];
        const m5 = m[5];
        const m6 = m[6];
        const m7 = m[7];
        const m8 = m[8];
        const m9 = m[9];
        const m10 = m[10];
        const m11 = m[11];
        const m12 = m[12];
        const m13 = m[13];
        const m14 = m[14];
        const m15 = m[15];

        for (i = 0; i < len; i += 4) {

            x = p[i + 0];
            y = p[i + 1];
            z = p[i + 2];

            p2[i + 0] = (m0 * x) + (m4 * y) + (m8 * z) + m12;
            p2[i + 1] = (m1 * x) + (m5 * y) + (m9 * z) + m13;
            p2[i + 2] = (m2 * x) + (m6 * y) + (m10 * z) + m14;
            p2[i + 3] = (m3 * x) + (m7 * y) + (m11 * z) + m15;
        }

        return p2;
    },

    /**
     * Gets the diagonal size of an AABB3 given as minima and maxima.
     *
     * @private
     */
    getAABB3Diag: ((() => {

        const min = new Float32Array(3);
        const max = new Float32Array(3);
        const tempVec3 = new Float32Array(3);

        return aabb => {

            min[0] = aabb[0];
            min[1] = aabb[1];
            min[2] = aabb[2];

            max[0] = aabb[3];
            max[1] = aabb[4];
            max[2] = aabb[5];

            math.subVec3(max, min, tempVec3);

            return Math.abs(math.lenVec3(tempVec3));
        };
    }))(),

    /**
     * Get a diagonal boundary size that is symmetrical about the given point.
     *
     * @private
     */
    getAABB3DiagPoint: ((() => {

        const min = new Float32Array(3);
        const max = new Float32Array(3);
        const tempVec3 = new Float32Array(3);

        return (aabb, p) => {

            min[0] = aabb[0];
            min[1] = aabb[1];
            min[2] = aabb[2];

            max[0] = aabb[3];
            max[1] = aabb[4];
            max[2] = aabb[5];

            const diagVec = math.subVec3(max, min, tempVec3);

            const xneg = p[0] - aabb[0];
            const xpos = aabb[3] - p[0];
            const yneg = p[1] - aabb[1];
            const ypos = aabb[4] - p[1];
            const zneg = p[2] - aabb[2];
            const zpos = aabb[5] - p[2];

            diagVec[0] += (xneg > xpos) ? xneg : xpos;
            diagVec[1] += (yneg > ypos) ? yneg : ypos;
            diagVec[2] += (zneg > zpos) ? zneg : zpos;

            return Math.abs(math.lenVec3(diagVec));
        };
    }))(),

    /**
     * Gets the center of an AABB.
     *
     * @private
     */
    getAABB3Center(aabb, dest) {
        const r = dest || math.vec3();

        r[0] = (aabb[0] + aabb[3]) / 2;
        r[1] = (aabb[1] + aabb[4]) / 2;
        r[2] = (aabb[2] + aabb[5]) / 2;

        return r;
    },

    /**
     * Gets the center of a 2D AABB.
     *
     * @private
     */
    getAABB2Center(aabb, dest) {
        const r = dest || math.vec2();

        r[0] = (aabb[2] + aabb[0]) / 2;
        r[1] = (aabb[3] + aabb[1]) / 2;

        return r;
    },

    /**
     * Collapses a 3D axis-aligned boundary, ready to expand to fit 3D points.
     * Creates new AABB if none supplied.
     *
     * @private
     */
    collapseAABB3(aabb = math.AABB3()) {
        aabb[0] = math.MAX_DOUBLE;
        aabb[1] = math.MAX_DOUBLE;
        aabb[2] = math.MAX_DOUBLE;
        aabb[3] = -math.MAX_DOUBLE;
        aabb[4] = -math.MAX_DOUBLE;
        aabb[5] = -math.MAX_DOUBLE;

        return aabb;
    },

    /**
     * Converts an axis-aligned 3D boundary into an oriented boundary consisting of
     * an array of eight 3D positions, one for each corner of the boundary.
     *
     * @private
     */
    AABB3ToOBB3(aabb, obb = math.OBB3()) {
        obb[0] = aabb[0];
        obb[1] = aabb[1];
        obb[2] = aabb[2];
        obb[3] = 1;

        obb[4] = aabb[3];
        obb[5] = aabb[1];
        obb[6] = aabb[2];
        obb[7] = 1;

        obb[8] = aabb[3];
        obb[9] = aabb[4];
        obb[10] = aabb[2];
        obb[11] = 1;

        obb[12] = aabb[0];
        obb[13] = aabb[4];
        obb[14] = aabb[2];
        obb[15] = 1;

        obb[16] = aabb[0];
        obb[17] = aabb[1];
        obb[18] = aabb[5];
        obb[19] = 1;

        obb[20] = aabb[3];
        obb[21] = aabb[1];
        obb[22] = aabb[5];
        obb[23] = 1;

        obb[24] = aabb[3];
        obb[25] = aabb[4];
        obb[26] = aabb[5];
        obb[27] = 1;

        obb[28] = aabb[0];
        obb[29] = aabb[4];
        obb[30] = aabb[5];
        obb[31] = 1;

        return obb;
    },

    /**
     * Finds the minimum axis-aligned 3D boundary enclosing the homogeneous 3D points (x,y,z,w) given in a flattened array.
     *
     * @private
     */
    positions3ToAABB3: ((() => {

        const p = new Float32Array(3);

        return (positions, aabb, positionsDecodeMatrix) => {
            aabb = aabb || math.AABB3();

            let xmin = math.MAX_DOUBLE;
            let ymin = math.MAX_DOUBLE;
            let zmin = math.MAX_DOUBLE;
            let xmax = -math.MAX_DOUBLE;
            let ymax = -math.MAX_DOUBLE;
            let zmax = -math.MAX_DOUBLE;

            let x;
            let y;
            let z;

            for (let i = 0, len = positions.length; i < len; i += 3) {

                if (positionsDecodeMatrix) {

                    p[0] = positions[i + 0];
                    p[1] = positions[i + 1];
                    p[2] = positions[i + 2];

                    math.decompressPosition(p, positionsDecodeMatrix, p);

                    x = p[0];
                    y = p[1];
                    z = p[2];

                } else {
                    x = positions[i + 0];
                    y = positions[i + 1];
                    z = positions[i + 2];
                }

                if (x < xmin) {
                    xmin = x;
                }

                if (y < ymin) {
                    ymin = y;
                }

                if (z < zmin) {
                    zmin = z;
                }

                if (x > xmax) {
                    xmax = x;
                }

                if (y > ymax) {
                    ymax = y;
                }

                if (z > zmax) {
                    zmax = z;
                }
            }

            aabb[0] = xmin;
            aabb[1] = ymin;
            aabb[2] = zmin;
            aabb[3] = xmax;
            aabb[4] = ymax;
            aabb[5] = zmax;

            return aabb;
        };
    }))(),

    /**
     * Finds the minimum axis-aligned 3D boundary enclosing the homogeneous 3D points (x,y,z,w) given in a flattened array.
     *
     * @private
     */
    OBB3ToAABB3(obb, aabb = math.AABB3()) {
        let xmin = math.MAX_DOUBLE;
        let ymin = math.MAX_DOUBLE;
        let zmin = math.MAX_DOUBLE;
        let xmax = -math.MAX_DOUBLE;
        let ymax = -math.MAX_DOUBLE;
        let zmax = -math.MAX_DOUBLE;

        let x;
        let y;
        let z;

        for (let i = 0, len = obb.length; i < len; i += 4) {

            x = obb[i + 0];
            y = obb[i + 1];
            z = obb[i + 2];

            if (x < xmin) {
                xmin = x;
            }

            if (y < ymin) {
                ymin = y;
            }

            if (z < zmin) {
                zmin = z;
            }

            if (x > xmax) {
                xmax = x;
            }

            if (y > ymax) {
                ymax = y;
            }

            if (z > zmax) {
                zmax = z;
            }
        }

        aabb[0] = xmin;
        aabb[1] = ymin;
        aabb[2] = zmin;
        aabb[3] = xmax;
        aabb[4] = ymax;
        aabb[5] = zmax;

        return aabb;
    },

    /**
     * Finds the minimum axis-aligned 3D boundary enclosing the given 3D points.
     *
     * @private
     */
    points3ToAABB3(points, aabb = math.AABB3()) {
        let xmin = math.MAX_DOUBLE;
        let ymin = math.MAX_DOUBLE;
        let zmin = math.MAX_DOUBLE;
        let xmax = -math.MAX_DOUBLE;
        let ymax = -math.MAX_DOUBLE;
        let zmax = -math.MAX_DOUBLE;

        let x;
        let y;
        let z;

        for (let i = 0, len = points.length; i < len; i++) {

            x = points[i][0];
            y = points[i][1];
            z = points[i][2];

            if (x < xmin) {
                xmin = x;
            }

            if (y < ymin) {
                ymin = y;
            }

            if (z < zmin) {
                zmin = z;
            }

            if (x > xmax) {
                xmax = x;
            }

            if (y > ymax) {
                ymax = y;
            }

            if (z > zmax) {
                zmax = z;
            }
        }

        aabb[0] = xmin;
        aabb[1] = ymin;
        aabb[2] = zmin;
        aabb[3] = xmax;
        aabb[4] = ymax;
        aabb[5] = zmax;

        return aabb;
    },

    /**
     * Finds the minimum boundary sphere enclosing the given 3D points.
     *
     * @private
     */
    points3ToSphere3: ((() => {

        const tempVec3 = new Float32Array(3);

        return (points, sphere) => {

            sphere = sphere || math.vec4();

            let x = 0;
            let y = 0;
            let z = 0;

            let i;
            const numPoints = points.length;

            for (i = 0; i < numPoints; i++) {
                x += points[i][0];
                y += points[i][1];
                z += points[i][2];
            }

            sphere[0] = x / numPoints;
            sphere[1] = y / numPoints;
            sphere[2] = z / numPoints;

            let radius = 0;
            let dist;

            for (i = 0; i < numPoints; i++) {

                dist = Math.abs(math.lenVec3(math.subVec3(points[i], sphere, tempVec3)));

                if (dist > radius) {
                    radius = dist;
                }
            }

            sphere[3] = radius;

            return sphere;
        };
    }))(),

    /**
     * Finds the minimum boundary sphere enclosing the given 3D positions.
     *
     * @private
     */
    positions3ToSphere3: ((() => {

        const tempVec3a = new Float32Array(3);
        const tempVec3b = new Float32Array(3);

        return (positions, sphere) => {

            sphere = sphere || math.vec4();

            let x = 0;
            let y = 0;
            let z = 0;

            let i;
            const lenPositions = positions.length;
            let radius = 0;

            for (i = 0; i < lenPositions; i += 3) {
                x += positions[i];
                y += positions[i + 1];
                z += positions[i + 2];
            }

            const numPositions = lenPositions / 3;

            sphere[0] = x / numPositions;
            sphere[1] = y / numPositions;
            sphere[2] = z / numPositions;

            let dist;

            for (i = 0; i < lenPositions; i += 3) {

                tempVec3a[0] = positions[i];
                tempVec3a[1] = positions[i+1];
                tempVec3a[2] = positions[i+2];

                dist = Math.abs(math.lenVec3(math.subVec3(tempVec3a, sphere, tempVec3b)));

                if (dist > radius) {
                    radius = dist;
                }
            }

            sphere[3] = radius;

            return sphere;
        };
    }))(),

    /**
     * Finds the minimum boundary sphere enclosing the given 3D points.
     *
     * @private
     */
    OBB3ToSphere3: ((() => {

        const point = new Float32Array(3);
        const tempVec3 = new Float32Array(3);

        return (points, sphere) => {

            sphere = sphere || math.vec4();

            let x = 0;
            let y = 0;
            let z = 0;

            let i;
            const lenPoints = points.length;
            const numPoints = lenPoints / 4;

            for (i = 0; i < lenPoints; i += 4) {
                x += points[i + 0];
                y += points[i + 1];
                z += points[i + 2];
            }

            sphere[0] = x / numPoints;
            sphere[1] = y / numPoints;
            sphere[2] = z / numPoints;

            let radius = 0;
            let dist;

            for (i = 0; i < lenPoints; i += 4) {

                point[0] = points[i + 0];
                point[1] = points[i + 1];
                point[2] = points[i + 2];

                dist = Math.abs(math.lenVec3(math.subVec3(point, sphere, tempVec3)));

                if (dist > radius) {
                    radius = dist;
                }
            }

            sphere[3] = radius;

            return sphere;
        };
    }))(),

    /**
     * Gets the center of a bounding sphere.
     *
     * @private
     */
    getSphere3Center(sphere, dest = math.vec3()) {
        dest[0] = sphere[0];
        dest[1] = sphere[1];
        dest[2] = sphere[2];

        return dest;
    },

    /**
     * Expands the first axis-aligned 3D boundary to enclose the second, if required.
     *
     * @private
     */
    expandAABB3(aabb1, aabb2) {

        if (aabb1[0] > aabb2[0]) {
            aabb1[0] = aabb2[0];
        }

        if (aabb1[1] > aabb2[1]) {
            aabb1[1] = aabb2[1];
        }

        if (aabb1[2] > aabb2[2]) {
            aabb1[2] = aabb2[2];
        }

        if (aabb1[3] < aabb2[3]) {
            aabb1[3] = aabb2[3];
        }

        if (aabb1[4] < aabb2[4]) {
            aabb1[4] = aabb2[4];
        }

        if (aabb1[5] < aabb2[5]) {
            aabb1[5] = aabb2[5];
        }

        return aabb1;
    },

    /**
     * Expands an axis-aligned 3D boundary to enclose the given point, if needed.
     *
     * @private
     */
    expandAABB3Point3(aabb, p) {

        if (aabb[0] > p[0]) {
            aabb[0] = p[0];
        }

        if (aabb[1] > p[1]) {
            aabb[1] = p[1];
        }

        if (aabb[2] > p[2]) {
            aabb[2] = p[2];
        }

        if (aabb[3] < p[0]) {
            aabb[3] = p[0];
        }

        if (aabb[4] < p[1]) {
            aabb[4] = p[1];
        }

        if (aabb[5] < p[2]) {
            aabb[5] = p[2];
        }

        return aabb;
    },

    /**
     * Expands an axis-aligned 3D boundary to enclose the given points, if needed.
     *
     * @private
     */
    expandAABB3Points3(aabb, positions) {
        var x;
        var y;
        var z;
        for (var i = 0, len = positions.length; i < len; i += 3) {
            x = positions[i];
            y = positions[i + 1];
            z = positions[i + 2];
            if (aabb[0] > x) {
                aabb[0] = x;
            }
            if (aabb[1] > y) {
                aabb[1] = y;
            }
            if (aabb[2] > z) {
                aabb[2] = z;
            }
            if (aabb[3] < x) {
                aabb[3] = x;
            }
            if (aabb[4] < y) {
                aabb[4] = y;
            }
            if (aabb[5] < z) {
                aabb[5] = z;
            }
        }
        return aabb;
    },

    /**
     * Collapses a 2D axis-aligned boundary, ready to expand to fit 2D points.
     * Creates new AABB if none supplied.
     *
     * @private
     */
    collapseAABB2(aabb = math.AABB2()) {
        aabb[0] = math.MAX_DOUBLE;
        aabb[1] = math.MAX_DOUBLE;
        aabb[2] = -math.MAX_DOUBLE;
        aabb[3] = -math.MAX_DOUBLE;

        return aabb;
    },

    point3AABB3Intersect(aabb, p) {
        return aabb[0] > p[0] || aabb[3] < p[0] || aabb[1] > p[1] || aabb[4] < p[1] || aabb[2] > p[2] || aabb[5] < p[2];
    },

    /**
     * Finds the minimum 2D projected axis-aligned boundary enclosing the given 3D points.
     *
     * @private
     */
    OBB3ToAABB2(points, aabb = math.AABB2()) {
        let xmin = math.MAX_DOUBLE;
        let ymin = math.MAX_DOUBLE;
        let xmax = -math.MAX_DOUBLE;
        let ymax = -math.MAX_DOUBLE;

        let x;
        let y;
        let w;
        let f;

        for (let i = 0, len = points.length; i < len; i += 4) {

            x = points[i + 0];
            y = points[i + 1];
            w = points[i + 3] || 1.0;

            f = 1.0 / w;

            x *= f;
            y *= f;

            if (x < xmin) {
                xmin = x;
            }

            if (y < ymin) {
                ymin = y;
            }

            if (x > xmax) {
                xmax = x;
            }

            if (y > ymax) {
                ymax = y;
            }
        }

        aabb[0] = xmin;
        aabb[1] = ymin;
        aabb[2] = xmax;
        aabb[3] = ymax;

        return aabb;
    },

    /**
     * Expands the first axis-aligned 2D boundary to enclose the second, if required.
     *
     * @private
     */
    expandAABB2(aabb1, aabb2) {

        if (aabb1[0] > aabb2[0]) {
            aabb1[0] = aabb2[0];
        }

        if (aabb1[1] > aabb2[1]) {
            aabb1[1] = aabb2[1];
        }

        if (aabb1[2] < aabb2[2]) {
            aabb1[2] = aabb2[2];
        }

        if (aabb1[3] < aabb2[3]) {
            aabb1[3] = aabb2[3];
        }

        return aabb1;
    },

    /**
     * Expands an axis-aligned 2D boundary to enclose the given point, if required.
     *
     * @private
     */
    expandAABB2Point2(aabb, p) {

        if (aabb[0] > p[0]) {
            aabb[0] = p[0];
        }

        if (aabb[1] > p[1]) {
            aabb[1] = p[1];
        }

        if (aabb[2] < p[0]) {
            aabb[2] = p[0];
        }

        if (aabb[3] < p[1]) {
            aabb[3] = p[1];
        }

        return aabb;
    },

    AABB2ToCanvas(aabb, canvasWidth, canvasHeight, aabb2 = aabb) {
        const xmin = (aabb[0] + 1.0) * 0.5;
        const ymin = (aabb[1] + 1.0) * 0.5;
        const xmax = (aabb[2] + 1.0) * 0.5;
        const ymax = (aabb[3] + 1.0) * 0.5;

        aabb2[0] = Math.floor(xmin * canvasWidth);
        aabb2[1] = canvasHeight - Math.floor(ymax * canvasHeight);
        aabb2[2] = Math.floor(xmax * canvasWidth);
        aabb2[3] = canvasHeight - Math.floor(ymin * canvasHeight);

        return aabb2;
    },

    //------------------------------------------------------------------------------------------------------------------
    // Curves
    //------------------------------------------------------------------------------------------------------------------

    tangentQuadraticBezier(t, p0, p1, p2) {
        return 2 * (1 - t) * (p1 - p0) + 2 * t * (p2 - p1);
    },

    tangentQuadraticBezier3(t, p0, p1, p2, p3) {
        return -3 * p0 * (1 - t) * (1 - t) +
            3 * p1 * (1 - t) * (1 - t) - 6 * t * p1 * (1 - t) +
            6 * t * p2 * (1 - t) - 3 * t * t * p2 +
            3 * t * t * p3;
    },

    tangentSpline(t) {
        const h00 = 6 * t * t - 6 * t;
        const h10 = 3 * t * t - 4 * t + 1;
        const h01 = -6 * t * t + 6 * t;
        const h11 = 3 * t * t - 2 * t;
        return h00 + h10 + h01 + h11;
    },

    catmullRomInterpolate(p0, p1, p2, p3, t) {
        const v0 = (p2 - p0) * 0.5;
        const v1 = (p3 - p1) * 0.5;
        const t2 = t * t;
        const t3 = t * t2;
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
    },

// Bezier Curve formulii from http://en.wikipedia.org/wiki/B%C3%A9zier_curve

// Quad Bezier Functions

    b2p0(t, p) {
        const k = 1 - t;
        return k * k * p;

    },

    b2p1(t, p) {
        return 2 * (1 - t) * t * p;
    },

    b2p2(t, p) {
        return t * t * p;
    },

    b2(t, p0, p1, p2) {
        return this.b2p0(t, p0) + this.b2p1(t, p1) + this.b2p2(t, p2);
    },

// Cubic Bezier Functions

    b3p0(t, p) {
        const k = 1 - t;
        return k * k * k * p;
    },

    b3p1(t, p) {
        const k = 1 - t;
        return 3 * k * k * t * p;
    },

    b3p2(t, p) {
        const k = 1 - t;
        return 3 * k * t * t * p;
    },

    b3p3(t, p) {
        return t * t * t * p;
    },

    b3(t, p0, p1, p2, p3) {
        return this.b3p0(t, p0) + this.b3p1(t, p1) + this.b3p2(t, p2) + this.b3p3(t, p3);
    },

    //------------------------------------------------------------------------------------------------------------------
    // Geometry
    //------------------------------------------------------------------------------------------------------------------

    /**
     * Calculates the normal vector of a triangle.
     *
     * @private
     */
    triangleNormal(a, b, c, normal = math.vec3()) {
        const p1x = b[0] - a[0];
        const p1y = b[1] - a[1];
        const p1z = b[2] - a[2];

        const p2x = c[0] - a[0];
        const p2y = c[1] - a[1];
        const p2z = c[2] - a[2];

        const p3x = p1y * p2z - p1z * p2y;
        const p3y = p1z * p2x - p1x * p2z;
        const p3z = p1x * p2y - p1y * p2x;

        const mag = Math.sqrt(p3x * p3x + p3y * p3y + p3z * p3z);
        if (mag === 0) {
            normal[0] = 0;
            normal[1] = 0;
            normal[2] = 0;
        } else {
            normal[0] = p3x / mag;
            normal[1] = p3y / mag;
            normal[2] = p3z / mag;
        }

        return normal
    },

    /**
     * Finds the intersection of a 3D ray with a 3D triangle.
     *
     * @private
     */
    rayTriangleIntersect: ((() => {

        const tempVec3 = new Float32Array(3);
        const tempVec3b = new Float32Array(3);
        const tempVec3c = new Float32Array(3);
        const tempVec3d = new Float32Array(3);
        const tempVec3e = new Float32Array(3);

        return (origin, dir, a, b, c, isect) => {

            isect = isect || math.vec3();

            const EPSILON = 0.000001;

            const edge1 = math.subVec3(b, a, tempVec3);
            const edge2 = math.subVec3(c, a, tempVec3b);

            const pvec = math.cross3Vec3(dir, edge2, tempVec3c);
            const det = math.dotVec3(edge1, pvec);
            if (det < EPSILON) {
                return null;
            }

            const tvec = math.subVec3(origin, a, tempVec3d);
            const u = math.dotVec3(tvec, pvec);
            if (u < 0 || u > det) {
                return null;
            }

            const qvec = math.cross3Vec3(tvec, edge1, tempVec3e);
            const v = math.dotVec3(dir, qvec);
            if (v < 0 || u + v > det) {
                return null;
            }

            const t = math.dotVec3(edge2, qvec) / det;
            isect[0] = origin[0] + t * dir[0];
            isect[1] = origin[1] + t * dir[1];
            isect[2] = origin[2] + t * dir[2];

            return isect;
        };
    }))(),

    /**
     * Finds the intersection of a 3D ray with a plane defined by 3 points.
     *
     * @private
     */
    rayPlaneIntersect: ((() => {

        const tempVec3 = new Float32Array(3);
        const tempVec3b = new Float32Array(3);
        const tempVec3c = new Float32Array(3);
        const tempVec3d = new Float32Array(3);

        return (origin, dir, a, b, c, isect) => {

            isect = isect || math.vec3();

            dir = math.normalizeVec3(dir, tempVec3);

            const edge1 = math.subVec3(b, a, tempVec3b);
            const edge2 = math.subVec3(c, a, tempVec3c);

            const n = math.cross3Vec3(edge1, edge2, tempVec3d);
            math.normalizeVec3(n, n);

            const d = -math.dotVec3(a, n);

            const t = -(math.dotVec3(origin, n) + d) / math.dotVec3(dir, n);

            isect[0] = origin[0] + t * dir[0];
            isect[1] = origin[1] + t * dir[1];
            isect[2] = origin[2] + t * dir[2];

            return isect;
        };
    }))(),

    /**
     * Gets barycentric coordinates from cartesian coordinates within a triangle.
     * Gets barycentric coordinates from cartesian coordinates within a triangle.
     *
     * @private
     */
    cartesianToBarycentric: ((() => {

        const tempVec3 = new Float32Array(3);
        const tempVec3b = new Float32Array(3);
        const tempVec3c = new Float32Array(3);

        return (cartesian, a, b, c, dest) => {

            const v0 = math.subVec3(c, a, tempVec3);
            const v1 = math.subVec3(b, a, tempVec3b);
            const v2 = math.subVec3(cartesian, a, tempVec3c);

            const dot00 = math.dotVec3(v0, v0);
            const dot01 = math.dotVec3(v0, v1);
            const dot02 = math.dotVec3(v0, v2);
            const dot11 = math.dotVec3(v1, v1);
            const dot12 = math.dotVec3(v1, v2);

            const denom = (dot00 * dot11 - dot01 * dot01);

            // Colinear or singular triangle

            if (denom === 0) {

                // Arbitrary location outside of triangle

                return null;
            }

            const invDenom = 1 / denom;

            const u = (dot11 * dot02 - dot01 * dot12) * invDenom;
            const v = (dot00 * dot12 - dot01 * dot02) * invDenom;

            dest[0] = 1 - u - v;
            dest[1] = v;
            dest[2] = u;

            return dest;
        };
    }))(),

    /**
     * Returns true if the given barycentric coordinates are within their triangle.
     *
     * @private
     */
    barycentricInsideTriangle(bary) {

        const v = bary[1];
        const u = bary[2];

        return (u >= 0) && (v >= 0) && (u + v < 1);
    },

    /**
     * Gets cartesian coordinates from barycentric coordinates within a triangle.
     *
     * @private
     */
    barycentricToCartesian(bary, a, b, c, cartesian = math.vec3()) {
        const u = bary[0];
        const v = bary[1];
        const w = bary[2];

        cartesian[0] = a[0] * u + b[0] * v + c[0] * w;
        cartesian[1] = a[1] * u + b[1] * v + c[1] * w;
        cartesian[2] = a[2] * u + b[2] * v + c[2] * w;

        return cartesian;
    },


    /**
     * Given geometry defined as an array of positions, optional normals, option uv and an array of indices, returns
     * modified arrays that have duplicate vertices removed.
     *
     * Note: does not work well when co-incident vertices have same positions but different normals and UVs.
     *
     * @param positions
     * @param normals
     * @param uv
     * @param indices
     * @returns {{positions: Array, indices: Array}}
     * @private
     */
    mergeVertices(positions, normals, uv, indices) {
        const positionsMap = {}; // Hashmap for looking up vertices by position coordinates (and making sure they are unique)
        const indicesLookup = [];
        const uniquePositions = [];
        const uniqueNormals = normals ? [] : null;
        const uniqueUV = uv ? [] : null;
        const indices2 = [];
        let vx;
        let vy;
        let vz;
        let key;
        const precisionPoints = 4; // number of decimal points, e.g. 4 for epsilon of 0.0001
        const precision = 10 ** precisionPoints;
        let i;
        let len;
        let uvi = 0;
        for (i = 0, len = positions.length; i < len; i += 3) {
            vx = positions[i];
            vy = positions[i + 1];
            vz = positions[i + 2];
            key = `${Math.round(vx * precision)}_${Math.round(vy * precision)}_${Math.round(vz * precision)}`;
            if (positionsMap[key] === undefined) {
                positionsMap[key] = uniquePositions.length / 3;
                uniquePositions.push(vx);
                uniquePositions.push(vy);
                uniquePositions.push(vz);
                if (normals) {
                    uniqueNormals.push(normals[i]);
                    uniqueNormals.push(normals[i + 1]);
                    uniqueNormals.push(normals[i + 2]);
                }
                if (uv) {
                    uniqueUV.push(uv[uvi]);
                    uniqueUV.push(uv[uvi + 1]);
                }
            }
            indicesLookup[i / 3] = positionsMap[key];
            uvi += 2;
        }
        for (i = 0, len = indices.length; i < len; i++) {
            indices2[i] = indicesLookup[indices[i]];
        }
        const result = {
            positions: uniquePositions,
            indices: indices2
        };
        if (uniqueNormals) {
            result.normals = uniqueNormals;
        }
        if (uniqueUV) {
            result.uv = uniqueUV;

        }
        return result;
    },

    /**
     * Builds normal vectors from positions and indices.
     *
     * @private
     */
    buildNormals: ((() => {

        const a = new Float32Array(3);
        const b = new Float32Array(3);
        const c = new Float32Array(3);
        const ab = new Float32Array(3);
        const ac = new Float32Array(3);
        const crossVec = new Float32Array(3);

        return (positions, indices, normals) => {

            let i;
            let len;
            const nvecs = new Array(positions.length / 3);
            let j0;
            let j1;
            let j2;

            for (i = 0, len = indices.length; i < len; i += 3) {

                j0 = indices[i];
                j1 = indices[i + 1];
                j2 = indices[i + 2];

                a[0] = positions[j0 * 3];
                a[1] = positions[j0 * 3 + 1];
                a[2] = positions[j0 * 3 + 2];

                b[0] = positions[j1 * 3];
                b[1] = positions[j1 * 3 + 1];
                b[2] = positions[j1 * 3 + 2];

                c[0] = positions[j2 * 3];
                c[1] = positions[j2 * 3 + 1];
                c[2] = positions[j2 * 3 + 2];

                math.subVec3(b, a, ab);
                math.subVec3(c, a, ac);

                const normVec = new Float32Array(3);

                math.normalizeVec3(math.cross3Vec3(ab, ac, crossVec), normVec);

                if (!nvecs[j0]) {
                    nvecs[j0] = [];
                }
                if (!nvecs[j1]) {
                    nvecs[j1] = [];
                }
                if (!nvecs[j2]) {
                    nvecs[j2] = [];
                }

                nvecs[j0].push(normVec);
                nvecs[j1].push(normVec);
                nvecs[j2].push(normVec);
            }

            normals = (normals && normals.length === positions.length) ? normals : new Float32Array(positions.length);

            let count;
            let x;
            let y;
            let z;

            for (i = 0, len = nvecs.length; i < len; i++) {  // Now go through and average out everything

                count = nvecs[i].length;

                x = 0;
                y = 0;
                z = 0;

                for (let j = 0; j < count; j++) {
                    x += nvecs[i][j][0];
                    y += nvecs[i][j][1];
                    z += nvecs[i][j][2];
                }

                normals[i * 3] = (x / count);
                normals[i * 3 + 1] = (y / count);
                normals[i * 3 + 2] = (z / count);
            }

            return normals;
        };
    }))(),

    /**
     * Builds vertex tangent vectors from positions, UVs and indices.
     *
     * @private
     */
    buildTangents: ((() => {

        const tempVec3 = new Float32Array(3);
        const tempVec3b = new Float32Array(3);
        const tempVec3c = new Float32Array(3);
        const tempVec3d = new Float32Array(3);
        const tempVec3e = new Float32Array(3);
        const tempVec3f = new Float32Array(3);
        const tempVec3g = new Float32Array(3);

        return (positions, indices, uv) => {

            const tangents = new Float32Array(positions.length);

            // The vertex arrays needs to be calculated
            // before the calculation of the tangents

            for (let location = 0; location < indices.length; location += 3) {

                // Recontructing each vertex and UV coordinate into the respective vectors

                let index = indices[location];

                const v0 = positions.subarray(index * 3, index * 3 + 3);
                const uv0 = uv.subarray(index * 2, index * 2 + 2);

                index = indices[location + 1];

                const v1 = positions.subarray(index * 3, index * 3 + 3);
                const uv1 = uv.subarray(index * 2, index * 2 + 2);

                index = indices[location + 2];

                const v2 = positions.subarray(index * 3, index * 3 + 3);
                const uv2 = uv.subarray(index * 2, index * 2 + 2);

                const deltaPos1 = math.subVec3(v1, v0, tempVec3);
                const deltaPos2 = math.subVec3(v2, v0, tempVec3b);

                const deltaUV1 = math.subVec2(uv1, uv0, tempVec3c);
                const deltaUV2 = math.subVec2(uv2, uv0, tempVec3d);

                const r = 1 / ((deltaUV1[0] * deltaUV2[1]) - (deltaUV1[1] * deltaUV2[0]));

                const tangent = math.mulVec3Scalar(
                    math.subVec3(
                        math.mulVec3Scalar(deltaPos1, deltaUV2[1], tempVec3e),
                        math.mulVec3Scalar(deltaPos2, deltaUV1[1], tempVec3f),
                        tempVec3g
                    ),
                    r,
                    tempVec3f
                );

                // Average the value of the vectors

                let addTo;

                for (let v = 0; v < 3; v++) {
                    addTo = indices[location + v] * 3;
                    tangents[addTo] += tangent[0];
                    tangents[addTo + 1] += tangent[1];
                    tangents[addTo + 2] += tangent[2];
                }
            }

            return tangents;
        };
    }))(),

    /**
     * Builds vertex and index arrays needed by color-indexed triangle picking.
     *
     * @private
     */
    buildPickTriangles(positions, indices, compressGeometry) {

        const numIndices = indices.length;
        const pickPositions = compressGeometry ? new Uint16Array(numIndices * 9) : new Float32Array(numIndices * 9);
        const pickColors = new Uint8Array(numIndices * 12);
        let primIndex = 0;
        let vi;// Positions array index
        let pvi = 0;// Picking positions array index
        let pci = 0; // Picking color array index

        // Triangle indices
        let i;
        let r;
        let g;
        let b;
        let a;

        for (let location = 0; location < numIndices; location += 3) {

            // Primitive-indexed triangle pick color

            a = (primIndex >> 24 & 0xFF);
            b = (primIndex >> 16 & 0xFF);
            g = (primIndex >> 8 & 0xFF);
            r = (primIndex & 0xFF);

            // A

            i = indices[location];
            vi = i * 3;

            pickPositions[pvi++] = positions[vi];
            pickPositions[pvi++] = positions[vi + 1];
            pickPositions[pvi++] = positions[vi + 2];

            pickColors[pci++] = r;
            pickColors[pci++] = g;
            pickColors[pci++] = b;
            pickColors[pci++] = a;

            // B

            i = indices[location + 1];
            vi = i * 3;

            pickPositions[pvi++] = positions[vi];
            pickPositions[pvi++] = positions[vi + 1];
            pickPositions[pvi++] = positions[vi + 2];

            pickColors[pci++] = r;
            pickColors[pci++] = g;
            pickColors[pci++] = b;
            pickColors[pci++] = a;

            // C

            i = indices[location + 2];
            vi = i * 3;

            pickPositions[pvi++] = positions[vi];
            pickPositions[pvi++] = positions[vi + 1];
            pickPositions[pvi++] = positions[vi + 2];

            pickColors[pci++] = r;
            pickColors[pci++] = g;
            pickColors[pci++] = b;
            pickColors[pci++] = a;

            primIndex++;
        }

        return {
            positions: pickPositions,
            colors: pickColors
        };
    },

    /**
     * Converts surface-perpendicular face normals to vertex normals. Assumes that the mesh contains disjoint triangles
     * that don't share vertex array elements. Works by finding groups of vertices that have the same location and
     * averaging their normal vectors.
     *
     * @returns {{positions: Array, normals: *}}
     */
    faceToVertexNormals(positions, normals, options = {}) {
        const smoothNormalsAngleThreshold = options.smoothNormalsAngleThreshold || 20;
        const vertexMap = {};
        const vertexNormals = [];
        const vertexNormalAccum = {};
        let acc;
        let vx;
        let vy;
        let vz;
        let key;
        const precisionPoints = 4; // number of decimal points, e.g. 4 for epsilon of 0.0001
        const precision = 10 ** precisionPoints;
        let posi;
        let i;
        let j;
        let len;
        let a;
        let b;
        let c;

        for (i = 0, len = positions.length; i < len; i += 3) {

            posi = i / 3;

            vx = positions[i];
            vy = positions[i + 1];
            vz = positions[i + 2];

            key = `${Math.round(vx * precision)}_${Math.round(vy * precision)}_${Math.round(vz * precision)}`;

            if (vertexMap[key] === undefined) {
                vertexMap[key] = [posi];
            } else {
                vertexMap[key].push(posi);
            }

            const normal = math.normalizeVec3([normals[i], normals[i + 1], normals[i + 2]]);

            vertexNormals[posi] = normal;

            acc = math.vec4([normal[0], normal[1], normal[2], 1]);

            vertexNormalAccum[posi] = acc;
        }

        for (key in vertexMap) {

            if (vertexMap.hasOwnProperty(key)) {

                const vertices = vertexMap[key];
                const numVerts = vertices.length;

                for (i = 0; i < numVerts; i++) {

                    const ii = vertices[i];

                    acc = vertexNormalAccum[ii];

                    for (j = 0; j < numVerts; j++) {

                        if (i === j) {
                            continue;
                        }

                        const jj = vertices[j];

                        a = vertexNormals[ii];
                        b = vertexNormals[jj];

                        const angle = Math.abs(math.angleVec3(a, b) / math.DEGTORAD);

                        if (angle < smoothNormalsAngleThreshold) {

                            acc[0] += b[0];
                            acc[1] += b[1];
                            acc[2] += b[2];
                            acc[3] += 1.0;
                        }
                    }
                }
            }
        }

        for (i = 0, len = normals.length; i < len; i += 3) {

            acc = vertexNormalAccum[i / 3];

            normals[i + 0] = acc[0] / acc[3];
            normals[i + 1] = acc[1] / acc[3];
            normals[i + 2] = acc[2] / acc[3];

        }
    },

    //------------------------------------------------------------------------------------------------------------------
    // Ray casting
    //------------------------------------------------------------------------------------------------------------------

    /**
     Transforms a Canvas-space position into a World-space ray, in the context of a Camera.
     @method canvasPosToWorldRay
     @static
     @param {Number[]} viewMatrix View matrix
     @param {Number[]} projMatrix Projection matrix
     @param {Number[]} canvasPos The Canvas-space position.
     @param {Number[]} worldRayOrigin The World-space ray origin.
     @param {Number[]} worldRayDir The World-space ray direction.
     */
    canvasPosToWorldRay: ((() => {

        const tempMat4b = new Float32Array(16);
        const tempMat4c = new Float32Array(16);
        const tempVec4a = new Float32Array(4);
        const tempVec4b = new Float32Array(4);
        const tempVec4c = new Float32Array(4);
        const tempVec4d = new Float32Array(4);

        return (canvas, viewMatrix, projMatrix, canvasPos, worldRayOrigin, worldRayDir) => {

            const pvMat = math.mulMat4(projMatrix, viewMatrix, tempMat4b);
            const pvMatInverse = math.inverseMat4(pvMat, tempMat4c);

            // Calculate clip space coordinates, which will be in range
            // of x=[-1..1] and y=[-1..1], with y=(+1) at top

            const canvasWidth = canvas.width;
            const canvasHeight = canvas.height;

            const clipX = (canvasPos[0] - canvasWidth / 2) / (canvasWidth / 2);  // Calculate clip space coordinates
            const clipY = -(canvasPos[1] - canvasHeight / 2) / (canvasHeight / 2);

            tempVec4a[0] = clipX;
            tempVec4a[1] = clipY;
            tempVec4a[2] = -1;
            tempVec4a[3] = 1;

            math.transformVec4(pvMatInverse, tempVec4a, tempVec4b);
            math.mulVec4Scalar(tempVec4b, 1 / tempVec4b[3]);

            tempVec4c[0] = clipX;
            tempVec4c[1] = clipY;
            tempVec4c[2] = 1;
            tempVec4c[3] = 1;

            math.transformVec4(pvMatInverse, tempVec4c, tempVec4d);
            math.mulVec4Scalar(tempVec4d, 1 / tempVec4d[3]);

            worldRayOrigin[0] = tempVec4d[0];
            worldRayOrigin[1] = tempVec4d[1];
            worldRayOrigin[2] = tempVec4d[2];

            math.subVec3(tempVec4d, tempVec4b, worldRayDir);

            math.normalizeVec3(worldRayDir);
        };
    }))(),

    /**
     Transforms a Canvas-space position to a Mesh's Local-space coordinate system, in the context of a Camera.
     @method canvasPosToLocalRay
     @static
     @param {Camera} camera The Camera.
     @param {Mesh} mesh The Mesh.
     @param {Number[]} viewMatrix View matrix
     @param {Number[]} projMatrix Projection matrix
     @param {Number[]} worldMatrix Modeling matrix
     @param {Number[]} canvasPos The Canvas-space position.
     @param {Number[]} localRayOrigin The Local-space ray origin.
     @param {Number[]} localRayDir The Local-space ray direction.
     */
    canvasPosToLocalRay: ((() => {

        const worldRayOrigin = new Float32Array(3);
        const worldRayDir = new Float32Array(3);

        return (canvas, viewMatrix, projMatrix, worldMatrix, canvasPos, localRayOrigin, localRayDir) => {
            math.canvasPosToWorldRay(canvas, viewMatrix, projMatrix, canvasPos, worldRayOrigin, worldRayDir);
            math.worldRayToLocalRay(worldMatrix, worldRayOrigin, worldRayDir, localRayOrigin, localRayDir);
        };
    }))(),

    /**
     Transforms a ray from World-space to a Mesh's Local-space coordinate system.
     @method worldRayToLocalRay
     @static
     @param {Number[]} worldMatrix The World transform matrix
     @param {Number[]} worldRayOrigin The World-space ray origin.
     @param {Number[]} worldRayDir The World-space ray direction.
     @param {Number[]} localRayOrigin The Local-space ray origin.
     @param {Number[]} localRayDir The Local-space ray direction.
     */
    worldRayToLocalRay: ((() => {

        const tempMat4 = new Float32Array(16);
        const tempVec4a = new Float32Array(4);
        const tempVec4b = new Float32Array(4);

        return (worldMatrix, worldRayOrigin, worldRayDir, localRayOrigin, localRayDir) => {

            const modelMatInverse = math.inverseMat4(worldMatrix, tempMat4);

            tempVec4a[0] = worldRayOrigin[0];
            tempVec4a[1] = worldRayOrigin[1];
            tempVec4a[2] = worldRayOrigin[2];
            tempVec4a[3] = 1;

            math.transformVec4(modelMatInverse, tempVec4a, tempVec4b);

            localRayOrigin[0] = tempVec4b[0];
            localRayOrigin[1] = tempVec4b[1];
            localRayOrigin[2] = tempVec4b[2];

            math.transformVec3(modelMatInverse, worldRayDir, localRayDir);
        };
    }))(),

    buildKDTree: ((() => {

        const KD_TREE_MAX_DEPTH = 10;
        const KD_TREE_MIN_TRIANGLES = 20;

        const dimLength = new Float32Array();

        function buildNode(triangles, indices, positions, depth) {
            const aabb = new Float32Array(6);

            const node = {
                triangles: null,
                left: null,
                right: null,
                leaf: false,
                splitDim: 0,
                aabb
            };

            aabb[0] = aabb[1] = aabb[2] = Number.POSITIVE_INFINITY;
            aabb[3] = aabb[4] = aabb[5] = Number.NEGATIVE_INFINITY;

            let t;
            let i;
            let len;

            for (t = 0, len = triangles.length; t < len; ++t) {
                var ii = triangles[t] * 3;
                for (let j = 0; j < 3; ++j) {
                    const pi = indices[ii + j] * 3;
                    if (positions[pi] < aabb[0]) {
                        aabb[0] = positions[pi]
                    }
                    if (positions[pi] > aabb[3]) {
                        aabb[3] = positions[pi]
                    }
                    if (positions[pi + 1] < aabb[1]) {
                        aabb[1] = positions[pi + 1]
                    }
                    if (positions[pi + 1] > aabb[4]) {
                        aabb[4] = positions[pi + 1]
                    }
                    if (positions[pi + 2] < aabb[2]) {
                        aabb[2] = positions[pi + 2]
                    }
                    if (positions[pi + 2] > aabb[5]) {
                        aabb[5] = positions[pi + 2]
                    }
                }
            }

            if (triangles.length < KD_TREE_MIN_TRIANGLES || depth > KD_TREE_MAX_DEPTH) {
                node.triangles = triangles;
                node.leaf = true;
                return node;
            }

            dimLength[0] = aabb[3] - aabb[0];
            dimLength[1] = aabb[4] - aabb[1];
            dimLength[2] = aabb[5] - aabb[2];

            let dim = 0;

            if (dimLength[1] > dimLength[dim]) {
                dim = 1;
            }

            if (dimLength[2] > dimLength[dim]) {
                dim = 2;
            }

            node.splitDim = dim;

            const mid = (aabb[dim] + aabb[dim + 3]) / 2;
            const left = new Array(triangles.length);
            let numLeft = 0;
            const right = new Array(triangles.length);
            let numRight = 0;

            for (t = 0, len = triangles.length; t < len; ++t) {

                var ii = triangles[t] * 3;
                const i0 = indices[ii];
                const i1 = indices[ii + 1];
                const i2 = indices[ii + 2];

                const pi0 = i0 * 3;
                const pi1 = i1 * 3;
                const pi2 = i2 * 3;

                if (positions[pi0 + dim] <= mid || positions[pi1 + dim] <= mid || positions[pi2 + dim] <= mid) {
                    left[numLeft++] = triangles[t];
                } else {
                    right[numRight++] = triangles[t];
                }
            }

            left.length = numLeft;
            right.length = numRight;

            node.left = buildNode(left, indices, positions, depth + 1);
            node.right = buildNode(right, indices, positions, depth + 1);

            return node;
        }

        return (indices, positions) => {
            const numTris = indices.length / 3;
            const triangles = new Array(numTris);
            for (let i = 0; i < numTris; ++i) {
                triangles[i] = i;
            }
            return buildNode(triangles, indices, positions, 0);
        };
    }))(),


    decompressPosition(position, decodeMatrix, dest) {
        dest[0] = position[0] * decodeMatrix[0] + decodeMatrix[12];
        dest[1] = position[1] * decodeMatrix[5] + decodeMatrix[13];
        dest[2] = position[2] * decodeMatrix[10] + decodeMatrix[14];
    },

    decompressPositions(positions, decodeMatrix, dest = new Float32Array(positions.length)) {
        for (let i = 0, len = positions.length; i < len; i += 3) {
            dest[i + 0] = positions[i + 0] * decodeMatrix[0] + decodeMatrix[12];
            dest[i + 1] = positions[i + 1] * decodeMatrix[5] + decodeMatrix[13];
            dest[i + 2] = positions[i + 2] * decodeMatrix[10] + decodeMatrix[14];
        }
        return dest;
    },

    decompressUV(uv, decodeMatrix, dest) {
        dest[0] = uv[0] * decodeMatrix[0] + decodeMatrix[6];
        dest[1] = uv[1] * decodeMatrix[4] + decodeMatrix[7];
    },

    decompressUVs(uvs, decodeMatrix, dest = new Float32Array(uvs.length)) {
        for (let i = 0, len = uvs.length; i < len; i += 3) {
            dest[i + 0] = uvs[i + 0] * decodeMatrix[0] + decodeMatrix[6];
            dest[i + 1] = uvs[i + 1] * decodeMatrix[4] + decodeMatrix[7];
        }
        return dest;
    },

    octDecodeVec2(oct, result) {
        let x = oct[0];
        let y = oct[1];
        x = (2 * x + 1) / 255;
        y = (2 * y + 1) / 255;
        const z = 1 - Math.abs(x) - Math.abs(y);
        if (z < 0) {
            x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
            y = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
        }
        const length = Math.sqrt(x * x + y * y + z * z);
        result[0] = x / length;
        result[1] = y / length;
        result[2] = z / length;
        return result;
    },

    octDecodeVec2s(octs, result) {
        for (let i = 0, j = 0, len = octs.length; i < len; i += 2) {
            let x = octs[i + 0];
            let y = octs[i + 1];
            x = (2 * x + 1) / 255;
            y = (2 * y + 1) / 255;
            const z = 1 - Math.abs(x) - Math.abs(y);
            if (z < 0) {
                x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
                y = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);
            }
            const length = Math.sqrt(x * x + y * y + z * z);
            result[j + 0] = x / length;
            result[j + 1] = y / length;
            result[j + 2] = z / length;
            j += 3;
        }
        return result;
    }
};

math.buildEdgeIndices = (function () {

    const uniquePositions = [];
    const indicesLookup = [];
    const indicesReverseLookup = [];
    const weldedIndices = [];

    // TODO: Optimize with caching, but need to cater to both compressed and uncompressed positions

    const faces = [];
    let numFaces = 0;
    const compa = new Uint16Array(3);
    const compb = new Uint16Array(3);
    const compc = new Uint16Array(3);
    const a = math.vec3();
    const b = math.vec3();
    const c = math.vec3();
    const cb = math.vec3();
    const ab = math.vec3();
    const cross = math.vec3();
    const normal = math.vec3();

    function weldVertices(positions, indices) {
        const positionsMap = {}; // Hashmap for looking up vertices by position coordinates (and making sure they are unique)
        let vx;
        let vy;
        let vz;
        let key;
        const precisionPoints = 4; // number of decimal points, e.g. 4 for epsilon of 0.0001
        const precision = Math.pow(10, precisionPoints);
        let i;
        let len;
        let lenUniquePositions = 0;
        for (i = 0, len = positions.length; i < len; i += 3) {
            vx = positions[i];
            vy = positions[i + 1];
            vz = positions[i + 2];
            key = Math.round(vx * precision) + '_' + Math.round(vy * precision) + '_' + Math.round(vz * precision);
            if (positionsMap[key] === undefined) {
                positionsMap[key] = lenUniquePositions / 3;
                uniquePositions[lenUniquePositions++] = vx;
                uniquePositions[lenUniquePositions++] = vy;
                uniquePositions[lenUniquePositions++] = vz;
            }
            indicesLookup[i / 3] = positionsMap[key];
        }
        for (i = 0, len = indices.length; i < len; i++) {
            weldedIndices[i] = indicesLookup[indices[i]];
            indicesReverseLookup[weldedIndices[i]] = indices[i];
        }
    }

    function buildFaces(numIndices, positionsDecodeMatrix) {
        numFaces = 0;
        for (let i = 0, len = numIndices; i < len; i += 3) {
            const ia = ((weldedIndices[i]) * 3);
            const ib = ((weldedIndices[i + 1]) * 3);
            const ic = ((weldedIndices[i + 2]) * 3);
            if (positionsDecodeMatrix) {
                compa[0] = uniquePositions[ia];
                compa[1] = uniquePositions[ia + 1];
                compa[2] = uniquePositions[ia + 2];
                compb[0] = uniquePositions[ib];
                compb[1] = uniquePositions[ib + 1];
                compb[2] = uniquePositions[ib + 2];
                compc[0] = uniquePositions[ic];
                compc[1] = uniquePositions[ic + 1];
                compc[2] = uniquePositions[ic + 2];
                // Decode
                math.decompressPosition(compa, positionsDecodeMatrix, a);
                math.decompressPosition(compb, positionsDecodeMatrix, b);
                math.decompressPosition(compc, positionsDecodeMatrix, c);
            } else {
                a[0] = uniquePositions[ia];
                a[1] = uniquePositions[ia + 1];
                a[2] = uniquePositions[ia + 2];
                b[0] = uniquePositions[ib];
                b[1] = uniquePositions[ib + 1];
                b[2] = uniquePositions[ib + 2];
                c[0] = uniquePositions[ic];
                c[1] = uniquePositions[ic + 1];
                c[2] = uniquePositions[ic + 2];
            }
            math.subVec3(c, b, cb);
            math.subVec3(a, b, ab);
            math.cross3Vec3(cb, ab, cross);
            math.normalizeVec3(cross, normal);
            const face = faces[numFaces] || (faces[numFaces] = {normal: math.vec3()});
            face.normal[0] = normal[0];
            face.normal[1] = normal[1];
            face.normal[2] = normal[2];
            numFaces++;
        }
    }

    return function (positions, indices, positionsDecodeMatrix, edgeThreshold) {
        weldVertices(positions, indices);
        buildFaces(indices.length, positionsDecodeMatrix);
        const edgeIndices = [];
        const thresholdDot = Math.cos(math.DEGTORAD * edgeThreshold);
        const edges = {};
        let edge1;
        let edge2;
        let index1;
        let index2;
        let key;
        let largeIndex = false;
        let edge;
        let normal1;
        let normal2;
        let dot;
        let ia;
        let ib;
        for (let i = 0, len = indices.length; i < len; i += 3) {
            const faceIndex = i / 3;
            for (let j = 0; j < 3; j++) {
                edge1 = weldedIndices[i + j];
                edge2 = weldedIndices[i + ((j + 1) % 3)];
                index1 = Math.min(edge1, edge2);
                index2 = Math.max(edge1, edge2);
                key = index1 + "," + index2;
                if (edges[key] === undefined) {
                    edges[key] = {
                        index1: index1,
                        index2: index2,
                        face1: faceIndex,
                        face2: undefined
                    };
                } else {
                    edges[key].face2 = faceIndex;
                }
            }
        }
        for (key in edges) {
            edge = edges[key];
            // an edge is only rendered if the angle (in degrees) between the face normals of the adjoining faces exceeds this value. default = 1 degree.
            if (edge.face2 !== undefined) {
                normal1 = faces[edge.face1].normal;
                normal2 = faces[edge.face2].normal;
                dot = math.dotVec3(normal1, normal2);
                if (dot > thresholdDot) {
                    continue;
                }
            }
            ia = indicesReverseLookup[edge.index1];
            ib = indicesReverseLookup[edge.index2];
            if (!largeIndex && ia > 65535 || ib > 65535) {
                largeIndex = true;
            }
            edgeIndices.push(ia);
            edgeIndices.push(ib);
        }
        return (largeIndex) ? new Uint32Array(edgeIndices) : new Uint16Array(edgeIndices);
    };
})();



export {math};