/** @private */
class Dot {

    constructor(parentElement, cfg = {}) {

        this._x = 0;
        this._y = 0;

        this._visible = true;
        this._dot = document.createElement('div');
        this._dot.className += this._dot.className ? ' viewer-ruler-dot' : 'viewer-ruler-dot';

        var dot = this._dot;
        var style = dot.style;

        style["border-radius"] = 25 + "px";
        style.border = "solid 2px white";
        style.background = "lightgreen";
        style.position = "absolute";
        style["z-index"] = "40000005";
        style.width = 8 + "px";
        style.height = 8 + "px";
        style.visibility = "visible";
        style.top = 0 + "px";
        style.left = 0 + "px";
        style["box-shadow"] = "0 2px 5px 0 #182A3D;";
        style["pointer-events"] = "none";
        style["opacity"] = 1.0;

        parentElement.appendChild(dot);

        this.setPos(cfg.x || 0, cfg.y || 0);
        this.setFillColor(cfg.fillColor);
        this.setBorderColor(cfg.borderColor);
        this.setClickable(false);
    }

    setPos(x, y) {
        this._x = x;
        this._y = y;
        var style = this._dot.style;
        style["left"] = (Math.round(x) - 5) + 'px';
        style["top"] = (Math.round(y) - 5) + 'px';
    }

    setFillColor(color) {
        this._dot.style.background = color || "lightgreen";
    }

    setBorderColor(color) {
        this._dot.style.border = "solid 2px" + (color || "black");
    }

    setOpacity(opacity) {
        this._dot.style.opacity = opacity;
    }

    setVisible(visible) {
        if (this._visible === visible) {
            return;
        }
        this._visible = !!visible;
        this._dot.style.visibility = this._visible ? "visible" : "hidden";
    }

    setClickable(clickable) {
        this._dot.style["pointer-events"] = (!!clickable) ? "all" : "none";
    }

    destroy() {
        this.setVisible(false);
        this._dot.parentElement.removeChild(this._dot);
    }
}

export {Dot};
