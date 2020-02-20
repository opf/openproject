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

(function ($, undefined) {
  "use strict";

  function TopMenu (menu_container) {
    this.menu_container = $(menu_container);
    this.setup(menu_container);
  }

  TopMenu.prototype = $.extend(TopMenu.prototype, {
    setup: function () {
      this.hover = false;
      this.menuIsOpen = false;
      this.withHeadingFoldOutAtBorder();
      this.setupDropdownClick();
      this.registerEventHandlers();
      this.closeOnBodyClick();
      this.accessibility();
    },

    accessibility: function () {
      $(".drop-down > ul").attr("aria-expanded","false");
    },

    toggleClick: function (dropdown) {
      if (this.menuIsOpen) {
        if (this.isOpen(dropdown)) {
          this.closing();
        } else {
          this.open(dropdown);
        }
      } else {
        this.opening();
        this.open(dropdown);
      }
    },

    // somebody opens the menu via click, hover possible afterwards
    opening: function () {
      this.startHover();
      this.menuIsOpen = true;
      this.menu_container.trigger("openedMenu", this.menu_container);
    },

    // the entire menu gets closed, no hover possible afterwards
    closing: function () {
      this.stopHover();
      this.closeAllItems();
      this.menuIsOpen = false;
      this.menu_container.trigger("closedMenu", this.menu_container);
    },

    stopHover: function () {
      this.hover = false;
      this.menu_container.removeClass("hover");
    },

    startHover: function () {
      this.hover = true;
      this.menu_container.addClass("hover");
    },

    closeAllItems: function () {
      var self = this;
      this.openDropdowns().each(function (ix, item) {
        self.close($(item));
      });
    },

    closeOnBodyClick: function () {
      var self = this;
      document.getElementById('wrapper').addEventListener('click', function (evt) {
        if (self.menuIsOpen && !self.openDropdowns()[0].contains(evt.target)) {
          self.closing();
        }
      },  true);
    },

    openDropdowns: function () {
      return this.dropdowns().filter(".open");
    },

    dropdowns: function () {
      return this.menu_container.find("li.drop-down");
    },

    withHeadingFoldOutAtBorder: function () {
      var menu_start_position;
      if (this.menu_container.next().get(0) != undefined && (this.menu_container.next().get(0).tagName == 'H2')){
        menu_start_position = this.menu_container.next().innerHeight() + this.menu_container.next().position().top;
        this.menu_container.find("ul.menu-drop-down-container").css({ top: menu_start_position });
      }
      else if(this.menu_container.next().hasClass("wiki-content") && this.menu_container.next().children().next().first().get(0) != undefined && this.menu_container.next().children().next().first().get(0).tagName == 'H1'){
        var wiki_heading = this.menu_container.next().children().next().first();
        menu_start_position = wiki_heading.innerHeight() + wiki_heading.position().top;
        this.menu_container.find("ul.menu-drop-down-container").css({ top: menu_start_position });
      }
    },

    setupDropdownClick: function () {
      var self = this;
      this.dropdowns().each(function (ix, it) {
        $(it).click(function () {
          self.toggleClick($(this));
          return false;
        });
        $(it).on('touchstart', function(e) {
          // This shall avoid the hover event is fired,
          // which would otherwise lead to menu being closed directly after its opened.
          // Ignore clicks from within the dropdown
          if ($(e.target).closest('.menu-drop-down-container').length) {
            return true;
          }
          e.preventDefault();
          $(this).click();
          return false;
        });
      });
    },

    isOpen: function (dropdown) {
      return dropdown.filter(".open").length == 1;
    },

    isClosed: function (dropdown) {
      return !this.isOpen(dropdown);
    },

    open: function (dropdown) {
      this.dontCloseWhenUsing(dropdown);
      this.closeOtherItems(dropdown);
      this.slideAndFocus(dropdown, function() {
        dropdown.trigger("opened", dropdown);
      });
    },

    close: function (dropdown, immediate) {
      this.slideUp(dropdown, immediate);
      dropdown.trigger("closed", dropdown);
    },

    closeOtherItems: function (dropdown) {
      var self = this;
      this.openDropdowns().each(function (ix, it) {
        if ($(it) != $(dropdown)) {
          self.close($(it), true);
        }
      });
    },

    dontCloseWhenUsing: function (dropdown) {
      $(dropdown).find("li").click(function (event) {
        event.stopPropagation();
      });
      $(dropdown).bind("mousedown mouseup click", function (event) {
        event.stopPropagation();
      });
    },

    slideAndFocus: function (dropdown, callback) {
      this.slideDown(dropdown, callback);
      this.focusFirstInputOrLink(dropdown);
    },

    slideDown: function (dropdown, callback) {
      var toDrop = dropdown.find("> ul");
      dropdown.addClass("open");
      toDrop.slideDown(animationRate, callback).attr("aria-expanded","true");
    },

    slideUp: function (dropdown, immediate) {
      var toDrop = $(dropdown).find("> ul");
      dropdown.removeClass("open");

      if (immediate) {
        toDrop.hide();
      } else {
        toDrop.slideUp(animationRate);
      }

      toDrop.attr("aria-expanded","false");
    },

    // If there is ANY input, it will have precedence over links,
    // i.e. links will only get focussed, if there is NO input whatsoever
    focusFirstInputOrLink: function (dropdown) {
      var toFocus = dropdown.find("ul :input:visible:first");
      if (toFocus.length == 0) {
        toFocus = dropdown.find("ul a:visible:first");
      }
      // actually a simple focus should be enough.
      // The rest is only there to work around a rendering bug in webkit (as of Oct 2011),
      // occuring mostly inside the login/signup dropdown.
      toFocus.blur();
      setTimeout(function() {
        toFocus.focus();
      }, 10);
    },

    registerEventHandlers: function () {
      var self = this;
      var toggler = $("#main-menu-toggle");

      this.menu_container.on("closeDropDown", function (event) {
        self.close($(event.target));
      }).on("openDropDown", function (event) {
        self.open($(event.target));
      }).on("closeMenu", function () {
        self.closing();
      }).on("openMenu", function () {
        self.open(self.dropdowns().first());
        self.opening();
      });

      toggler.on("click", function() {  // click on hamburger icon is closing other menu
        self.closing();
      });
    }
  });

  // this holds all top menus currently active.
  // if one opens, all others are closed.
  var top_menus = [];
  $.fn.top_menu = function () {
    var new_menu;
    $(this).each(function () {
      new_menu = new TopMenu($(this));
      top_menus.forEach(function (menu) {
        menu.menu_container.on("openedMenu", function () {
          new_menu.closing();
        });
        new_menu.menu_container.on("openedMenu", function () {
          menu.closing();
        });
      });
      top_menus.push(new_menu);
    });
  };

}(jQuery));

function skipMenu() {
  // Skip to the breadcrumb or the first link in the toolbar or the first link in the content (homescreen)
  const selectors = '.first-breadcrumb-element a, .toolbar-container a:first-of-type, #content a:first-of-type';
  const visibleLink = jQuery(selectors)
                        .not(':hidden')
                        .first();

 if (visibleLink.length) {
   visibleLink.focus();
 }
}

jQuery(document).ready(function($) {
  $("#top-menu-items").top_menu();
});
