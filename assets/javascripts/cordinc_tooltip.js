/*
 * Copyright (c) 2009 Charles Cordingley (www.cordinc.com)
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
 
/*
 * cordinc_tooltip.js, v1.0.2 - 27 August 2008
 * For help see www.cordinc.com/projects/tooltips.html
 */
var Tooltip = Class.create({
  initialize: function(target, tooltip) {
    var options = Object.extend({
      start_effect: function(element) {},
      end_effect: function(element) {},
      zindex: 1000,
      offset: {x:0, y:0},
      hook: {target:'topRight', tip:'bottomLeft'},
      trigger: false, 
      DOM_location: false,
      className: false,
      delay: {}
    }, arguments[2] || {});
    this.target = $(target);
    this.show_at = (options.show_at_id !== undefined) ? $(options.show_at_id) : undefined
    this.tooltip = $(tooltip);
    this.options = options;
    this.event_target = this.options.trigger?$(this.options.trigger):this.target;

    if (this.options.className) {
      this.tooltip.addClassName(this.options.className);
    }
    this.tooltip.hide();
    this.display=false;

    this.mouse_over = this.displayTooltip.bindAsEventListener(this);
    this.mouse_out = this.removeTooltip.bindAsEventListener(this);
    this.event_target.observe("mouseover", this.mouse_over);
    this.event_target.observe("mouseout", this.mouse_out);
  },

  displayTooltip: function(event){
    event.stop();
    
    if (this.display) {return;}
    if (this.options.delay.start) {
      var self = this;
      this.timer_id = setTimeout(function(){self.timer_id = false; self.showTooltip(event);}, this.options.delay.start*1000);
    } else {
      this.showTooltip(event);
    }
  },

  showTooltip: function(event) {
    var show_at = (this.show_at !== undefined) ? this.show_at : this.target
    this.display=true;
    position = this.positionTooltip(event);
    
    this.clone = this.tooltip.cloneNode(true);
    parentId = this.options.DOM_location?$(this.options.DOM_location.parentId):show_at.parentNode;
    successorId = this.options.DOM_location?$(this.options.DOM_location.successorId):show_at.target;
    parentId.insertBefore(this.clone, successorId);
    
    this.clone.setStyle({
      position: 'absolute',
      top: position.top + "px",
      left: position.left + "px",
      display: "inline",
      zIndex:this.options.zindex,
      /* fix for ur dashboard */
      visibility: 'visible',
      width: "400px"
		});
                      
    if (this.options.start_effect) {
        this.options.start_effect(this.clone);
    }
  },

  positionTooltip: function(event) {
    target_position = this.target.cumulativeOffset();
    
    tooltip_dimensions = this.tooltip.getDimensions();
    target_dimensions = this.target.getDimensions();

    this.positionModify(target_position, target_dimensions, this.options.hook.target, 1);
    this.positionModify(target_position, tooltip_dimensions, this.options.hook.tip, -1);

    target_position.top += this.options.offset.y;
    target_position.left += this.options.offset.x;

    return target_position; 
  },

  positionModify: function(position, box, corner, neg) {
    if (corner == 'topRight') {
      position.left += box.width*neg;
    } else if (corner == 'topLeft') {
    } else if (corner == 'bottomLeft') {
      position.top += box.height*neg;
    } else if (corner == 'bottomRight') {
      position.top += box.height*neg;
      position.left += box.width*neg;
    } else if (corner == 'topMid') {
      position.left += (box.width/2)*neg;
    } else if (corner == 'leftMid') {
      position.top += (box.height/2)*neg;
    } else if (corner == 'bottomMid') {
      position.top += box.height*neg;
      position.left += (box.width/2)*neg;
    } else if (corner == 'rightMid') {
      position.top += (box.height/2)*neg;
      position.left += box.width*neg;
    }
  },

  removeTooltip: function(event) {
    if (this.timer_id) {
      clearTimeout(this.timer_id);
      this.timer_id = false;
      return;
    } 

    if (this.options.end_effect) {
        this.options.end_effect(this.clone);
    } 
    
    if (this.options.delay.end) {
      var self = this;
      setTimeout(function(){self.clearTooltip();}, this.options.delay.end*1000);
    } else {
      this.clearTooltip();
    }
  },
  
  clearTooltip: function() {
		if (this.clone !== undefined && this.clone !== null) {
    	this.clone.remove();
    	this.clone = null;
    	this.display=false;
		}
  },

  destroy: function() {
    this.event_target.stopObserving("mouseover", this.mouse_over);
    this.event_target.stopObserving("mouseout", this.mouse_out);
    this.clearTooltip();
  }
})