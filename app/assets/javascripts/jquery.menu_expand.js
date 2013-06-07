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

/*
 * Expands Redmine's current menu
 */
(function($) {
  $.menu_expand = function(options) {
      var opts = $.extend({
          menu: '#main-menu',
          selectedClass: '.selected'
      }, options);

      if (options.item !== undefined) {
        options.item.toggleClass("open").siblings("ul").show();
      }
      else {
        $(opts.menu +' '+ opts.selectedClass).toggleClass("open").siblings("ul").show();
      }

  }})(jQuery);
