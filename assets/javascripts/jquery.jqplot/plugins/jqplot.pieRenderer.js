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
     * Class: $.jqplot.PieRenderer
     * Plugin renderer to draw a pie chart.
     * Pie charts will draw only the first series.  Other series are ignored.
     * x values, if present, will be used as slice labels.
     * y values give slice size.
     */
    $.jqplot.PieRenderer = function(){
        $.jqplot.LineRenderer.call(this);
    };
    
    $.jqplot.PieRenderer.prototype = new $.jqplot.LineRenderer();
    $.jqplot.PieRenderer.prototype.constructor = $.jqplot.PieRenderer;
    
    // called with scope of a series
    $.jqplot.PieRenderer.prototype.init = function(options) {
        // Group: Properties
        //
        // prop: diameter
        // diameter of the pie, auto computed by default
        this.diameter = null;
        // prop: padding
        // padding between the pie and plot edges, legend, etc.
        this.padding = 20;
        // prop: sliceMargin
        // pixels spacing between pie slices.
        this.sliceMargin = 0;
        // prop: fill
        // true or false, wether to fil the slices.
        this.fill = true;
        // prop: shadowOffset
        // offset of the shadow from the slice and offset of 
        // each succesive stroke of the shadow from the last.
        this.shadowOffset = 2;
        // prop: shadowAlpha
        // transparency of the shadow (0 = transparent, 1 = opaque)
        this.shadowAlpha = 0.07;
        // prop: shadowDepth
        // number of strokes to apply to the shadow, 
        // each stroke offset shadowOffset from the last.
        this.shadowDepth = 5;
        this.tickRenderer = $.jqplot.PieTickRenderer;
        $.extend(true, this, options);
        if (this.diameter != null) {
            this.diameter = this.diameter - this.sliceMargin;
        }
        this._diameter = null;
    };
    
    $.jqplot.PieRenderer.prototype.setGridData = function(plot) {
        // this is a no-op
    };
    
    $.jqplot.PieRenderer.prototype.makeGridData = function(data, plot) {
        var stack = [];
        var td = [];
        for (var i=0; i<data.length; i++){
            stack.push(data[i][1]);
            td.push([data[i][0]]);
            if (i>0) {
                stack[i] += stack[i-1];
            }
        }
        var fact = Math.PI*2/stack[stack.length - 1];
        
        for (var i=0; i<stack.length; i++) {
            td[i][1] = stack[i] * fact;
        }
        return td;
    };
    
    $.jqplot.PieRenderer.prototype.drawSlice = function (ctx, ang1, ang2, color, isShadow) {
        var r = this._diameter / 2;
        var fill = this.fill;
        var lineWidth = this.lineWidth;
        ctx.save();
        ctx.translate(this.sliceMargin*Math.cos((ang1+ang2)/2), this.sliceMargin*Math.sin((ang1+ang2)/2));
        
        if (isShadow) {
            for (var i=0; i<this.shadowDepth; i++) {
                ctx.save();
                ctx.translate(this.shadowOffset*Math.cos(this.shadowAngle/180*Math.PI), this.shadowOffset*Math.sin(this.shadowAngle/180*Math.PI));
                doDraw();
            }
        }
        
        else {
            doDraw();
        }
        
        function doDraw () {
            // Fix for IE and Chrome that can't seem to draw circles correctly.
            // ang2 should always be <= 2 pi since that is the way the data is converted.
             if (ang2 > 6.282) {
                ang2 = 6.282;
                if (ang1 > ang2) {
                    ang1 = 6.281;
                }
            }
            ctx.beginPath();  
            ctx.moveTo(0, 0);
            ctx.fillStyle = color;
            ctx.strokeStyle = color;
            ctx.lineWidth = lineWidth;
            ctx.arc(0, 0, r, ang1, ang2, false);
            ctx.closePath();
            if (fill) {
                ctx.fill();
            }
            else {
                ctx.stroke();
            }
        }
        
        if (isShadow) {
            for (var i=0; i<this.shadowDepth; i++) {
                ctx.restore();
            }
        }
        
        ctx.restore();        
    };
    
    // called with scope of series
    $.jqplot.PieRenderer.prototype.draw = function (ctx, gd, options) {
        var i;
        var opts = (options != undefined) ? options : {};
        // offset and direction of offset due to legend placement
        var offx = 0;
        var offy = 0;
        var trans = 1;
        var colorGenerator = new this.colorGenerator(this.seriesColors);
        if (options.legendInfo) {
            var li = options.legendInfo;
            switch (li.location) {
                case 'nw':
                    offx = li.width + li.xoffset;
                    break;
                case 'w':
                    offx = li.width + li.xoffset;
                    break;
                case 'sw':
                    offx = li.width + li.xoffset;
                    break;
                case 'ne':
                    offx = li.width + li.xoffset;
                    trans = -1;
                    break;
                case 'e':
                    offx = li.width + li.xoffset;
                    trans = -1;
                    break;
                case 'se':
                    offx = li.width + li.xoffset;
                    trans = -1;
                    break;
                case 'n':
                    offy = li.height + li.yoffset;
                    break;
                case 's':
                    offy = li.height + li.yoffset;
                    trans = -1;
                    break;
                default:
                    break;
            }
        }
        
        var shadow = (opts.shadow != undefined) ? opts.shadow : this.shadow;
        var showLine = (opts.showLine != undefined) ? opts.showLine : this.showLine;
        var fill = (opts.fill != undefined) ? opts.fill : this.fill;
        var cw = ctx.canvas.width;
        var ch = ctx.canvas.height;
        var w = cw - offx - 2 * this.padding;
        var h = ch - offy - 2 * this.padding;
        var d = Math.min(w,h);
        this._diameter = this.diameter  || d - this.sliceMargin;
        // this.diameter -= this.sliceMargin;
        var r = this._diameter/2;
        ctx.save();
        ctx.translate((cw - trans * offx)/2 + trans * offx, (ch - trans*offy)/2 + trans * offy);
        
        if (this.shadow) {
            var shadowColor = 'rgba(0,0,0,'+this.shadowAlpha+')';
            for (var i=0; i<gd.length; i++) {
                var ang1 = (i == 0) ? 0 : gd[i-1][1];
                this.renderer.drawSlice.call (this, ctx, ang1, gd[i][1], shadowColor, true);
            }
            
        }
        for (var i=0; i<gd.length; i++) {
            var ang1 = (i == 0) ? 0 : gd[i-1][1];
            this.renderer.drawSlice.call (this, ctx, ang1, gd[i][1], colorGenerator.next());
        }
        
        ctx.restore();        
    };
    
    $.jqplot.PieAxisRenderer = function() {
        $.jqplot.LinearAxisRenderer.call(this);
    };
    
    $.jqplot.PieAxisRenderer.prototype = new $.jqplot.LinearAxisRenderer();
    $.jqplot.PieAxisRenderer.prototype.constructor = $.jqplot.PieAxisRenderer;
        
    
    // There are no traditional axes on a pie chart.  We just need to provide
    // dummy objects with properties so the plot will render.
    // called with scope of axis object.
    $.jqplot.PieAxisRenderer.prototype.init = function(options){
        //
        this.tickRenderer = $.jqplot.PieTickRenderer;
        $.extend(true, this, options);
        // I don't think I'm going to need _dataBounds here.
        // have to go Axis scaling in a way to fit chart onto plot area
        // and provide u2p and p2u functionality for mouse cursor, etc.
        // for convienence set _dataBounds to 0 and 100 and
        // set min/max to 0 and 100.
        this._dataBounds = {min:0, max:100};
        this.min = 0;
        this.max = 100;
        this.showTicks = false;
        this.ticks = [];
        this.showMark = false;
        this.show = false; 
    };
    
    $.jqplot.PieLegendRenderer = function() {
        $.jqplot.TableLegendRenderer.call(this);
    };
    
    $.jqplot.PieLegendRenderer.prototype = new $.jqplot.TableLegendRenderer();
    $.jqplot.PieLegendRenderer.prototype.constructor = $.jqplot.PieLegendRenderer;
    
    // called with context of legend
    $.jqplot.PieLegendRenderer.prototype.draw = function() {
        var legend = this;
        if (this.show) {
            var series = this._series;
            // make a table.  one line label per row.
            var ss = 'position:absolute;';
            ss += (this.background) ? 'background:'+this.background+';' : '';
            ss += (this.border) ? 'border:'+this.border+';' : '';
            ss += (this.fontSize) ? 'font-size:'+this.fontSize+';' : '';
            ss += (this.fontFamily) ? 'font-family:'+this.fontFamily+';' : '';
            ss += (this.textColor) ? 'color:'+this.textColor+';' : '';
            this._elem = $('<table class="jqplot-table-legend" style="'+ss+'"></table>');
        
            var pad = false;
            var s = series[0];
            var colorGenerator = new s.colorGenerator(s.seriesColors);
            if (s.show) {
                var pd = s.data;
                for (var i=0; i<pd.length; i++){
                    var lt = pd[i][0].toString();
                    if (lt) {
                        this.renderer.addrow.call(this, lt, colorGenerator.next(), pad);
                        pad = true;
                    }  
                }
            }
        }        
        return this._elem;
    };
    
    // setup default renderers for axes and legend so user doesn't have to
    // called with scope of plot
    function preInit(target, data, options) {
        options = options || {};
        options.axesDefaults = options.axesDefaults || {};
        options.legend = options.legend || {};
        options.seriesDefaults = options.seriesDefaults || {};
        // only set these if there is a pie series
        var setopts = false;
        if (options.seriesDefaults.renderer == $.jqplot.PieRenderer) {
            setopts = true;
        }
        else if (options.series) {
            for (var i=0; i < options.series.length; i++) {
                if (options.series[i].renderer == $.jqplot.PieRenderer) {
                    setopts = true;
                }
            }
        }
        
        if (setopts) {
            options.axesDefaults.renderer = $.jqplot.PieAxisRenderer;
            options.legend.renderer = $.jqplot.PieLegendRenderer;
            options.legend.preDraw = true;
            // options.seriesDefaults.colorGenerator = this.colorGenerator;
            // options.seriesDefaults.seriesColors = this.seriesColors;
        }
    }
    
    // called with scope of plot
    function postParseOptions(options) {
        for (var i=0; i<this.series.length; i++) {
            this.series[i].seriesColors = this.seriesColors;
            this.series[i].colorGenerator = this.colorGenerator;
        }
    }
    
    $.jqplot.preInitHooks.push(preInit);
    $.jqplot.postParseOptionsHooks.push(postParseOptions);
    
    $.jqplot.PieTickRenderer = function() {
        $.jqplot.AxisTickRenderer.call(this);
    };
    
    $.jqplot.PieTickRenderer.prototype = new $.jqplot.AxisTickRenderer();
    $.jqplot.PieTickRenderer.prototype.constructor = $.jqplot.PieTickRenderer;
    
})(jQuery);
    
    