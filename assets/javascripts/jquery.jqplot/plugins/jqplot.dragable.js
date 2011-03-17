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
     * Class: $.jqplot.Dragable
     * Plugin to make plotted points dragable by the user.
     */
    $.jqplot.Dragable = function(options) {
        // Group: Properties
        this.markerRenderer = new $.jqplot.MarkerRenderer({shadow:false});
        this.shapeRenderer = new $.jqplot.ShapeRenderer();
        this.isDragging = false;
        this.isOver = false;
        this._ctx;
        this._elem;
        this._point;
        this._gridData;
        // prop: color
        // CSS color spec for the dragged point (and adjacent line segment or bar).
        this.color;
        // prop: constrainTo
        // Constrain dragging motion to an axis or to none.
        // Allowable values are 'none', 'x', 'y'
        this.constrainTo = 'none';  // 'x', 'y', or 'none';
        $.extend(true, this, options);
    };
    
    function DragCanvas() {
        $.jqplot.GenericCanvas.call(this);
        this.isDragging = false;
        this.isOver = false;
        this._neighbor;
        this._cursors = [];
    }
    
    DragCanvas.prototype = new $.jqplot.GenericCanvas();
    DragCanvas.prototype.constructor = DragCanvas;
    
    
    // called within scope of series
    $.jqplot.Dragable.parseOptions = function (defaults, opts) {
        var options = opts || {};
        this.plugins.dragable = new $.jqplot.Dragable(options.dragable);
        // since this function is called before series options are parsed,
        // we can set this here and it will be overridden if needed.
        this.isDragable = $.jqplot.config.enablePlugins;
    };
    
    // called within context of plot
    // create a canvas which we can draw on.
    // insert it before the eventCanvas, so eventCanvas will still capture events.
    // add a new DragCanvas object to the plot plugins to handle drawing on this new canvas.
    $.jqplot.Dragable.postPlotDraw = function() {
        this.plugins.dragable = {previousCursor:'auto', isOver:false};
        this.plugins.dragable.dragCanvas = new DragCanvas();
        
        this.eventCanvas._elem.before(this.plugins.dragable.dragCanvas.createElement(this._gridPadding, 'jqplot-dragable-canvas', this._plotDimensions));
        var dctx = this.plugins.dragable.dragCanvas.setContext();
    };
    
    //$.jqplot.preInitHooks.push($.jqplot.Dragable.init);
    $.jqplot.preParseSeriesOptionsHooks.push($.jqplot.Dragable.parseOptions);
    $.jqplot.postDrawHooks.push($.jqplot.Dragable.postPlotDraw);
    $.jqplot.eventListenerHooks.push(['jqplotMouseMove', handleMove]);
    $.jqplot.eventListenerHooks.push(['jqplotMouseDown', handleDown]);
    $.jqplot.eventListenerHooks.push(['jqplotMouseUp', handleUp]);

    
    function initDragPoint(plot, neighbor) {
        var s = plot.series[neighbor.seriesIndex];
        var drag = s.plugins.dragable;
        
        // first, init the mark renderer for the dragged point
        var smr = s.markerRenderer;
        var mr = drag.markerRenderer;
        mr.style = smr.style;
        mr.lineWidth = smr.lineWidth + 2.5;
        mr.size = smr.size + 5;
        if (!drag.color) {
            var rgba = $.jqplot.getColorComponents(smr.color);
            var newrgb = [rgba[0], rgba[1], rgba[2]];
            var alpha = (rgba[3] >= 0.6) ? rgba[3]*0.6 : rgba[3]*(2-rgba[3]);
            drag.color = 'rgba('+newrgb[0]+','+newrgb[1]+','+newrgb[2]+','+alpha+')';
        }
        mr.color = drag.color;
        mr.init();

        var start = (neighbor.pointIndex > 0) ? neighbor.pointIndex - 1 : 0;
        var end = neighbor.pointIndex+2;
        drag._gridData = s.gridData.slice(start, end);
    }
    
    function handleMove(ev, gridpos, datapos, neighbor, plot) {
        if (plot.plugins.dragable.dragCanvas.isDragging) {
            var dc = plot.plugins.dragable.dragCanvas;
            var dp = dc._neighbor;
            var s = plot.series[dp.seriesIndex];
            var drag = s.plugins.dragable;
            var gd = s.gridData;
            
            // compute the new grid position with any constraints.
            var x = (drag.constrainTo == 'y') ? dp.gridData[0] : gridpos.x;
            var y = (drag.constrainTo == 'x') ? dp.gridData[1] : gridpos.y;
            
            // compute data values for any listeners.
            var xu = s._xaxis.series_p2u(x);
            var yu = s._yaxis.series_p2u(y);
            
            // clear the canvas then redraw effect at new position.
            var ctx = dc._ctx;
            ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
            
            // adjust our gridData for the new mouse position
            if (dp.pointIndex > 0) {
                drag._gridData[1] = [x, y];
            }
            else {
                drag._gridData[0] = [x, y];
            }
            plot.series[dp.seriesIndex].draw(dc._ctx, {gridData:drag._gridData, shadow:false, preventJqPlotSeriesDrawTrigger:true, color:drag.color, markerOptions:{color:drag.color, shadow:false}, trendline:{show:false}});
            plot.target.trigger('jqplotSeriesPointChange', [dp.seriesIndex, dp.pointIndex, [xu,yu], [x,y]]);
        }
        else if (neighbor != null) {
            var series = plot.series[neighbor.seriesIndex];
            if (series.isDragable) {
                var dc = plot.plugins.dragable.dragCanvas;
                if (!dc.isOver) {
                    dc._cursors.push(ev.target.style.cursor);
                    ev.target.style.cursor = "pointer";
                }
                dc.isOver = true;
            }
        }
        else if (neighbor == null) {
            var dc = plot.plugins.dragable.dragCanvas;
            if (dc.isOver) {
                ev.target.style.cursor = dc._cursors.pop();
                dc.isOver = false;
            }
        }
    }
    
    function handleDown(ev, gridpos, datapos, neighbor, plot) {
        var dc = plot.plugins.dragable.dragCanvas;
        dc._cursors.push(ev.target.style.cursor);
        if (neighbor != null) {
            var s = plot.series[neighbor.seriesIndex];
            var drag = s.plugins.dragable;
            if (s.isDragable && !dc.isDragging) {
                dc._neighbor = neighbor;
                dc.isDragging = true;
                initDragPoint(plot, neighbor);
                drag.markerRenderer.draw(s.gridData[neighbor.pointIndex][0], s.gridData[neighbor.pointIndex][1], dc._ctx);
                ev.target.style.cursor = "move";
            }
        }
        // Just in case of a hickup, we'll clear the drag canvas and reset.
        else {
           var ctx = dc._ctx;
           ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
           dc.isDragging = false;
        }
    }
    
    function handleUp(ev, gridpos, datapos, neighbor, plot) {
        if (plot.plugins.dragable.dragCanvas.isDragging) {
            var dc = plot.plugins.dragable.dragCanvas;
            // clear the canvas
            var ctx = dc._ctx;
            ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
            dc.isDragging = false;
            // redraw the series canvas at the new point.
            var dp = dc._neighbor;
            var s = plot.series[dp.seriesIndex];
            var drag = s.plugins.dragable;
            // compute the new grid position with any constraints.
            var x = (drag.constrainTo == 'y') ? dp.data[0] : datapos[s.xaxis];
            var y = (drag.constrainTo == 'x') ? dp.data[1] : datapos[s.yaxis];
            // var x = datapos[s.xaxis];
            // var y = datapos[s.yaxis];
            s.data[dp.pointIndex] = [x,y];
            plot.drawSeries({preventJqPlotSeriesDrawTrigger:true}, dp.seriesIndex);
            dc._neighbor = null;
            ev.target.style.cursor = dc._cursors.pop();
        }
    }
})(jQuery);