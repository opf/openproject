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
     * Class: $.jqplot.Cursor
     * Plugin class representing the cursor as displayed on the plot.
     */
    $.jqplot.Cursor = function(options) {
        // Group: Properties
        //
        // prop: style
        // CSS spec for cursor style
        this.style = 'crosshair';
        this.previousCursor = 'auto';
        // prop: show
        // wether to show the cursor or not.
        this.show = $.jqplot.config.enablePlugins;
        // prop: showTooltip
        // show a cursor position tooltip near the cursor
        this.showTooltip = true;
        // prop: followMouse
        // Tooltip follows the mouse, it is not at a fixed location.
        // Tooltip will show on the grid at the location given by
        // tooltipLocation, offset from the grid edge by tooltipOffset.
        this.followMouse = false;
        // prop: tooltipLocation
        // Where to position tooltip.  If followMouse is true, this is
        // relative to the cursor, otherwise, it is relative to the grid.
        // One of 'n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'
        this.tooltipLocation = 'se';
        // prop: tooltipOffset
        // Pixel offset of tooltip from the grid boudaries or cursor center.
        this.tooltipOffset = 6;
        // prop: showTooltipGridPosition
        // show the grid pixel coordinates of the mouse.
        this.showTooltipGridPosition = false;
        // prop: showTooltipUnitPosition
        // show the unit (data) coordinates of the mouse.
        this.showTooltipUnitPosition = true;
        // prop: showTooltipDataPosition
        // Used with showVerticalLine to show intersecting data points in the tooltip.
        this.showTooltipDataPosition = false;
        // prop: tooltipFormatString
        // sprintf format string for the tooltip.
        // Uses Ash Searle's javascript sprintf implementation
        // found here: http://hexmen.com/blog/2007/03/printf-sprintf/
        // See http://perldoc.perl.org/functions/sprintf.html for reference
        // Note, if showTooltipDataPosition is true, the default tooltipFormatString
        // will be set to the cursorLegendFormatString, not the default given here.
        this.tooltipFormatString = '%.4P, %.4P';
        // prop: useAxesFormatters
        // Use the x and y axes formatters to format the text in the tooltip.
        this.useAxesFormatters = true;
        // prop: tooltipAxisGroups
        // Show position for the specified axes.
        // This is an array like [['xaxis', 'yaxis'], ['xaxis', 'y2axis']]
        // Default is to compute automatically for all visible axes.
        this.tooltipAxisGroups = [];
        // prop: zoom
        // Enable plot zooming.
        this.zoom = false;
        // zoomProxy and zoomTarget properties are not directly set by user.  
        // They Will be set through call to zoomProxy method.
        this.zoomProxy = false;
        this.zoomTarget = false;
        // prop: clickReset
        // Will reset plot zoom if single click on plot without drag.
        this.clickReset = false;
        // prop: dblClickReset
        // Will reset plot zoom if double click on plot without drag.
        this.dblClickReset = true;
        // prop: showVerticalLine
        // draw a vertical line across the plot which follows the cursor.
        // When the line is near a data point, a special legend and/or tooltip can
        // be updated with the data values.
        this.showVerticalLine = false;
        // prop: showHorizontalLine
        // draw a horizontal line across the plot which follows the cursor.
        this.showHorizontalLine = false;
        // prop: constrainZoomTo
        // 'none', 'x' or 'y'
        this.constrainZoomTo = 'none';
        // // prop: autoscaleConstraint
        // // when a constrained axis is specified, true will
        // // auatoscale the adjacent axis.
        // this.autoscaleConstraint = true;
        this.shapeRenderer = new $.jqplot.ShapeRenderer();
        this._zoom = {start:[], end:[], started: false, zooming:false, isZoomed:false, axes:{start:{}, end:{}}};
        this._tooltipElem;
        this.zoomCanvas;
        this.cursorCanvas;
        // prop: intersectionThreshold
        // pixel distance from data point or marker to consider cursor lines intersecting with point.
        // If data point markers are not shown, this should be >= 1 or will often miss point intersections.
        this.intersectionThreshold = 2;
        // prop: showCursorLegend
        // Replace the plot legend with an enhanced legend displaying intersection information.
        this.showCursorLegend = false;
        // prop: cursorLegendFormatString
        // Format string used in the cursor legend.  If showTooltipDataPosition is true,
        // this will also be the default format string used by tooltipFormatString.
        this.cursorLegendFormatString = $.jqplot.Cursor.cursorLegendFormatString;
        $.extend(true, this, options);
    };
    
    $.jqplot.Cursor.cursorLegendFormatString = '%s x:%s, y:%s';
    
    // called with scope of plot
    $.jqplot.Cursor.init = function (target, data, opts){
        // add a cursor attribute to the plot
        var options = opts || {};
        this.plugins.cursor = new $.jqplot.Cursor(options.cursor);
        var c = this.plugins.cursor;

        if (c.show) {
            $.jqplot.eventListenerHooks.push(['jqplotMouseEnter', handleMouseEnter]);
            $.jqplot.eventListenerHooks.push(['jqplotMouseLeave', handleMouseLeave]);
            $.jqplot.eventListenerHooks.push(['jqplotMouseMove', handleMouseMove]);
            
            if (c.showCursorLegend) {              
                opts.legend = opts.legend || {};
                opts.legend.renderer =  $.jqplot.CursorLegendRenderer;
                opts.legend.formatString = this.plugins.cursor.cursorLegendFormatString;
                opts.legend.show = true;
            }
            
            if (c.zoom) {
                $.jqplot.eventListenerHooks.push(['jqplotMouseDown', handleMouseDown]);
                $.jqplot.eventListenerHooks.push(['jqplotMouseUp', handleMouseUp]);
                
                if (c.clickReset) {
                    $.jqplot.eventListenerHooks.push(['jqplotClick', handleClick]);
                }
                
                if (c.dblClickReset) {
                    $.jqplot.eventListenerHooks.push(['jqplotDblClick', handleDblClick]);
                }
            }
    
            this.resetZoom = function() {
                var axes = this.axes;
                if (!c.zoomProxy) {
                    for (var ax in axes) {
                        axes[ax].reset();
                    }
                    this.redraw();
                }
                else {
                    var ctx = this.plugins.cursor.zoomCanvas._ctx;
                    ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
                }
                this.plugins.cursor._zoom.isZoomed = false;
                this.target.trigger('jqplotResetZoom', [this, this.plugins.cursor]);
            };
            

            if (c.showTooltipDataPosition) {
                c.showTooltipUnitPosition = false;
                c.showTooltipGridPosition = false;
                if (options.cursor.tooltipFormatString == undefined) {
                    c.tooltipFormatString = $.jqplot.Cursor.cursorLegendFormatString;
                }
            }
        }
    };
    
    // called with context of plot
    $.jqplot.Cursor.postDraw = function() {
        var c = this.plugins.cursor;
        // if (c.zoom) {
        c.zoomCanvas = new $.jqplot.GenericCanvas();
        this.eventCanvas._elem.before(c.zoomCanvas.createElement(this._gridPadding, 'jqplot-zoom-canvas', this._plotDimensions));
        var zctx = c.zoomCanvas.setContext();
        // }
        c._tooltipElem = $('<div class="jqplot-cursor-tooltip" style="position:absolute;display:none"></div>');
        c.zoomCanvas._elem.before(c._tooltipElem);
        if (c.showVerticalLine || c.showHorizontalLine) {
            c.cursorCanvas = new $.jqplot.GenericCanvas();
            this.eventCanvas._elem.before(c.cursorCanvas.createElement(this._gridPadding, 'jqplot-cursor-canvas', this._plotDimensions));
            var zctx = c.cursorCanvas.setContext();
        }

        // if we are showing the positions in unit coordinates, and no axes groups
        // were specified, create a default set.
        if (c.showTooltipUnitPosition){
            if (c.tooltipAxisGroups.length === 0) {
                var series = this.series;
                var s;
                var temp = [];
                for (var i=0; i<series.length; i++) {
                    s = series[i];
                    var ax = s.xaxis+','+s.yaxis;
                    if ($.inArray(ax, temp) == -1) {
                        temp.push(ax);
                    }
                }
                for (var i=0; i<temp.length; i++) {
                    c.tooltipAxisGroups.push(temp[i].split(','));
                }
            }
        }
    };
    
    // Group: methods
    //
    // method: $.jqplot.Cursor.zoomProxy
    // links targetPlot to controllerPlot so that plot zooming of
    // targetPlot will be controlled by zooming on the controllerPlot.
    // controllerPlot will not actually zoom, but acts as an
    // overview plot.  Note, the zoom options must be set to true for
    // zoomProxy to work.
    $.jqplot.Cursor.zoomProxy = function(targetPlot, controllerPlot) {
        var tc = targetPlot.plugins.cursor;
        var cc = controllerPlot.plugins.cursor;
        tc.zoomTarget = true;
        tc.zoom = true;
        tc.style = 'auto';
        tc.dblClickReset = false;
        cc.zoom = true;
        cc.zoomProxy = true;
              
        controllerPlot.target.bind('jqplotZoom', plotZoom);
        controllerPlot.target.bind('jqplotResetZoom', plotReset);

        function plotZoom(ev, gridpos, datapos, plot, cursor) {
            tc.doZoom(gridpos, datapos, targetPlot, cursor);
        } 

        function plotReset(ev, plot, cursor) {
            targetPlot.resetZoom();
        }
    };
    
    $.jqplot.Cursor.prototype.resetZoom = function(plot, cursor) {
        var axes = plot.axes;
        var cax = cursor._zoom.axes;
        if (!plot.plugins.cursor.zoomProxy && cursor._zoom.isZoomed) {
            for (var ax in axes) {
                axes[ax]._ticks = [];
                axes[ax].min = cax[ax].min;
                axes[ax].max = cax[ax].max;
                axes[ax].numberTicks = cax[ax].numberTicks; 
                axes[ax].tickInterval = cax[ax].tickInterval;
                // for date axes
                axes[ax].daTickInterval = cax[ax].daTickInterval;
            }
            plot.redraw();
            cursor._zoom.isZoomed = false;
        }
        else {
            var ctx = cursor.zoomCanvas._ctx;
            ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
        }
        plot.target.trigger('jqplotResetZoom', [plot, cursor]);
    };
    
    $.jqplot.Cursor.resetZoom = function(plot) {
        plot.resetZoom();
    };
    
    $.jqplot.Cursor.prototype.doZoom = function (gridpos, datapos, plot, cursor) {
        var c = cursor;
        var axes = plot.axes;
        var zaxes = c._zoom.axes;
        var start = zaxes.start;
        var end = zaxes.end;
        var min, max;
        var ctx = plot.plugins.cursor.zoomCanvas._ctx;
        // don't zoom is zoom area is too small (in pixels)
        if ((c.constrainZoomTo == 'none' && Math.abs(gridpos.x - c._zoom.start[0]) > 6 && Math.abs(gridpos.y - c._zoom.start[1]) > 6) || (c.constrainZoomTo == 'x' && Math.abs(gridpos.x - c._zoom.start[0]) > 6) ||  (c.constrainZoomTo == 'y' && Math.abs(gridpos.y - c._zoom.start[1]) > 6)) {
            if (!plot.plugins.cursor.zoomProxy) {
                for (var ax in datapos) {
                    // make a copy of the original axes to revert back.
                    if (c._zoom.axes[ax] == undefined) {
                        c._zoom.axes[ax] = {};
                        c._zoom.axes[ax].numberTicks = axes[ax].numberTicks;
                        c._zoom.axes[ax].tickInterval = axes[ax].tickInterval;
                        // for date axes...
                        c._zoom.axes[ax].daTickInterval = axes[ax].daTickInterval;
                        c._zoom.axes[ax].min = axes[ax].min;
                        c._zoom.axes[ax].max = axes[ax].max;
                    }
                    if ((c.constrainZoomTo == 'none') || (c.constrainZoomTo == 'x' && ax.charAt(0) == 'x') || (c.constrainZoomTo == 'y' && ax.charAt(0) == 'y')) {   
                        dp = datapos[ax];
                        if (dp != null) {           
                            if (dp > start[ax]) { 
                                axes[ax].min = start[ax];
                                axes[ax].max = dp;
                            }
                            else {
                                span = start[ax] - dp;
                                axes[ax].max = start[ax];
                                axes[ax].min = dp;
                            }
                            axes[ax].tickInterval = null;
                            // for date axes...
                            axes[ax].daTickInterval = null;
                            axes[ax]._ticks = [];
                        }
                    }
                            
                    // if ((c.constrainZoomTo == 'x' && ax.charAt(0) == 'y' && c.autoscaleConstraint) || (c.constrainZoomTo == 'y' && ax.charAt(0) == 'x' && c.autoscaleConstraint)) {
                    //     dp = datapos[ax];
                    //     if (dp != null) {
                    //         axes[ax].max == null;
                    //         axes[ax].min = null;
                    //     }
                    // }
                }
                ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
                plot.redraw();
                c._zoom.isZoomed = true;
            }
            plot.target.trigger('jqplotZoom', [gridpos, datapos, plot, cursor]);
        }
    };
    
    $.jqplot.preInitHooks.push($.jqplot.Cursor.init);
    $.jqplot.postDrawHooks.push($.jqplot.Cursor.postDraw);
    
    function updateTooltip(gridpos, datapos, plot) {
        var c = plot.plugins.cursor;
        var s = '';
        var addbr = false;
        if (c.showTooltipGridPosition) {
            s = gridpos.x+', '+gridpos.y;
            addbr = true;
        }
        if (c.showTooltipUnitPosition) {
            var g;
            for (var i=0; i<c.tooltipAxisGroups.length; i++) {
                g = c.tooltipAxisGroups[i];
                if (addbr) {
                    s += '<br />';
                }
                if (c.useAxesFormatters) {
                    var xf = plot.axes[g[0]]._ticks[0].formatter;
                    var yf = plot.axes[g[1]]._ticks[0].formatter;
                    var xfstr = plot.axes[g[0]]._ticks[0].formatString;
                    var yfstr = plot.axes[g[1]]._ticks[0].formatString;
                    s += xf(xfstr, datapos[g[0]]) + ', '+ yf(yfstr, datapos[g[1]]);
                }
                else {
                    s += $.jqplot.sprintf(c.tooltipFormatString, datapos[g[0]], datapos[g[1]]);
                }
                addbr = true;
            }
        }
        
        if (c.showTooltipDataPosition) {
            var series = plot.series; 
            var ret = getIntersectingPoints(plot, gridpos.x, gridpos.y);
            var addbr = false;
        
            for (var i = 0; i< series.length; i++) {
                if (series[i].show) {
                    var idx = series[i].index;
                    var label = series[i].label.toString();
                    var cellid = $.inArray(idx, ret.indices);
                    var sx = undefined;
                    var sy = undefined;
                    if (cellid != -1) {
                        var data = ret.data[cellid].data;
                        if (c.useAxesFormatters) {
                            var xf = series[i]._xaxis._ticks[0].formatter;
                            var yf = series[i]._yaxis._ticks[0].formatter;
                            var xfstr = series[i]._xaxis._ticks[0].formatString;
                            var yfstr = series[i]._yaxis._ticks[0].formatString;
                            sx = xf(xfstr, data[0]);
                            sy = yf(yfstr, data[1]);
                        }
                        else {
                            sx = data[0];
                            sy = data[1];
                        }
                        if (addbr) {
                            s += '<br />';
                        }
                        s += $.jqplot.sprintf(c.tooltipFormatString, label, sx, sy);
                        addbr = true;
                    }
                }
            }
            
        }
        c._tooltipElem.html(s);
    }
    
    function moveLine(gridpos, plot) {
        var c = plot.plugins.cursor;
        var ctx = c.cursorCanvas._ctx;
        ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
        if (c.showVerticalLine) {
            c.shapeRenderer.draw(ctx, [[gridpos.x, 0], [gridpos.x, ctx.canvas.height]]);
        }
        if (c.showHorizontalLine) {
            c.shapeRenderer.draw(ctx, [[0, gridpos.y], [ctx.canvas.width, gridpos.y]]);
        }
        var ret = getIntersectingPoints(plot, gridpos.x, gridpos.y);
        if (c.showCursorLegend) {
            var cells = $(plot.targetId + ' td.jqplot-cursor-legend-label');
            for (var i=0; i<cells.length; i++) {
                var idx = $(cells[i]).data('seriesIndex');
                var series = plot.series[idx];
                var label = series.label.toString();
                var cellid = $.inArray(idx, ret.indices);
                var sx = undefined;
                var sy = undefined;
                if (cellid != -1) {
                    var data = ret.data[cellid].data;
                    if (c.useAxesFormatters) {
                        var xf = series._xaxis._ticks[0].formatter;
                        var yf = series._yaxis._ticks[0].formatter;
                        var xfstr = series._xaxis._ticks[0].formatString;
                        var yfstr = series._yaxis._ticks[0].formatString;
                        sx = xf(xfstr, data[0]);
                        sy = yf(yfstr, data[1]);
                    }
                    else {
                        sx = data[0];
                        sy = data[1];
                    }
                }
                if (plot.legend.escapeHtml) {
                    $(cells[i]).text($.jqplot.sprintf(c.cursorLegendFormatString, label, sx, sy));
                }
                else {
                    $(cells[i]).html($.jqplot.sprintf(c.cursorLegendFormatString, label, sx, sy));
                }
            }        
        }
    }
        
    function getIntersectingPoints(plot, x, y) {
        var ret = {indices:[], data:[]};
        var s, i, d0, d, j, r;
        var threshold;
        var c = plot.plugins.cursor;
        for (var i=0; i<plot.series.length; i++) {
            s = plot.series[i];
            r = s.renderer;
            if (s.show) {
                threshold = c.intersectionThreshold;
                if (s.showMarker) {
                    threshold += s.markerRenderer.size/2;
                }
                for (var j=0; j<s.gridData.length; j++) {
                    p = s.gridData[j];
                    // check vertical line
                    if (c.showVerticalLine) {
                        if (Math.abs(x-p[0]) <= threshold) {
                            ret.indices.push(i);
                            ret.data.push({seriesIndex: i, pointIndex:j, gridData:p, data:s.data[j]});
                        }
                    }
                } 
            }
        }
        return ret;
    }
    
    function moveTooltip(gridpos, plot) {
        var c = plot.plugins.cursor;  
        var elem = c._tooltipElem;
        switch (c.tooltipLocation) {
            case 'nw':
                var x = gridpos.x + plot._gridPadding.left - elem.outerWidth(true) - c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top - c.tooltipOffset - elem.outerHeight(true);
                break;
            case 'n':
                var x = gridpos.x + plot._gridPadding.left - elem.outerWidth(true)/2;
                var y = gridpos.y + plot._gridPadding.top - c.tooltipOffset - elem.outerHeight(true);
                break;
            case 'ne':
                var x = gridpos.x + plot._gridPadding.left + c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top - c.tooltipOffset - elem.outerHeight(true);
                break;
            case 'e':
                var x = gridpos.x + plot._gridPadding.left + c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top - elem.outerHeight(true)/2;
                break;
            case 'se':
                var x = gridpos.x + plot._gridPadding.left + c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top + c.tooltipOffset;
                break;
            case 's':
                var x = gridpos.x + plot._gridPadding.left - elem.outerWidth(true)/2;
                var y = gridpos.y + plot._gridPadding.top + c.tooltipOffset;
                break;
            case 'sw':
                var x = gridpos.x + plot._gridPadding.left - elem.outerWidth(true) - c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top + c.tooltipOffset;
                break;
            case 'w':
                var x = gridpos.x + plot._gridPadding.left - elem.outerWidth(true) - c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top - elem.outerHeight(true)/2;
                break;
            default:
                var x = gridpos.x + plot._gridPadding.left + c.tooltipOffset;
                var y = gridpos.y + plot._gridPadding.top + c.tooltipOffset;
                break;
        }
            
        c._tooltipElem.css('left', x);
        c._tooltipElem.css('top', y);
    }
    
    function positionTooltip(plot) { 
        // fake a grid for positioning
        var grid = plot._gridPadding; 
        var c = plot.plugins.cursor;
        var elem = c._tooltipElem;  
        switch (c.tooltipLocation) {
            case 'nw':
                var a = grid.left + c.tooltipOffset;
                var b = grid.top + c.tooltipOffset;
                elem.css('left', a);
                elem.css('top', b);
                break;
            case 'n':
                var a = (grid.left + (plot._plotDimensions.width - grid.right))/2 - elem.outerWidth(true)/2;
                var b = grid.top + c.tooltipOffset;
                elem.css('left', a);
                elem.css('top', b);
                break;
            case 'ne':
                var a = grid.right + c.tooltipOffset;
                var b = grid.top + c.tooltipOffset;
                elem.css({right:a, top:b});
                break;
            case 'e':
                var a = grid.right + c.tooltipOffset;
                var b = (grid.top + (plot._plotDimensions.height - grid.bottom))/2 - elem.outerHeight(true)/2;
                elem.css({right:a, top:b});
                break;
            case 'se':
                var a = grid.right + c.tooltipOffset;
                var b = grid.bottom + c.tooltipOffset;
                elem.css({right:a, bottom:b});
                break;
            case 's':
                var a = (grid.left + (plot._plotDimensions.width - grid.right))/2 - elem.outerWidth(true)/2;
                var b = grid.bottom + c.tooltipOffset;
                elem.css({left:a, bottom:b});
                break;
            case 'sw':
                var a = grid.left + c.tooltipOffset;
                var b = grid.bottom + c.tooltipOffset;
                elem.css({left:a, bottom:b});
                break;
            case 'w':
                var a = grid.left + c.tooltipOffset;
                var b = (grid.top + (plot._plotDimensions.height - grid.bottom))/2 - elem.outerHeight(true)/2;
                elem.css({left:a, top:b});
                break;
            default:  // same as 'se'
                var a = grid.right - c.tooltipOffset;
                var b = grid.bottom + c.tooltipOffset;
                elem.css({right:a, bottom:b});
                break;
        }
    }
    
    function handleClick (ev, gridpos, datapos, neighbor, plot) {
        ev.stopPropagation();
        ev.preventDefault();
        var c = plot.plugins.cursor;
        if (c.clickReset) {
            c.resetZoom(plot, c);
        }
        return false;
    }
    
    function handleDblClick (ev, gridpos, datapos, neighbor, plot) {
        ev.stopPropagation();
        ev.preventDefault();
        var c = plot.plugins.cursor;
        if (c.dblClickReset) {
            c.resetZoom(plot, c);
        }
        return false;
    }
    
    function handleMouseLeave(ev, gridpos, datapos, neighbor, plot) {
        var c = plot.plugins.cursor;
        if (c.show) {
            $(ev.target).css('cursor', c.previousCursor);
            if (c.showTooltip) {
                c._tooltipElem.hide();
            }
            if (c.zoom) {
                c._zoom.started = false;
                c._zoom.zooming = false;
                if (!c.zoomProxy) {
                    var ctx = c.zoomCanvas._ctx;
                    ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
                }
            }
            if (c.showVerticalLine || c.showHorizontalLine) {
                var ctx = c.cursorCanvas._ctx;
                ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
            } if (c.showCursorLegend) {
            var cells = $(plot.targetId + ' td.jqplot-cursor-legend-label');
            for (var i=0; i<cells.length; i++) {
                var idx = $(cells[i]).data('seriesIndex');
                var series = plot.series[idx];
                var label = series.label.toString();
                if (plot.legend.escapeHtml) {
                    $(cells[i]).text($.jqplot.sprintf(c.cursorLegendFormatString, label, undefined, undefined));
                }
                else {
                    $(cells[i]).html($.jqplot.sprintf(c.cursorLegendFormatString, label, undefined, undefined));
                }
                
            }        
        }
        }
    }
    
    function handleMouseEnter(ev, gridpos, datapos, neighbor, plot) {
        var c = plot.plugins.cursor;
        if (c.show) {
            c.previousCursor = ev.target.style.cursor;
            ev.target.style.cursor = c.style;
            if (c.showTooltip) {
                updateTooltip(gridpos, datapos, plot);
                if (c.followMouse) {
                    moveTooltip(gridpos, plot);
                }
                else {
                    positionTooltip(plot);
                }
                c._tooltipElem.show();
            }
            if (c.showVerticalLine || c.showHorizontalLine) {
                moveLine(gridpos, plot);
            }
        }
    }
    
    function handleMouseMove(ev, gridpos, datapos, neighbor, plot) {
        var c = plot.plugins.cursor;
        var ctx = c.zoomCanvas._ctx;
        if (c.show) {
            if (c.showTooltip) {
                updateTooltip(gridpos, datapos, plot);
                if (c.followMouse) {
                    moveTooltip(gridpos, plot);
                }
            }
            if (c.zoom && c._zoom.started && !c.zoomTarget) {
                c._zoom.zooming = true;
                if (c.constrainZoomTo == 'x') {
                    c._zoom.end = [gridpos.x, ctx.canvas.height];
                }
                else if (c.constrainZoomTo == 'y') {
                    c._zoom.end = [ctx.canvas.width, gridpos.y];
                }
                else {
                    c._zoom.end = [gridpos.x, gridpos.y];
                }
                drawZoomBox.call(c);
            }
            if (c.showVerticalLine || c.showHorizontalLine) {
                moveLine(gridpos, plot);
            }
        }
    }
    
    function handleMouseDown(ev, gridpos, datapos, neighbor, plot) {
        var c = plot.plugins.cursor;
        var axes = plot.axes;
        if (c.zoom) {
            if (!c.zoomProxy) {
                var ctx = c.zoomCanvas._ctx;
                ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
            }
            if (c.constrainZoomTo == 'x') {
                c._zoom.start = [gridpos.x, 0];
            }
            else if (c.constrainZoomTo == 'y') {
                c._zoom.start = [0, gridpos.y];
            }
            else {
                c._zoom.start = [gridpos.x, gridpos.y];
            }
            c._zoom.started = true;
            for (var ax in datapos) {
                // get zoom starting position.
                c._zoom.axes.start[ax] = datapos[ax];
            }
        }
    }
    
    function handleMouseUp(ev, gridpos, datapos, neighbor, plot) {
        var c = plot.plugins.cursor;
        if (c.zoom && c._zoom.zooming && !c.zoomTarget) {
            c.doZoom(gridpos, datapos, plot, c);
        }
        c._zoom.started = false;
        c._zoom.zooming = false;
    }
    
    function drawZoomBox() {
        var start = this._zoom.start;
        var end = this._zoom.end;
        var ctx = this.zoomCanvas._ctx;
        var l, t, h, w;
        if (end[0] > start[0]) {
            l = start[0];
            w = end[0] - start[0];
        }
        else {
            l = end[0];
            w = start[0] - end[0];
        }
        if (end[1] > start[1]) {
            t = start[1];
            h = end[1] - start[1];
        }
        else {
            t = end[1];
            h = start[1] - end[1];
        }
        ctx.fillStyle = 'rgba(0,0,0,0.2)';
        ctx.strokeStyle = '#999999';
        ctx.lineWidth = 1.0;
        ctx.clearRect(0,0,ctx.canvas.width, ctx.canvas.height);
        ctx.fillRect(0,0,ctx.canvas.width, ctx.canvas.height);
        ctx.clearRect(l, t, w, h);
        // IE won't show transparent fill rect, so stroke a rect also.
        ctx.strokeRect(l,t,w,h);
    }
    
    $.jqplot.CursorLegendRenderer = function(options) {
        $.jqplot.TableLegendRenderer.call(this, options);
        this.formatString = '%s';
    };
    
    $.jqplot.CursorLegendRenderer.prototype = new $.jqplot.TableLegendRenderer();
    $.jqplot.CursorLegendRenderer.prototype.constructor = $.jqplot.CursorLegendRenderer;
    
    // called in context of a Legend
    $.jqplot.CursorLegendRenderer.prototype.draw = function() {
        if (this.show) {
            var series = this._series;
            // make a table.  one line label per row.
            this._elem = $('<table class="jqplot-legend jqplot-cursor-legend" style="position:absolute"></table>');
        
            var pad = false;
            for (var i = 0; i< series.length; i++) {
                s = series[i];
                if (s.show) {
                    var lt = $.jqplot.sprintf(this.formatString, s.label.toString());
                    if (lt) {
                        var color = s.color;
                        if (s._stack && !s.fill) {
                            color = '';
                        }
                        addrow.call(this, lt, color, pad, i);
                        pad = true;
                    }
                    // let plugins add more rows to legend.  Used by trend line plugin.
                    for (var j=0; j<$.jqplot.addLegendRowHooks.length; j++) {
                        var item = $.jqplot.addLegendRowHooks[j].call(this, s);
                        if (item) {
                            addrow.call(this, item.label, item.color, pad);
                            pad = true;
                        } 
                    }
                }
            }
        }
        
        function addrow(label, color, pad, idx) {
            var rs = (pad) ? this.rowSpacing : '0';
            var tr = $('<tr class="jqplot-legend jqplot-cursor-legend"></tr>').appendTo(this._elem);
            tr.data('seriesIndex', idx);
            $('<td class="jqplot-legend jqplot-cursor-legend-swatch" style="padding-top:'+rs+';">'+
                '<div style="border:1px solid #cccccc;padding:0.2em;">'+
                '<div class="jqplot-cursor-legend-swatch" style="background-color:'+color+';"></div>'+
                '</div></td>').appendTo(tr);
            var td = $('<td class="jqplot-legend jqplot-cursor-legend-label" style="vertical-align:middle;padding-top:'+rs+';"></td>');
            td.appendTo(tr);
            td.data('seriesIndex', idx);
            if (this.escapeHtml) {
                td.text(label);
            }
            else {
                td.html(label);
            }
        }
        return this._elem;
    };
    
})(jQuery);