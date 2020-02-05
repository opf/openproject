//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
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
})(jQuery);
