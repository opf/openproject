// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++
import { findAllFocusableElementsWithin } from 'core-app/shared/helpers/focus-helpers';

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

  skipContentClickListener():void {
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

  accessibility():void {
    jQuery('.op-app-menu--dropdown').attr('aria-expanded', 'false');
  }

  toggleClick(dropdown:JQuery):void {
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
  opening():void {
    this.startHover();
    this.menuIsOpen = true;
    this.menuContainer.trigger('openedMenu', this.menuContainer);
  }

  // the entire menu gets closed, no hover possible afterwards
  closing():void {
    this.stopHover();
    this.closeAllItems();
    this.menuIsOpen = false;
    this.menuContainer.trigger('closedMenu', this.menuContainer);
  }

  stopHover():void {
    this.hover = false;
    this.menuContainer.removeClass('hover');
  }

  startHover():void {
    this.hover = true;
    this.menuContainer.addClass('hover');
  }

  closeAllItems():void {
    this.openDropdowns().each((ix, item) => {
      this.close(jQuery(item));
    });
  }

  closeOnBodyClick():void {
    const wrapper = document.getElementById('wrapper');
    if (!wrapper) {
      return;
    }

    wrapper.addEventListener('click', (evt) => {
      if (this.menuIsOpen && !this.openDropdowns()[0].contains(evt.target as HTMLElement)) {
        this.closing();
      }
    }, true);
  }

  openDropdowns() {
    return this.menuContainer.find('.op-app-menu--item_dropdown-open');
  }

  dropdowns() {
    return this.menuContainer.find('.op-app-menu--item_has-dropdown');
  }

  withHeadingFoldOutAtBorder():void {
    let menuStartPosition;
    const next = this.menuContainer.next();
    const wikiHeading = this.menuContainer.next().children().next().first();
    if (next.get(0)?.tagName === 'H2') {
      menuStartPosition = this.menuContainer.next().innerHeight()! + this.menuContainer.next().position().top;
      this.menuContainer.find('.op-app-menu--body').css({ top: menuStartPosition });
    } else if (this.menuContainer.next().hasClass('wiki-content')
      && wikiHeading.get(0)?.tagName === 'H1') {
      menuStartPosition = wikiHeading.innerHeight()! + wikiHeading.position().top;
      this.menuContainer.find('.op-app-menu--body').css({ top: menuStartPosition });
    }
  }

  setupDropdownClick():void {
    this.dropdowns().each((ix, it) => {
      jQuery(it).find('.op-app-menu--item-action').click((e) => {
        this.toggleClick(jQuery(it));
        e.preventDefault();
      });
    });
  }

  isOpen(dropdown:JQuery):boolean {
    return dropdown.filter('.op-app-menu--item_dropdown-open').length === 1;
  }

  isClosed(dropdown:JQuery):boolean {
    return !this.isOpen(dropdown);
  }

  open(dropdown:JQuery):void {
    this.dontCloseWhenUsing(dropdown);
    this.closeOtherItems(dropdown);
    this.slideAndFocus(dropdown, () => {
      dropdown.trigger('opened', dropdown);
    });
  }

  close(dropdown:JQuery, immediate?:boolean):void {
    this.slideUp(dropdown, !!immediate);
    dropdown.trigger('closed', dropdown);
    this.removeStoppingOfEventPropagation(dropdown);
  }

  closeOtherItems(dropdown:JQuery):void {
    this.openDropdowns().each((ix, it) => {
      if (jQuery(it) !== jQuery(dropdown)) {
        this.close(jQuery(it), true);
      }
    });
  }

  dontCloseWhenUsing(dropdown:JQuery):void {
    setTimeout(() => {
      jQuery(dropdown).find('li').click((event) => {
        event.stopPropagation();
      });

      jQuery(dropdown).bind('mousedown mouseup click', (event) => {
        event.stopPropagation();
      });
    }, 0);
  }

  removeStoppingOfEventPropagation(dropdown:JQuery):void {
    jQuery(dropdown).find('li').unbind('click');
    jQuery(dropdown).unbind('mousedown mouseup click');
  }

  slideAndFocus(dropdown:JQuery, callback:any) {
    this.slideDown(dropdown, callback);
    setTimeout(() => this.focusFirstInputOrLink(dropdown), ANIMATION_RATE_MS);
  }

  slideDown(dropdown:JQuery, callback:any) {
    const toDrop = dropdown.find('.op-app-menu--dropdown');
    dropdown.addClass('op-app-menu--item_dropdown-open');
    toDrop.slideDown(ANIMATION_RATE_MS, callback).attr('aria-expanded', 'true');
  }

  slideUp(dropdown:JQuery, immediate:boolean):void {
    const toDrop = jQuery(dropdown).find('.op-app-menu--dropdown');
    dropdown.removeClass('op-app-menu--item_dropdown-open');

    if (immediate) {
      toDrop.hide();
    } else {
      toDrop.slideUp(ANIMATION_RATE_MS);
    }

    toDrop.attr('aria-expanded', 'false');
  }

  // If there is ANY input, it will have precedence over links,
  // i.e. links will only get focused, if there is NO input whatsoever
  focusFirstInputOrLink(dropdown:JQuery):void {
    const focusable = findAllFocusableElementsWithin(dropdown.find('.op-app-menu--dropdown')[0]);
    const toFocus = focusable[0] as HTMLElement;
    if (!toFocus) {
      return;
    }
    // actually a simple focus should be enough.
    // The rest is only there to work around a rendering bug in webkit (as of Oct 2011),
    // occurring mostly inside the login/signup dropdown.
    toFocus.blur();
    setTimeout(() => {
      toFocus.focus();
    }, 10);
  }

  registerEventHandlers():void {
    const toggler = jQuery('#main-menu-toggle');

    this.menuContainer.on('closeDropDown', (event:Event) => {
      this.close(jQuery(event.target as HTMLElement));
    }).on('openDropDown', (event) => {
      this.open(jQuery(event.target));
    }).on('closeMenu', () => {
      this.closing();
    }).on('openMenu', () => {
      this.open(this.dropdowns().first());
      this.opening();
    });

    toggler.on('click', () => { // click on hamburger icon is closing other menu
      this.closing();
    });
  }
}
