/**
 * @desc A low-level component that represents a WebGL Sampler.
 * @private
 */
class Sampler {

    constructor(gl, location) {
        this.bindTexture = function (texture, unit) {
            if (texture.bind(unit)) {
                gl.uniform1i(location, unit);
                return true;
            }
            return false;
        };
    }
}

export {Sampler};