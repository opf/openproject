/** @private */
class Label {

    constructor(parentElement, cfg = {}) {

        this._prefix = cfg.prefix || "";
        this._x = 0;
        this._y = 0;
        this._visible = true;

        this._label = document.createElement('div');
        this._label.className += this._label.className ? ' viewer-ruler-label' : 'viewer-ruler-label';

        var label = this._label;
        var style = label.style;

        style["border-radius"] = 5 + "px";
        style.color = "white";
        style.padding = "4px";
        style.border = "solid 0px white";
        style.background = "lightgreen";
        style.position = "absolute";
        style["z-index"] = "5000005";
        style.width = "auto";
        style.height = "auto";
        style.visibility = "visible";
        style.top = 0 + "px";
        style.left = 0 + "px";
        style["pointer-events"] = "none";
        style["opacity"] = 1.0;
        label.innerText = "";

        parentElement.appendChild(label);

        this.setPos(cfg.x || 0, cfg.y || 0);
        this.setFillColor(cfg.fillColor);
        this.setBorderColor(cfg.borderColor);
        this.setText(cfg.text);
    }

    setPos(x, y) {
        this._x = x;
        this._y = y;
        var style = this._label.style;
        style["left"] = (Math.round(x) - 20) + 'px';
        style["top"] = (Math.round(y) - 12) + 'px';
    }

    setPosOnWire(x1, y1, x2, y2) {
        var x = x1 + ((x2 - x1) * 0.5);
        var y = y1 + ((y2 - y1) * 0.5);
        var style = this._label.style;
        style["left"] = (Math.round(x) - 20) + 'px';
        style["top"] = (Math.round(y) - 12) + 'px';
    }

    setPosBetweenWires(x1, y1, x2, y2, x3, y3) {
        var x = (x1 + x2 + x3) / 3;
        var y = (y1 + y2 + y3) / 3;
        var style = this._label.style;
        style["left"] = (Math.round(x) - 20) + 'px';
        style["top"] = (Math.round(y) - 12) + 'px';
    }

    setText(text) {
        this._label.innerText = this._prefix + "~" + (text || "");
    }

    setFillColor(color) {
        this._label.style.background = color || "lightgreen";
    }

    setBorderColor(color) {
        this._label.style.border = "solid 2px" + (color || "black");
    }

    setOpacity(opacity) {
        this._label.style.opacity = opacity;
    }

    setVisible(visible) {
        if (this._visible === visible) {
            return;
        }
        this._visible = !!visible;
        this._label.style.visibility = this._visible ? "visible" : "hidden";
    }

    destroy() {
        this._label.parentElement.removeChild(this._label);
    }
}

export {Label};

