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
    // Class: $.jqplot.MekkoRenderer
    $.jqplot.MekkoRenderer = function(){
        this.shapeRenderer = new $.jqplot.ShapeRenderer();
    };
    
    // called with scope of series.
    $.jqplot.MekkoRenderer.prototype.init = function(options, plot) {
        this.fill = false;
        this.fillRect = true;
        this.strokeRect = true;
        this.shadow = false;
        // width of bar on x axis.
        this._xwidth = 0;
        this._xstart = 0;
        $.extend(true, this.renderer, options);
        // set the shape renderer options
        var opts = {lineJoin:'miter', lineCap:'butt', isarc:false, fillRect:this.fillRect, strokeRect:this.strokeRect};
        this.renderer.shapeRenderer.init(opts);
        plot.axes.x2axis._series.push(this);
    };
    
    // Method: setGridData
    // converts the user data values to grid coordinates and stores them
    // in the gridData array.  Will convert user data into appropriate
    // rectangles.
    // Called with scope of a series.
    $.jqplot.MekkoRenderer.prototype.setGridData = function(plot) {
        // recalculate the grid data
        var xp = this._xaxis.series_u2p;
        var yp = this._yaxis.series_u2p;
        var data = this._plotData;
        this.gridData = [];
        // figure out width on x axis.
        // this._xwidth = this._sumy / plot._sumy * this.canvas.getWidth();
        this._xwidth = xp(this._sumy) - xp(0);
        if (this.index>0) {
            this._xstart = plot.series[this.index-1]._xstart + plot.series[this.index-1]._xwidth;
        }
        var totheight = this.canvas.getHeight();
        var sumy = 0;
        var cury;
        var curheight;
        for (var i=0; i<data.length; i++) {
            if (data[i] != null) {
                sumy += data[i][1];
                cury = totheight - (sumy / this._sumy * totheight);
                curheight = data[i][1] / this._sumy * totheight;
                this.gridData.push([this._xstart, cury, this._xwidth, curheight]);
            }
        }
    };
    
    // Method: makeGridData
    // converts any arbitrary data values to grid coordinates and
    // returns them.  This method exists so that plugins can use a series'
    // linerenderer to generate grid data points without overwriting the
    // grid data associated with that series.
    // Called with scope of a series.
    $.jqplot.MekkoRenderer.prototype.makeGridData = function(data, plot) {
        // recalculate the grid data
        // figure out width on x axis.
        var xp = this._xaxis.series_u2p;
        var totheight = this.canvas.getHeight();
        var sumy = 0;
        var cury;
        var curheight;
        var gd = [];
        for (var i=0; i<data.length; i++) {
            if (data[i] != null) {
                sumy += data[i][1];
                cury = totheight - (sumy / this._sumy * totheight);
                curheight = data[i][1] / this._sumy * totheight;
                gd.push([this._xstart, cury, this._xwidth, curheight]);
            }
        }
        return gd;
    };
    

    // called within scope of series.
    $.jqplot.MekkoRenderer.prototype.draw = function(ctx, gd, options) {
        var i;
        var opts = (options != undefined) ? options : {};
        var showLine = (opts.showLine != undefined) ? opts.showLine : this.showLine;
        var colorGenerator = new $.jqplot.ColorGenerator(this.seriesColors);
        ctx.save();
        if (gd.length) {
            if (showLine) {
                for (i=0; i<gd.length; i++){
                    opts.fillStyle = colorGenerator.next();
                    this.renderer.shapeRenderer.draw(ctx, gd[i], opts);
                }
            }
        }
        
        ctx.restore();
    };  
    
    $.jqplot.MekkoRenderer.prototype.drawShadow = function(ctx, gd, options) {
        // This is a no-op, no shadows on mekko charts.
    };
    
    // called with scope of legend renderer.
    $.jqplot.MekkoLegendRenderer = function() {
        $.jqplot.TableLegendRenderer.call(this);
    };
    
    $.jqplot.MekkoLegendRenderer.prototype = new $.jqplot.TableLegendRenderer();
    $.jqplot.MekkoLegendRenderer.prototype.constructor = $.jqplot.MekkoLegendRenderer;
    
    // called with scope of legend
    $.jqplot.MekkoLegendRenderer.prototype.init = function(options) {
        this.labels = [];
        this.placement = "outside";
        $.extend(true, this, options);
    };
    
    // called with context of legend
    $.jqplot.MekkoLegendRenderer.prototype.draw = function() {
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
            this._elem = $('<table class="jqplot-table-legend jqplot-mekko-legend" style="'+ss+'"></table>');
        
            var pad = false, i, labels = [], colors = [];
            var s = series[0];
            var colorGenerator = new $.jqplot.ColorGenerator(s.seriesColors);
            if (s.show) {
                var pd = s.data;
                for (i=0; i<pd.length; i++){
                    labels.push(this.labels[i] || pd[i][0].toString());
                    colors.push(colorGenerator.next());  
                }
                for (i=pd.length-1; i>-1; i--) {
                    if (labels[i]) {
                        this.renderer.addrow.call(this, labels[i], colors[i], pad);
                        pad = true;
                    }
                }
            }
        }        
        return this._elem;
    };
    
    $.jqplot.MekkoLegendRenderer.prototype.pack = function(offsets) {
        if (this.show) {
            // fake a grid for positioning
            var grid = {_top:offsets.top, _left:offsets.left, _right:offsets.right, _bottom:this._plotDimensions.height - offsets.bottom};      
            if (this.placement == 'inside') {
                switch (this.location) {
                    case 'nw':
                        var a = grid._left + this.xoffset;
                        var b = grid._top + this.yoffset;
                        this._elem.css('left', a);
                        this._elem.css('top', b);
                        break;
                    case 'n':
                        var a = (offsets.left + (this._plotDimensions.width - offsets.right))/2 - this.getWidth()/2;
                        var b = grid._top + this.yoffset;
                        this._elem.css('left', a);
                        this._elem.css('top', b);
                        break;
                    case 'ne':
                        var a = offsets.right + this.xoffset;
                        var b = grid._top + this.yoffset;
                        this._elem.css({right:a, top:b});
                        break;
                    case 'e':
                        var a = offsets.right + this.xoffset;
                        var b = (offsets.top + (this._plotDimensions.height - offsets.bottom))/2 - this.getHeight()/2;
                        this._elem.css({right:a, top:b});
                        break;
                    case 'se':
                        var a = offsets.right + this.xoffset;
                        var b = offsets.bottom + this.yoffset;
                        this._elem.css({right:a, bottom:b});
                        break;
                    case 's':
                        var a = (offsets.left + (this._plotDimensions.width - offsets.right))/2 - this.getWidth()/2;
                        var b = offsets.bottom + this.yoffset;
                        this._elem.css({left:a, bottom:b});
                        break;
                    case 'sw':
                        var a = grid._left + this.xoffset;
                        var b = offsets.bottom + this.yoffset;
                        this._elem.css({left:a, bottom:b});
                        break;
                    case 'w':
                        var a = grid._left + this.xoffset;
                        var b = (offsets.top + (this._plotDimensions.height - offsets.bottom))/2 - this.getHeight()/2;
                        this._elem.css({left:a, top:b});
                        break;
                    default:  // same as 'se'
                        var a = grid._right - this.xoffset;
                        var b = grid._bottom + this.yoffset;
                        this._elem.css({right:a, bottom:b});
                        break;
                }
                
            }
            else {
                switch (this.location) {
                    case 'nw':
                        var a = this._plotDimensions.width - grid._left + this.xoffset;
                        var b = grid._top + this.yoffset;
                        this._elem.css('right', a);
                        this._elem.css('top', b);
                        break;
                    case 'n':
                        var a = (offsets.left + (this._plotDimensions.width - offsets.right))/2 - this.getWidth()/2;
                        var b = this._plotDimensions.height - grid._top + this.yoffset;
                        this._elem.css('left', a);
                        this._elem.css('bottom', b);
                        break;
                    case 'ne':
                        var a = this._plotDimensions.width - offsets.right + this.xoffset;
                        var b = grid._top + this.yoffset;
                        this._elem.css({left:a, top:b});
                        break;
                    case 'e':
                        var a = this._plotDimensions.width - offsets.right + this.xoffset;
                        var b = (offsets.top + (this._plotDimensions.height - offsets.bottom))/2 - this.getHeight()/2;
                        this._elem.css({left:a, top:b});
                        break;
                    case 'se':
                        var a = this._plotDimensions.width - offsets.right + this.xoffset;
                        var b = offsets.bottom + this.yoffset;
                        this._elem.css({left:a, bottom:b});
                        break;
                    case 's':
                        var a = (offsets.left + (this._plotDimensions.width - offsets.right))/2 - this.getWidth()/2;
                        var b = this._plotDimensions.height - offsets.bottom + this.yoffset;
                        this._elem.css({left:a, top:b});
                        break;
                    case 'sw':
                        var a = this._plotDimensions.width - grid._left + this.xoffset;
                        var b = offsets.bottom + this.yoffset;
                        this._elem.css({right:a, bottom:b});
                        break;
                    case 'w':
                        var a = this._plotDimensions.width - grid._left + this.xoffset;
                        var b = (offsets.top + (this._plotDimensions.height - offsets.bottom))/2 - this.getHeight()/2;
                        this._elem.css({right:a, top:b});
                        break;
                    default:  // same as 'se'
                        var a = grid._right - this.xoffset;
                        var b = grid._bottom + this.yoffset;
                        this._elem.css({right:a, bottom:b});
                        break;
                }
            }
        } 
    };
    
    // setup default renderers for axes and legend so user doesn't have to
    // called with scope of plot
    function preInit(target, data, options) {
        options = options || {};
        options.axesDefaults = options.axesDefaults || {};
        options.legend = options.legend || {};
        options.seriesDefaults = options.seriesDefaults || {};
        var setopts = false;
        if (options.seriesDefaults.renderer == $.jqplot.MekkoRenderer) {
            setopts = true;
        }
        else if (options.series) {
            for (var i=0; i < options.series.length; i++) {
                if (options.series[i].renderer == $.jqplot.MekkoRenderer) {
                    setopts = true;
                }
            }
        }
        
        if (setopts) {
            options.axesDefaults.renderer = $.jqplot.MekkoAxisRenderer;
            options.legend.renderer = $.jqplot.MekkoLegendRenderer;
            options.legend.preDraw = true;
        }
    }
    
    $.jqplot.preInitHooks.push(preInit);
    
})(jQuery);    