//-- copyright
// OpenProject is a project management system.
//
// Copyright (C) 2012-2013 the OpenProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

(function( $ ){
  $.fn.nextElementInDom = function(selector, options) {
    return $(this).findElementInDom(selector, $.extend(options, { direction: 'front' }));
  };

  $.fn.previousElementInDom = function(selector, options) {
    return $(this).findElementInDom(selector, $.extend(options, { direction: 'back' }));
  };

  $.fn.findElementInDom = function(selector, options) {
    var defaults, parent, direction, found, children;
    defaults = { stopAt : 'body', direction: 'front' };
    options = $.extend(defaults, options);

    parent = $(this).parent();

    direction = (options.direction === 'front') ? ":gt" : ":lt";
    children = parent.children(direction + "(" + $(this).index() + ")");
    children = (options.direction === 'front') ? children : children.reverse();

    found = parent.children(direction + "(" + $(this).index() + ")").find(selector).filter(":first");

    if (found.length > 0) {
      return found;
    } else {
      if (parent.length === 0 || parent.is(options.stopAt)) {
        return $([])
      } else {
        return parent.findElementInDom(selector, options);
      }
    }
  };

})( jQuery );