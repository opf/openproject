/**
 * Copyright (c) 2009 Chris Leonello
 * jqPlot is currently available for use in all personal or commercial projects 
 * under both the MIT and GPL version 2.0 licenses. This means that you can 
 * choose the license that best suits your project and use it accordingly. 
 *
 * The author would appreciate an email letting him know of any substantial
 * use of jqPlot.  You can reach the author at: chris dot leonello at gmail 
 * dot com or see http://www.jqplot.com/info.php .  This is, of course, 
 * not required.
 *
 * If you are feeling kind and generous, consider supporting the project by
 * making a donation at: http://www.jqplot.com/donate.php .
 *
 * Thanks for using jqPlot!
 * 
 */
(function($) {
    /**
    *  Class: $.jqplot.CanvasAxisTickRenderer
    * Renderer to draw axis ticks with a canvas element to support advanced
    * featrues such as rotated text.  This renderer uses a separate rendering engine
    * to draw the text on the canvas.  Two modes of rendering the text are available.
    * If the browser has native font support for canvas fonts (currently Mozila 3.5
    * and Safari 4), you can enable text rendering with the canvas fillText method.
    * You do so by setting the "enableFontSupport" option to true. 
    * 
    * Browsers lacking native font support will have the text drawn on the canvas
    * using the Hershey font metrics.  Even if the "enableFontSupport" option is true
    * non-supporting browsers will still render with the Hershey font.
    */
    $.jqplot.CanvasAxisTickRenderer = function(options) {
        // Group: Properties
        
        // prop: mark
        // tick mark on the axis.  One of 'inside', 'outside', 'cross', '' or null.
        this.mark = 'outside';
        // prop: showMark
        // wether or not to show the mark on the axis.
        this.showMark = true;
        // prop: showGridline
        // wether or not to draw the gridline on the grid at this tick.
        this.showGridline = true;
        // prop: isMinorTick
        // if this is a minor tick.
        this.isMinorTick = false;
        // prop: angle
        // angle of text, measured clockwise from x axis.
        this.angle = 0;
        // prop:  markSize
        // Length of the tick marks in pixels.  For 'cross' style, length
        // will be stoked above and below axis, so total length will be twice this.
        this.markSize = 4;
        // prop: show
        // wether or not to show the tick (mark and label).
        this.show = true;
        // prop: showLabel
        // wether or not to show the label.
        this.showLabel = true;
        // prop: labelPosition
        // 'auto', 'start', 'middle' or 'end'.
        // Whether tick label should be positioned so the start, middle, or end
        // of the tick mark.
        this.labelPosition = 'auto';
        this.label = '';
        this.value = null;
        this._styles = {};
        // prop: formatter
        // A class of a formatter for the tick text.
        // The default $.jqplot.DefaultTickFormatter uses sprintf.
        this.formatter = $.jqplot.DefaultTickFormatter;
        // prop: formatString
        // string passed to the formatter.
        this.formatString = '';
        // prop: fontFamily
        // css spec for the font-family css attribute.
        this.fontFamily = '"Trebuchet MS", Arial, Helvetica, sans-serif';
        // prop: fontSize
        // CSS spec for font size.
        this.fontSize = '11px';
        // prop: fontWeight
        // CSS spec for fontWeight
        this.fontWeight = 'normal';
        // prop: fontStretch
        // Multiplier to condense or expand font width.  
        // Applies only to browsers which don't support canvas native font rendering.
        this.fontStretch = 1.0;
        // prop: textColor
        // css spec for the color attribute.
        this.textColor = '#666666';
        // prop: enableFontSupport
        // true to turn on native canvas font support in Mozilla 3.5+ and Safari 4+.
        // If true, tick label will be drawn with canvas tag native support for fonts.
        // If false, tick label will be drawn with Hershey font metrics.
        this.enableFontSupport = false;
        // prop: pt2px
        // Point to pixel scaling factor, used for computing height of bounding box
        // around a label.  The labels text renderer has a default setting of 1.4, which 
        // should be suitable for most fonts.  Leave as null to use default.  If tops of
        // letters appear clipped, increase this.  If bounding box seems too big, decrease.
        // This is an issue only with the native font renderering capabilities of Mozilla
        // 3.5 and Safari 4 since they do not provide a method to determine the font height.
        this.pt2px = null;
        
        this._elem;
        this._ctx;
        this._plotWidth;
        this._plotHeight;
        this._plotDimensions = {height:null, width:null};
        
        $.extend(true, this, options);
        
        var ropts = {fontSize:this.fontSize, fontWeight:this.fontWeight, fontStretch:this.fontStretch, fillStyle:this.textColor, angle:this.getAngleRad(), fontFamily:this.fontFamily};
        if (this.pt2px) {
            ropts.pt2px = this.pt2px;
        }
        
        if (this.enableFontSupport) {
            if ($.browser.safari) {
                var p = $.browser.version.split('.');
                for (var i=0; i<p.length; i++) { p[i] = Number(p[i]); }
                if (p[0] > 528 || (p[0] == 528 && p[1] >= 16)) {
                    this._textRenderer = new $.jqplot.CanvasFontRenderer(ropts); 
                }
            }
            else if ($.browser.mozilla) {
                var p = $.browser.version.split(".");
                if (p[0] > 1 || (p[0] == 1 &&  p[1] >= 9 && p[2] > 0) ) {
                    this._textRenderer = new $.jqplot.CanvasFontRenderer(ropts);
                }
                else {
                    this._textRenderer = new $.jqplot.CanvasTextRenderer(ropts);
                }
            }
            
            // TODO: test and enable this
            // else if ($.browser.msie) {
            //     this._textRenderer = new $.jqplot.CanvasFontRenderer(ropts); 
            // }
            
            else {
                this._textRenderer = new $.jqplot.CanvasTextRenderer(ropts); 
            }
        }
        else {
            this._textRenderer = new $.jqplot.CanvasTextRenderer(ropts); 
        }
    };
    
    $.jqplot.CanvasAxisTickRenderer.prototype.init = function(options) {
        $.extend(true, this, options);
        this._textRenderer.init({fontSize:this.fontSize, fontWeight:this.fontWeight, fontStretch:this.fontStretch, fillStyle:this.textColor, angle:this.getAngleRad(), fontFamily:this.fontFamily});
    };
    
    // return width along the x axis
    // will check first to see if an element exists.
    // if not, will return the computed text box width.
    $.jqplot.CanvasAxisTickRenderer.prototype.getWidth = function(ctx) {
        if (this._elem) {
         return this._elem.outerWidth(true);
        }
        else {
            var tr = this._textRenderer;
            var l = tr.getWidth(ctx);
            var h = tr.getHeight(ctx);
            var w = Math.abs(Math.sin(tr.angle)*h) + Math.abs(Math.cos(tr.angle)*l);
            return w;
        }
    };
    
    // return height along the y axis.
    $.jqplot.CanvasAxisTickRenderer.prototype.getHeight = function(ctx) {
        if (this._elem) {
         return this._elem.outerHeight(true);
        }
        else {
            var tr = this._textRenderer;
            var l = tr.getWidth(ctx);
            var h = tr.getHeight(ctx);
            var w = Math.abs(Math.cos(tr.angle)*h) + Math.abs(Math.sin(tr.angle)*l);
            return w;
        }
    };
    
    $.jqplot.CanvasAxisTickRenderer.prototype.getAngleRad = function() {
        var a = this.angle * Math.PI/180;
        return a;
    };
    
    
    $.jqplot.CanvasAxisTickRenderer.prototype.setTick = function(value, axisName, isMinor) {
        this.value = value;
        if (isMinor) {
            this.isMinorTick = true;
        }
        return this;
    };
    
    $.jqplot.CanvasAxisTickRenderer.prototype.draw = function(ctx) {
        if (!this.label) {
            this.label = this.formatter(this.formatString, this.value);
        }
        // create a canvas here, but can't draw on it untill it is appended
        // to dom for IE compatability.
        var domelem = document.createElement('canvas');
        this._textRenderer.setText(this.label, ctx);
        var w = this.getWidth(ctx);
        var h = this.getHeight(ctx);
        domelem.width = w;
        domelem.height = h;
        domelem.style.width = w;
        domelem.style.height = h;
        domelem.style.textAlign = 'left';
        domelem.style.position = 'absolute';
        this._domelem = domelem;
        this._elem = $(domelem);
        this._elem.css(this._styles);
        this._elem.addClass('jqplot-'+this.axis+'-tick');
        
        return this._elem;
    };
    
    $.jqplot.CanvasAxisTickRenderer.prototype.pack = function() {
        if ($.browser.msie) {
            window.G_vmlCanvasManager.init_(document);
            this._domelem = window.G_vmlCanvasManager.initElement(this._domelem);
        }
        var ctx = this._elem.get(0).getContext("2d");
        this._textRenderer.draw(ctx, this.label);
    };
    
})(jQuery);