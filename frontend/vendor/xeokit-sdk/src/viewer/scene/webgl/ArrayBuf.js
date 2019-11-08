/**
 * @desc Represents a WebGL ArrayBuffer.
 *
 * @private
 */
class ArrayBuf {

    constructor(gl, type, data, numItems, itemSize, usage, normalized, stride, offset) {

        this._gl = gl;
        this.type = type;
        this.allocated = false;

        switch (data.constructor) {

            case Uint8Array:
                this.itemType = gl.UNSIGNED_BYTE;
                this.itemByteSize = 1;
                break;

            case Int8Array:
                this.itemType = gl.BYTE;
                this.itemByteSize = 1;
                break;

            case  Uint16Array:
                this.itemType = gl.UNSIGNED_SHORT;
                this.itemByteSize = 2;
                break;

            case  Int16Array:
                this.itemType = gl.SHORT;
                this.itemByteSize = 2;
                break;

            case Uint32Array:
                this.itemType = gl.UNSIGNED_INT;
                this.itemByteSize = 4;
                break;

            case Int32Array:
                this.itemType = gl.INT;
                this.itemByteSize = 4;
                break;

            default:
                this.itemType = gl.FLOAT;
                this.itemByteSize = 4;
        }

        this.usage = usage;
        this.length = 0;
        this.dataLength = numItems;
        this.numItems = 0;
        this.itemSize = itemSize;
        this.normalized = !!normalized;
        this.stride = stride || 0;
        this.offset = offset || 0;

        this._allocate(data);
    }

    _allocate(data) {
        this.allocated = false;
        this._handle = this._gl.createBuffer();
        if (!this._handle) {
            throw "Failed to allocate WebGL ArrayBuffer";
        }
        if (this._handle) {
            this._gl.bindBuffer(this.type, this._handle);
            this._gl.bufferData(this.type, data.length > this.dataLength ? data.slice(0, this.dataLength) : data, this.usage);
            this._gl.bindBuffer(this.type, null);
            this.length = data.length;
            this.numItems = this.length / this.itemSize;
            this.allocated = true;
        }
    }

    setData(data, offset) {
        if (!this.allocated) {
            return;
        }
        if (data.length + (offset || 0) > this.length) {            // Needs reallocation
            this.destroy();
            this._allocate(data);
        } else {            // No reallocation needed
            this._gl.bindBuffer(this.type, this._handle);
            if (offset || offset === 0) {
                this._gl.bufferSubData(this.type, offset * this.itemByteSize, data);
            } else {
                this._gl.bufferData(this.type, data, this.usage);
            }
            this._gl.bindBuffer(this.type, null);
        }
    }

    bind() {
        if (!this.allocated) {
            return;
        }
        this._gl.bindBuffer(this.type, this._handle);
    }

    unbind() {
        if (!this.allocated) {
            return;
        }
        this._gl.bindBuffer(this.type, null);
    }

    destroy() {
        if (!this.allocated) {
            return;
        }
        this._gl.deleteBuffer(this._handle);
        this._handle = null;
        this.allocated = false;
    }
}

export {ArrayBuf};
