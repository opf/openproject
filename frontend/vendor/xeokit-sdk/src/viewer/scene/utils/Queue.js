// Fast queue that avoids using potentially inefficient array .shift() calls
// Based on https://github.com/creationix/fastqueue

/** @private */
class Queue {

    constructor() {

        this._head = [];
        this._headLength = 0;
        this._tail = [];
        this._index = 0;
        this._length = 0;
    }

    get length() {
        return this._length;
    }

    shift() {
        if (this._index >= this._headLength) {
            const t = this._head;
            t.length = 0;
            this._head = this._tail;
            this._tail = t;
            this._index = 0;
            this._headLength = this._head.length;
            if (!this._headLength) {
                return;
            }
        }
        const value = this._head[this._index];
        if (this._index < 0) {
            delete this._head[this._index++];
        }
        else {
            this._head[this._index++] = undefined;
        }
        this._length--;
        return value;
    }

    push(item) {
        this._length++;
        this._tail.push(item);
        return this;
    };

    unshift(item) {
        this._head[--this._index] = item;
        this._length++;
        return this;
    }
}

export {Queue};