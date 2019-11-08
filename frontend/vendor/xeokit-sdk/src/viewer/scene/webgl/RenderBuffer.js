/**
 * @desc Represents a WebGL render buffer.
 * @private
 */
class RenderBuffer {

    constructor(canvas, gl, options) {
        options = options || {};
        this.gl = gl;
        this.allocated = false;
        this.canvas = canvas;
        this.buffer = null;
        this.bound = false;
        this.size = options.size;
    }

    setSize(size) {
        this.size = size;
    }

    webglContextRestored(gl) {
        this.gl = gl;
        this.buffer = null;
        this.allocated = false;
        this.bound = false;
    }

    bind() {
        this._touch();
        if (this.bound) {
            return;
        }
        const gl = this.gl;
        gl.bindFramebuffer(gl.FRAMEBUFFER, this.buffer.framebuf);
        this.bound = true;
    }

    _touch() {

        let width;
        let height;
        const gl = this.gl;

        if (this.size) {
            width = this.size[0];
            height = this.size[1];

        } else {
            width = this.canvas.clientWidth;
            height = this.canvas.clientHeight;
        }

        if (this.buffer) {

            if (this.buffer.width === width && this.buffer.height === height) {
                return;

            } else {
                gl.deleteTexture(this.buffer.texture);
                gl.deleteFramebuffer(this.buffer.framebuf);
                gl.deleteRenderbuffer(this.buffer.renderbuf);
            }
        }

        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        const renderbuf = gl.createRenderbuffer();
        gl.bindRenderbuffer(gl.RENDERBUFFER, renderbuf);
        gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);

        const framebuf = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuf);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
        gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, renderbuf);

        gl.bindTexture(gl.TEXTURE_2D, null);
        gl.bindRenderbuffer(gl.RENDERBUFFER, null);
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // Verify framebuffer is OK

        gl.bindFramebuffer(gl.FRAMEBUFFER, framebuf);
        if (!gl.isFramebuffer(framebuf)) {
            throw "Invalid framebuffer";
        }
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        const status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);

        switch (status) {

            case gl.FRAMEBUFFER_COMPLETE:
                break;

            case gl.FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
                throw "Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_ATTACHMENT";

            case gl.FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
                throw "Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT";

            case gl.FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
                throw "Incomplete framebuffer: FRAMEBUFFER_INCOMPLETE_DIMENSIONS";

            case gl.FRAMEBUFFER_UNSUPPORTED:
                throw "Incomplete framebuffer: FRAMEBUFFER_UNSUPPORTED";

            default:
                throw "Incomplete framebuffer: " + status;
        }

        this.buffer = {
            framebuf: framebuf,
            renderbuf: renderbuf,
            texture: texture,
            width: width,
            height: height
        };

        this.bound = false;
    }

    clear() {
        if (!this.bound) {
            throw "Render buffer not bound";
        }
        const gl = this.gl;
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    read(pickX, pickY) {
        const x = pickX;
        const y = this.canvas.height - pickY;
        const pix = new Uint8Array(4);
        const gl = this.gl;
        gl.readPixels(x, y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pix);
        return pix;
    }

    unbind() {
        const gl = this.gl;
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        this.bound = false;
    }

    getTexture() {
        const self = this;
        return {
            renderBuffer: this,
            bind: function (unit) {
                if (self.buffer && self.buffer.texture) {
                    self.gl.activeTexture(self.gl["TEXTURE" + unit]);
                    self.gl.bindTexture(self.gl.TEXTURE_2D, self.buffer.texture);
                    return true;
                }
                return false;
            },
            unbind: function (unit) {
                if (self.buffer && self.buffer.texture) {
                    self.gl.activeTexture(self.gl["TEXTURE" + unit]);
                    self.gl.bindTexture(self.gl.TEXTURE_2D, null);
                }
            }
        };
    }

    destroy() {
        if (this.allocated) {
            const gl = this.gl;
            gl.deleteTexture(this.buffer.texture);
            gl.deleteFramebuffer(this.buffer.framebuf);
            gl.deleteRenderbuffer(this.buffer.renderbuf);
            this.allocated = false;
            this.buffer = null;
            this.bound = false;
        }
    }
}

export {RenderBuffer};