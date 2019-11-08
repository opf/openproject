/** @private */
class Wire {

    constructor(parentElement, cfg = {}) {

        this._wire = document.createElement('div');
        this._wire.className += this._wire.className ? ' viewer-ruler-wire' : 'viewer-ruler-wire';
        this._visible = true;

        var wire = this._wire;
        var style = wire.style;

        this._thickness = cfg.thickness || 1.0;

        style.border = "solid " + this._thickness + "px " + (cfg.color || "black");
        style.position = "absolute";
        style["z-index"] = "2000001";
        style.width = 0 + "px";
        style.height = 0 + "px";
        style.visibility = "visible";
        style.top = 0 + "px";
        style.left = 0 + "px";
        style["pointer-events"] = "none";
        style['-webkit-transform-origin'] = "0 0";
        style['-moz-transform-origin'] = "0 0";
        style['-ms-transform-origin'] = "0 0";
        style['-o-transform-origin'] = "0 0";
        style['transform-origin'] = "0 0";
        style['-webkit-transform'] = 'rotate(0deg)';
        style['-moz-transform'] = 'rotate(0deg)';
        style['-ms-transform'] = 'rotate(0deg)';
        style['-o-transform'] = 'rotate(0deg)';
        style['transform'] = 'rotate(0deg)';
        style["opacity"] = 1.0;

        parentElement.appendChild(wire);

        this._x1 = 0;
        this._y1 = 0;
        this._x2 = 0;
        this._y2 = 0;

        this._update();
    }

    _update() {

        var length = Math.abs(Math.sqrt((this._x1 - this._x2) * (this._x1 - this._x2) + (this._y1 - this._y2) * (this._y1 - this._y2)));
        var angle = Math.atan2(this._y2 - this._y1, this._x2 - this._x1) * 180.0 / Math.PI;

        var style = this._wire.style;
        style["width"] = Math.round(length) + 'px';
        style["left"] = Math.round(this._x1) + 'px';
        style["top"] = Math.round(this._y1) + 'px';
        style['-webkit-transform'] = 'rotate(' + angle + 'deg)';
        style['-moz-transform'] = 'rotate(' + angle + 'deg)';
        style['-ms-transform'] = 'rotate(' + angle + 'deg)';
        style['-o-transform'] = 'rotate(' + angle + 'deg)';
        style['transform'] = 'rotate(' + angle + 'deg)';
        style["pointer-events"] = "none";
    }

    setStartAndEnd(x1, y1, x2, y2) {
        this._x1 = x1;
        this._y1 = y1;
        this._x2 = x2;
        this._y2 = y2;
        this._update();
    }

    setColor(color) {
        this._wire.style.border = "solid " + this._thickness + "px " + (color || "black");
    }

    setOpacity(opacity) {
        this._wire.style.opacity = opacity;
    }

    setVisible(visible) {
        visible = !!visible;
        if (this._visible === visible) {
            return;
        }
        this._visible = visible;
        this._wire.style.visibility = this._visible ? "visible" : "hidden";
    }

    destroy(visible) {
        this._wire.parentElement.removeChild(this._wire);
    }
}

export {Wire};
