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
     * Class: $.jqplot.OHLCRenderer
     * jqPlot Plugin to draw Open Hi Low Close, Candlestick and Hi Low Close charts.
     * 
     * To use this plugin, include the renderer js file in 
     * your source:
     * 
     * > <script type="text/javascript" src="plugins/jqplot.ohlcRenderer.js"></script>
     * 
     * You will most likely want to use a date axis renderer
     * for the x axis also, so include the date axis render js file also:
     * 
     * > <script type="text/javascript" src="plugins/jqplot.dateAxisRenderer.js"></script>
     * 
     * Then you set the renderer in the series options on your plot:
     * 
     * > series: [{renderer:$.jqplot.OHLCRenderer}]
     * 
     * For OHLC and candlestick charts, data should be specified
     * like so:
     * 
     * > dat = [['07/06/2009',138.7,139.68,135.18,135.4], ['06/29/2009',143.46,144.66,139.79,140.02], ...]
     * 
     * If the data array has only 4 values per point instead of 5,
     * the renderer will create a Hi Low Close chart instead.  In that case,
     * data should be supplied like:
     * 
     * > dat = [['07/06/2009',139.68,135.18,135.4], ['06/29/2009',144.66,139.79,140.02], ...]
     * 
     * To generate a candlestick chart instead of an OHLC chart,
     * set the "candlestick" option to true:
     * 
     * > series: [{renderer:$.jqplot.OHLCRenderer, rendererOptions:{candleStick:true}}],
     * 
     */
    $.jqplot.OHLCRenderer = function(){
        // subclass line renderer to make use of some of it's methods.
        $.jqplot.LineRenderer.call(this);
        // prop: candleStick
        // true to render chart as candleStick.
        // Must have an open price, cannot be a hlc chart.
        this.candleStick = false;
        // prop: tickLength
        // length of the line in pixels indicating open and close price.
        // Default will auto calculate based on plot width and 
        // number of points displayed.
        this.tickLength = 'auto';
        // prop: bodyWidth
        // width of the candlestick body in pixels.  Default will auto calculate
        // based on plot width and number of candlesticks displayed.
        this.bodyWidth = 'auto';
        // prop: openColor
        // color of the open price tick mark.  Default is series color.
        this.openColor = null;
        // prop: closeColor
        // color of the close price tick mark.  Default is series color.
        this.closeColor = null;
        // prop: wickColor
        // color of the hi-lo line thorugh the candlestick body.
        // Default is the series color.
        this.wickColor = null;
        // prop: fillUpBody
        // true to render an "up" day (close price greater than open price)
        // with a filled candlestick body.
        this.fillUpBody = false;
        // prop: fillDownBody
        // true to render a "down" day (close price lower than open price)
        // with a filled candlestick body.
        this.fillDownBody = true;
        // prop: upBodyColor
        // Color of candlestick body of an "up" day.  Default is series color.
        this.upBodyColor = null;
        // prop: downBodyColor
        // Color of candlestick body on a "down" day.  Default is series color.
        this.downBodyColor = null;
        // prop: hlc
        // true if is a hi-low-close chart (no open price).
        // This is determined automatically from the series data.
        this.hlc = false;
        this._tickLength;
        this._bodyWidth;
    };
    
    $.jqplot.OHLCRenderer.prototype = new $.jqplot.LineRenderer();
    $.jqplot.OHLCRenderer.prototype.constructor = $.jqplot.OHLCRenderer;
    
    // called with scope of series.
    $.jqplot.OHLCRenderer.prototype.init = function(options) {
        // prop: lineWidth
        // Width of the hi-low line and open/close ticks.
        this.lineWidth = 1.5;
        $.jqplot.LineRenderer.prototype.init.call(this, options);
        // set the yaxis data bounds here to account for hi and low values
        var db = this._yaxis._dataBounds;
        var d = this._plotData;
        // if data points have less than 5 values, force a hlc chart.
        if (d[0].length < 5) {
            this.renderer.hlc = true;

            for (var j=0; j<d.length; j++) { 
                if (d[j][2] < db.min || db.min == null) {
                    db.min = d[j][2];
                }
                if (d[j][1] > db.max || db.max == null) {
                    db.max = d[j][1];
                }             
            }
        }
        else {
            for (var j=0; j<d.length; j++) { 
                if (d[j][3] < db.min || db.min == null) {
                    db.min = d[j][3];
                }
                if (d[j][2] > db.max || db.max == null) {
                    db.max = d[j][2];
                }             
            }
        }
        
    };
    
    // called within scope of series.
    $.jqplot.OHLCRenderer.prototype.draw = function(ctx, gd, options) {
        var d = this.data;
        var xmin = this._xaxis.min;
        var xmax = this._xaxis.max;
        // index of last value below range of plot.
        var xminidx = 0;
        // index of first value above range of plot.
        var xmaxidx = d.length;
        var xp = this._xaxis.series_u2p;
        var yp = this._yaxis.series_u2p;
        var i, prevColor, ops, b, h, w, a, points;
        var o;
        var r = this.renderer;
        var opts = (options != undefined) ? options : {};
        var shadow = (opts.shadow != undefined) ? opts.shadow : this.shadow;
        var fill = (opts.fill != undefined) ? opts.fill : this.fill;
        var fillAndStroke = (opts.fillAndStroke != undefined) ? opts.fillAndStroke : this.fillAndStroke;
        r.bodyWidth = (opts.bodyWidth != undefined) ? opts.bodyWidth : r.bodyWidth;
        r.tickLength = (opts.tickLength != undefined) ? opts.tickLength : r.tickLength;
        ctx.save();
        if (this.show) {
            var x, open, hi, low, close;
            // need to get widths based on number of points shown,
            // not on total number of points.  Use the results 
            // to speed up drawing in next step.
            for (var i=0; i<d.length; i++) {
                if (d[i][0] < xmin) {
                    xminidx = i;
                }
                else if (d[i][0] < xmax) {
                    xmaxidx = i+1;
                }
            }
            
            if (r.candleStick) {
                if (typeof(r.bodyWidth) == 'number') {
                    r._bodyWidth = r.bodyWidth;
                }
                else {
                    r._bodyWidth = Math.min(20, ctx.canvas.width/(xmaxidx - xminidx)/2);
                }
            }
            else {
                if (typeof(r.tickLength) == 'number') {
                    r._tickLength = r.tickLength;
                }
                else {
                    r._tickLength = Math.min(10, ctx.canvas.width/(xmaxidx - xminidx)/4);
                }
            }
            
            for (var i=xminidx; i<xmaxidx; i++) {
                x = xp(d[i][0]);
                if (r.hlc) {
                    open = null;
                    hi = yp(d[i][1]);
                    low = yp(d[i][2]);
                    close = yp(d[i][3]);
                }
                else {
                    open = yp(d[i][1]);
                    hi = yp(d[i][2]);
                    low = yp(d[i][3]);
                    close = yp(d[i][4]);
                }
                o = {};
                if (r.candleStick && !r.hlc) {
                    w = r._bodyWidth;
                    a = x - w/2;
                    // draw candle
                    // determine if candle up or down
                    // up, remember grid coordinates increase downward
                    if (close < open) {
                        // draw wick
                        if (r.wickColor) {
                            o.color = r.wickColor;
                        }
                        else if (r.downBodyColor) {
                            o.color = r.upBodyColor;
                        }
                        ops = $.extend(true, {}, opts, o);
                        r.shapeRenderer.draw(ctx, [[x, hi], [x, close]], ops); 
                        r.shapeRenderer.draw(ctx, [[x, open], [x, low]], ops); 
                        o = {};
                        b = close;
                        h = open - close;
                        // if color specified, use it
                        if (r.fillUpBody) {
                            o.fillRect = true;
                        }
                        else {
                            o.strokeRect = true;
                            w = w - this.lineWidth;
                            a = x - w/2;
                        }
                        if (r.upBodyColor) {
                            o.color = r.upBodyColor;
                            o.fillStyle = r.upBodyColor;
                        }
                        points = [a, b, w, h];
                    }
                    // down
                    else if (close >  open) {
                        // draw wick
                        if (r.wickColor) {
                            o.color = r.wickColor;
                        }
                        else if (r.downBodyColor) {
                            o.color = r.downBodyColor;
                        }
                        ops = $.extend(true, {}, opts, o);
                        r.shapeRenderer.draw(ctx, [[x, hi], [x, open]], ops); 
                        r.shapeRenderer.draw(ctx, [[x, close], [x, low]], ops);
                         
                        o = {};
                        
                        b = open;
                        h = close - open;
                        // if color specified, use it
                        if (r.fillDownBody) {
                            o.fillRect = true;
                        }
                        else {
                            o.strokeRect = true;
                            w = w - this.lineWidth;
                            a = x - w/2;
                        }
                        if (r.downBodyColor) {
                            o.color = r.downBodyColor;
                            o.fillStyle = r.downBodyColor;
                        }
                        points = [a, b, w, h];
                    }
                    // even, open = close
                    else  {
                        // draw wick
                        if (r.wickColor) {
                            o.color = r.wickColor;
                        }
                        ops = $.extend(true, {}, opts, o);
                        r.shapeRenderer.draw(ctx, [[x, hi], [x, low]], ops); 
                        o = {};
                        o.fillRect = false;
                        o.strokeRect = false;
                        a = [x - w/2, open];
                        b = [x + w/2, close];
                        w = null;
                        h = null;
                        points = [a, b];
                    }
                    ops = $.extend(true, {}, opts, o);
                    r.shapeRenderer.draw(ctx, points, ops);
                }
                else {
                    prevColor = opts.color;
                    if (r.openColor) {
                        opts.color = r.openColor;
                    }
                    // draw open tick
                    if (!r.hlc) {
                        r.shapeRenderer.draw(ctx, [[x-r._tickLength, open], [x, open]], opts);    
                    }
                    opts.color = prevColor;
                    // draw wick
                    if (r.wickColor) {
                        opts.color = r.wickColor;
                    }
                    r.shapeRenderer.draw(ctx, [[x, hi], [x, low]], opts); 
                    opts.color  = prevColor;
                    // draw close tick
                    if (r.closeColor) {
                        opts.color = r.closeColor;
                    }
                    r.shapeRenderer.draw(ctx, [[x, close], [x+r._tickLength, close]], opts); 
                    opts.color = prevColor;
                }
            }
        }
        
        ctx.restore();
    };  
    
    $.jqplot.OHLCRenderer.prototype.drawShadow = function(ctx, gd, options) {
        // This is a no-op, shadows drawn with lines.
    };
    
    // called with scope of plot.
    $.jqplot.OHLCRenderer.checkOptions = function(target, data, options) {
        // provide some sensible highlighter options by default
        // These aren't good for hlc, only for ohlc or candlestick
        if (!options.highlighter) {
            options.highlighter = {
                showMarker:false,
                tooltipAxes: 'y',
                yvalues: 4,
                formatString:'<table class="jqplot-highlighter"><tr><td>date:</td><td>%s</td></tr><tr><td>open:</td><td>%s</td></tr><tr><td>hi:</td><td>%s</td></tr><tr><td>low:</td><td>%s</td></tr><tr><td>close:</td><td>%s</td></tr></table>'
            };
        }
    };
    
    //$.jqplot.preInitHooks.push($.jqplot.OHLCRenderer.checkOptions);
    
})(jQuery);    