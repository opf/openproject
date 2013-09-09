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

jQuery.fn.reverse = [].reverse;
(function($){
  $.fn.adjustBreadcrumbToWindowSize = function(){
    var breadcrumbElements = this.find(' > li');
    var breadcrumb = this;
    var lastChanged;

    if (breadcrumb.breadcrumbOutOfBounds()){
      breadcrumbElements.each(function(index) {
        if (breadcrumb.breadcrumbOutOfBounds()){
          if (!$(this).find(' > a').hasClass('nocut')){
              $(this).addClass('cutme ellipsis');
          }
        }
        else {
          return false;
        }
      });
    }
    else {
      breadcrumbElements.reverse().each(function(index) {
        if (!breadcrumb.breadcrumbOutOfBounds()){
          if (!$(this).find(' > a').hasClass('nocut')){
            $(this).removeClass('cutme ellipsis');
            lastChanged = $(this);
          }
        }
      });

      if (breadcrumb.breadcrumbOutOfBounds()){
        if (lastChanged != undefined){
          lastChanged.addClass('cutme ellipsis');
          return false;
        }
      }
    }
  };

  $.fn.breadcrumbOutOfBounds = function(){
    var lastElement = this.find(' > li').last();
    if (lastElement) {
      var rightCorner = lastElement.width() + lastElement.offset().left;
      var windowSize = jQuery(window).width();

      if ((Math.max(1000,windowSize) - rightCorner) < 10) {
        return true;
      }
      else {
        return false;
      }
    } else {
      return false;
    }
  };
})(jQuery)
