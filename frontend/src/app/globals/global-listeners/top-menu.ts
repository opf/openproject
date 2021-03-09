//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++
export const ANIMATION_RATE_MS = 100;

export class TopMenu {
  private hover = false;
  private menuIsOpen = false;

  constructor(readonly menuContainer:JQuery) {
    this.withHeadingFoldOutAtBorder();
    this.setupDropdownClick();
    this.registerEventHandlers();
    this.closeOnBodyClick();
    this.accessibility();
    this.skipContentClickListener();
  }

  skipContentClickListener() {
    // Skip menu on content
    jQuery('#skip-navigation--content').on('click', () => {
      // Skip to the breadcrumb or the first link in the toolbar or the first link in the content (homescreen)
      const selectors = '.first-breadcrumb-element a, .toolbar-container a:first-of-type, #content a:first-of-type';
      const visibleLink = jQuery(selectors)
        .not(':hidden')
        .first();

      if (visibleLink.length) {
        visibleLink.trigger('focus');
      }
    });
  }

  accessibility() {
    jQuery(".drop-down > ul").attr("aria-expanded", "false");
  }

  toggleClick(dropdown:JQuery) {
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
  }

  // somebody opens the menu via click, hover possible afterwards
  opening() {
    this.startHover();
    this.menuIsOpen = true;
    this.menuContainer.trigger("openedMenu", this.menuContainer);
  }

  // the entire menu gets closed, no hover possible afterwards
  closing() {
    this.stopHover();
    this.closeAllItems();
    this.menuIsOpen = false;
    this.menuContainer.trigger("closedMenu", this.menuContainer);
  }

  stopHover() {
    this.hover = false;
    this.menuContainer.removeClass("hover");
  }

  startHover() {
    this.hover = true;
    this.menuContainer.addClass("hover");
  }

  closeAllItems() {
    this.openDropdowns().each((ix, item) => {
      this.close(jQuery(item));
    });
  }

  closeOnBodyClick() {
    const self = this;
    const wrapper = document.getElementById('wrapper');

    if (!wrapper) {
      return;
    }

    wrapper.addEventListener('click', function (evt) {
      if (self.menuIsOpen && !self.openDropdowns()[0].contains(evt.target as HTMLElement)) {
        self.closing();
      }
    }, true);
  }

  openDropdowns() {
    return this.dropdowns().filter(".open");
  }

  dropdowns() {
    return this.menuContainer.find("li.drop-down");
  }

  withHeadingFoldOutAtBorder() {
    var menu_start_position;
    if (this.menuContainer.next().get(0) !== undefined && (this.menuContainer.next().get(0).tagName === 'H2')) {
      menu_start_position = this.menuContainer.next().innerHeight()! + this.menuContainer.next().position().top;
      this.menuContainer.find("ul.menu-drop-down-container").css({ top: menu_start_position });
    } else if (this.menuContainer.next().hasClass("wiki-content") &&
      this.menuContainer.next().children().next().first().get(0) !== undefined &&
      this.menuContainer.next().children().next().first().get(0).tagName === 'H1') {
      var wiki_heading = this.menuContainer.next().children().next().first();
      menu_start_position = wiki_heading.innerHeight()! + wiki_heading.position().top;
      this.menuContainer.find("ul.menu-drop-down-container").css({ top: menu_start_position });
    }
  }

  setupDropdownClick() {
    var self = this;
    this.dropdowns().each(function (ix, it) {
      jQuery(it).click(function () {
        self.toggleClick(jQuery(this));
        return false;
      });
      jQuery(it).on('touchstart', function (e) {
        // This shall avoid the hover event is fired,
        // which would otherwise lead to menu being closed directly after its opened.
        // Ignore clicks from within the dropdown
        if (jQuery(e.target).closest('.menu-drop-down-container').length) {
          return true;
        }
        e.preventDefault();
        jQuery(this).click();
        return false;
      });
    });
  }

  isOpen(dropdown:JQuery) {
    return dropdown.filter(".open").length === 1;
  }

  isClosed(dropdown:JQuery) {
    return !this.isOpen(dropdown);
  }

  open(dropdown:JQuery) {
    this.dontCloseWhenUsing(dropdown);
    this.closeOtherItems(dropdown);
    this.slideAndFocus(dropdown, function () {
      dropdown.trigger("opened", dropdown);
    });
  }

  close(dropdown:JQuery, immediate?:any) {
    this.slideUp(dropdown, immediate);
    dropdown.trigger("closed", dropdown);
  }

  closeOtherItems(dropdown:JQuery) {
    var self = this;
    this.openDropdowns().each(function (ix, it) {
      if (jQuery(it) !== jQuery(dropdown)) {
        self.close(jQuery(it), true);
      }
    });
  }

  dontCloseWhenUsing(dropdown:JQuery) {
    jQuery(dropdown).find("li").click(function (event) {
      event.stopPropagation();
    });
    jQuery(dropdown).bind("mousedown mouseup click", function (event) {
      event.stopPropagation();
    });
  }

  slideAndFocus(dropdown:JQuery, callback:any) {
    this.slideDown(dropdown, callback);
    this.focusFirstInputOrLink(dropdown);
  }

  slideDown(dropdown:JQuery, callback:any) {
    var toDrop = dropdown.find("> ul");
    dropdown.addClass("open");
    toDrop.slideDown(ANIMATION_RATE_MS, callback).attr("aria-expanded", "true");
  }

  slideUp(dropdown:JQuery, immediate:any) {
    var toDrop = jQuery(dropdown).find("> ul");
    dropdown.removeClass("open");

    if (immediate) {
      toDrop.hide();
    } else {
      toDrop.slideUp(ANIMATION_RATE_MS);
    }

    toDrop.attr("aria-expanded", "false");
  }

  // If there is ANY input, it will have precedence over links,
  // i.e. links will only get focussed, if there is NO input whatsoever
  focusFirstInputOrLink(dropdown:JQuery) {
    var toFocus = dropdown.find("ul :input:visible:first");
    if (toFocus.length === 0) {
      toFocus = dropdown.find("ul a:visible:first");
    }
    // actually a simple focus should be enough.
    // The rest is only there to work around a rendering bug in webkit (as of Oct 2011),
    // occuring mostly inside the login/signup dropdown.
    toFocus.blur();
    setTimeout(function () {
      toFocus.focus();
    }, 10);
  }

  registerEventHandlers() {
    const toggler = jQuery("#main-menu-toggle");

    this.menuContainer.on("closeDropDown", (event) => {
      this.close(jQuery(event.target));
    }).on("openDropDown", (event) => {
      this.open(jQuery(event.target));
    }).on("closeMenu", () => {
      this.closing();
    }).on("openMenu", () => {
      this.open(this.dropdowns().first());
      this.opening();
    });

    toggler.on("click", () => {  // click on hamburger icon is closing other menu
      this.closing();
    });
  }
}
