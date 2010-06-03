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
    *  class: $.jqplot.CategoryAxisRenderer
    *  A plugin for jqPlot to render a category style axis, with equal pixel spacing between y data values of a series.
    *  This renderer has no options beyond those supplied by the <Axis> class. 
    *  
    *  To use this renderer, include the plugin in your source
    *  > <script type="text/javascript" language="javascript" src="plugins/jqplot.categoryAxisRenderer.js"></script>
    *  
    *  and supply the appropriate options to your plot
    *  
    *  > {axes:{xaxis:{renderer:$.jqplot.CategoryAxisRenderer}}}
    **/
    $.jqplot.CategoryAxisRenderer = function() {
        $.jqplot.LinearAxisRenderer.call(this);
    };
    
    $.jqplot.CategoryAxisRenderer.prototype = new $.jqplot.LinearAxisRenderer();
    $.jqplot.CategoryAxisRenderer.prototype.constructor = $.jqplot.CategoryAxisRenderer;
    
    $.jqplot.CategoryAxisRenderer.prototype.init = function(options){
        // prop: tickRenderer
        // A class of a rendering engine for creating the ticks labels displayed on the plot, 
        // See <$.jqplot.AxisTickRenderer>.
        // this.tickRenderer = $.jqplot.AxisTickRenderer;
        // this.labelRenderer = $.jqplot.AxisLabelRenderer;
        $.extend(true, this, {tickOptions:{formatString:'%d'}}, options);
        var db = this._dataBounds;
        // Go through all the series attached to this axis and find
        // the min/max bounds for this axis.
        for (var i=0; i<this._series.length; i++) {
            var s = this._series[i];
            var d = s.data;
            
            for (var j=0; j<d.length; j++) { 
                if (this.name == 'xaxis' || this.name == 'x2axis') {
                    if (d[j][0] < db.min || db.min == null) {
                        db.min = d[j][0];
                    }
                    if (d[j][0] > db.max || db.max == null) {
                        db.max = d[j][0];
                    }
                }              
                else {
                    if (d[j][1] < db.min || db.min == null) {
                        db.min = d[j][1];
                    }
                    if (d[j][1] > db.max || db.max == null) {
                        db.max = d[j][1];
                    }
                }              
            }
        }
    };
 

    $.jqplot.CategoryAxisRenderer.prototype.createTicks = function() {
        // we're are operating on an axis here
        var ticks = this._ticks;
        var userTicks = this.ticks;
        var name = this.name;
        // databounds were set on axis initialization.
        var db = this._dataBounds;
        var dim, interval;
        var min, max;
        var pos1, pos2;
        var tt, i;

        // if we already have ticks, use them.
        if (userTicks.length) {
            this.min = 0.5;
            this.max = userTicks.length + 0.5;
            var range = this.max - this.min;
            this.numberTicks = 2*userTicks.length + 1;
            for (i=0; i<userTicks.length; i++){
                tt = this.min + 2 * i * range / (this.numberTicks-1);
                // need a marker before and after the tick
                var t = new this.tickRenderer(this.tickOptions);
                t.showLabel = false;
                t.showMark = true;
                t.setTick(tt, this.name);
                this._ticks.push(t);
                var t = new this.tickRenderer(this.tickOptions);
                t.label = userTicks[i];
                t.showLabel = true;
                t.showMark = false;
                t.showGridline = false;
                t.setTick(tt+0.5, this.name);
                this._ticks.push(t);
            }
            // now add the last tick at the end
            var t = new this.tickRenderer(this.tickOptions);
            t.showLabel = false;
            t.showMark = true;
            t.setTick(tt+1, this.name);
            this._ticks.push(t);
        }

        // we don't have any ticks yet, let's make some!
        else {
            if (name == 'xaxis' || name == 'x2axis') {
                dim = this._plotDimensions.width;
            }
            else {
                dim = this._plotDimensions.height;
            }
            
            // if min, max and number of ticks specified, user can't specify interval.
            if (this.min != null && this.max != null && this.numberTicks != null) {
                this.tickInterval = null;
            }
            
            // if max, min, and interval specified and interval won't fit, ignore interval.
            if (this.min != null && this.max != null && this.tickInterval != null) {
                if (parseInt((this.max-this.min)/this.tickInterval, 10) != (this.max-this.min)/this.tickInterval) {
                    this.tickInterval = null;
                }
            }
        
            // find out how many categories are in the lines and collect labels
            var labels = [];
            var numcats = 0;
            var min = 0.5;
            var max, val;
            for (var i=0; i<this._series.length; i++) {
                var s = this._series[i];
                for (var j=0; j<s.data.length; j++) {
                    if (this.name == 'xaxis' || this.name == 'x2axis') {
                        val = s.data[j][0];
                    }
                    else {
                        val = s.data[j][1];
                    }
                    if ($.inArray(val, labels) == -1) {
                        numcats += 1;      
                        labels.push(val);
                    }
                }
            }
            
            // keep a reference to these tick labels to use for redrawing plot (see bug #57)
            this.ticks = labels;
            
            // now bin the data values to the right lables.
            for (var i=0; i<this._series.length; i++) {
                var s = this._series[i];
                for (var j=0; j<s.data.length; j++) {
                    if (this.name == 'xaxis' || this.name == 'x2axis') {
                        val = s.data[j][0];
                    }
                    else {
                        val = s.data[j][1];
                    }
                    // for category axis, force the values into category bins.
                    // we should have the value in the label array now.
                    var idx = $.inArray(val, labels)+1;
                    if (this.name == 'xaxis' || this.name == 'x2axis') {
                        s.data[j][0] = idx;
                    }
                    else {
                        s.data[j][1] = idx;
                    }
                }
            }
        
            max = numcats + 0.5;
            if (this.numberTicks == null) {
                this.numberTicks = 2*numcats + 1;
            }

            var range = max - min;
            this.min = min;
            this.max = max;
            var track = 0;
            
            // todo: adjust this so more ticks displayed.
            var maxVisibleTicks = parseInt(3+dim/20, 10);
            var skip = parseInt(numcats/maxVisibleTicks, 10);

            if (this.tickInterval == null) {

                this.tickInterval = range / (this.numberTicks-1);

            }
            // if tickInterval is specified, we will ignore any computed maximum.
            for (var i=0; i<this.numberTicks; i++){
                tt = this.min + i * this.tickInterval;
                var t = new this.tickRenderer(this.tickOptions);
                // if even tick, it isn't a category, it's a divider
                if (i/2 == parseInt(i/2, 10)) {
                    t.showLabel = false;
                    t.showMark = true;
                }
                else {
                    if (skip>0 && track<skip) {
                        t.showLabel = false;
                        track += 1;
                    }
                    else {
                        t.showLabel = true;
                        track = 0;
                    } 
                    t.label = t.formatter(t.formatString, labels[(i-1)/2]);
                    t.showMark = false;
                    t.showGridline = false;
                }
                if (!this.showTicks) {
                    t.showLabel = false;
                    t.showMark = false;
                }
                else if (!this.showTickMarks) {
                    t.showMark = false;
                }
                t.setTick(tt, this.name);
                this._ticks.push(t);
            }
        }
    };
    
    
})(jQuery);