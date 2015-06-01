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
      TOOLBAR_ITEM_CLASS = '.toolbar-item',
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

    body.not(SUBMENU_CLASS).not(triggers).on('click', function() {
      $(SUBMENU_CLASS).removeClass(SHOW_CLASS);
    });

    $(SUBMENU_CLASS + '> .toolbar-item > a').on('click focus', function() {
      $(this).closest(SUBMENU_CLASS).addClass(SHOW_CLASS).attr('aria-hidden', false);
    });
  });

  //scrollable toolbars
  $(function() {

    var win = $(window),
        toolbar = $('.toolbar.-scrollable'),
        timeout = null,
        update = function() {
          var fixated = win.scrollTop() > 150,
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

  // key binding
  $(function() {
    var topLevelFocusItems =  $(TOOLBAR_CLASS).find('.toolbar-item > .button'),
        hasSubmenu = function(link) {
          return link.parent(TOOLBAR_ITEM_CLASS).is(SUBMENU_ITEM_CLASS);
        },
        focusLastItem = function(link) {
          var previous = link.parent(TOOLBAR_ITEM_CLASS).prev(TOOLBAR_ITEM_CLASS);
          if (previous) {
            previous.find('> .button').focus();
          }
        },
        focusNextItem = function(link) {
          var next = link.parent(TOOLBAR_ITEM_CLASS).next(TOOLBAR_ITEM_CLASS);
          if (next) {
            next.find('> .button').focus();
          }
        },
        nextSubmenuItem = function(link) {
          if (!hasSubmenu(link)) {
            return;
          }
          var menu = link.siblings(SUBMENU_CLASS);
          menu.attr('aria-hidden', false).addClass(SHOW_CLASS);
          menu.find(TOOLBAR_ITEM_CLASS).find('a').attr('tabindex', 0).first().focus();
        },
        previousSubmenuItem = function(link) {
          if(!hasSubmenu(link)) {
            return;
          }
          var menu = link.siblings(SUBMENU_CLASS);
          menu.attr('aria-hidden', false).addClass(SHOW_CLASS);
          menu.find(TOOLBAR_ITEM_CLASS).find('a').attr('tabindex', 0).last().focus();
        },
        closeSubmenu = function(link) {
          if(!hasSubmenu(link)) {
            return;
          }
          var menu = link.siblings(SUBMENU_CLASS);
          menu.removeClass(SHOW_CLASS).attr('aria-hidden', true);
        }
    topLevelFocusItems.on('keydown', function(e) {
      var link = $(this);
      switch(e.keyCode) {
        // escape
        case 27:
          closeSubmenu(link);
          break;
        // left
        case 37:
          e.preventDefault();
          focusLastItem(link);
          break;
        // up
        case 38:
          e.preventDefault();
          previousSubmenuItem(link);
          break;
        // right
        case 39:
          e.preventDefault();
          focusNextItem(link);
          break;
        // down
        case 40:
          e.preventDefault();
          nextSubmenuItem(link);
          break;

        default:
          break;
      }
    });

    var submenuFocusItems = $(SUBMENU_CLASS + ' > ' + TOOLBAR_ITEM_CLASS + ' > a', TOOLBAR_CLASS),
        closeParentSubmenu =  function(link) {
          var menu =  link.closest(SUBMENU_CLASS);
          menu.parent(TOOLBAR_ITEM_CLASS).find('> .button').focus();
        },
        focusLastSubmenuItem = function(link) {
          var lastItem = link.parent(TOOLBAR_ITEM_CLASS).prev(TOOLBAR_ITEM_CLASS);
          if (lastItem.hasClass('-divider')) {
            lastItem = lastItem.prev(TOOLBAR_ITEM_CLASS);
          };
          if (lastItem) {
            lastItem.find('a').focus();
          } else {
            var menu = link.closest(SUBMENU_CLASS);
            menu.find(TOOLBAR_ITEM_CLASS + ' > a').last().focus();
          }
        },
        focusNextSubmenuItem = function(link) {
          var nextItem = link.parent(TOOLBAR_ITEM_CLASS).next(TOOLBAR_ITEM_CLASS);
          if (nextItem.hasClass('-divider')) {
            nextItem = nextItem.next(TOOLBAR_ITEM_CLASS);
          };
          if (nextItem) {
            nextItem.find('a').focus();
          } else {
            var menu = link.closest(SUBMENU_CLASS);
            menu.find(TOOLBAR_ITEM_CLASS + ' > a').first().focus();
          }
        }
    submenuFocusItems.on('keydown', function(e) {
      var link = $(this);
      switch(e.keyCode) {
        // escape
        case 27:
          e.preventDefault();
          closeParentSubmenu(link);
          break;
        // up
        case 38:
          e.preventDefault();
          focusLastSubmenuItem(link);
          break;
        // down
        case 40:
          e.preventDefault();
          focusNextSubmenuItem(link);
          break;
      }
    });
  })
}(jQuery));
