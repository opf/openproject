//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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
// See doc/COPYRIGHT.rdoc for more details.
//++
!(function($) {
  'use strict';

  var TOOLBAR_CLASS = '.toolbar',
      SUBMENU_CLASS = '.toolbar-submenu',
      SUBMENU_ITEM_CLASS = '.-with-submenu',
      SHOW_CLASS = 'show';

  // submenu handling
  $(function() {
    var toolbars = $(TOOLBAR_CLASS),
        body    = $('body');

    // bail if this is the WP list (has a custom implementation via directives)
    if (body.is('.controller-work_packages.action-index')) {
      return;
    };

    if (toolbars.length === 0) {
      return;
    };

    var triggers = toolbars.find(SUBMENU_ITEM_CLASS + ' > .button');
    triggers.on({
      'focus': function toggleSubmenu() {
        var submenu = $(this).siblings(SUBMENU_CLASS);
        submenu.toggleClass(SHOW_CLASS);
        if (submenu.attr('aria-hidden') === 'true') {
          submenu.attr('aria-hidden', 'false');
        } else {
          submenu.attr('aria-hidden', 'true');
        };
      },
      'click focus': function silenceEvent(e) {
        e.preventDefault();
        e.stopPropagation();
      },
      'blur': function() {
        $(this).siblings(SUBMENU_CLASS).removeClass(SHOW_CLASS);
      }
    });

    body.not(SUBMENU_CLASS).not(triggers).on('click', function(e) {
      $(SUBMENU_CLASS).removeClass(SHOW_CLASS);
    });
  });

  //scrollable toolbars
  $(function() {

    var win = $(window),
        main = $('#main'),
        toolbar = $('.toolbar.-scrollable'),
        timeout = null,
        update = function() {
          var fixated = win.scrollTop() > 159,
              smallToolbar = $('#wrapper').hasClass('hidden-navigation');
          toolbar.toggleClass('-fixed', fixated);
          toolbar.toggleClass('-wide', fixated && smallToolbar);
          timeout = null;
        };

    win.scroll(function(e) {
      if (timeout === null) {
        timeout = setTimeout(update, 50);
      }
    });

    update();
  });
}(jQuery));
