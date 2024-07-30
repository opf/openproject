//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
import {
  Inject,
  Injectable,
} from '@angular/core';
import { DOCUMENT } from '@angular/common';
import {
  BehaviorSubject,
  Observable,
} from 'rxjs';

export const ANIMATION_RATE_MS = 100;

@Injectable({ providedIn: 'root' })
export class TopMenuService {
  private hover = false;

  private menuIsOpen = false;

  private menuContainer = this.document.querySelector<HTMLElement>('.op-app-header');

  private active$ = new BehaviorSubject<HTMLElement|null>(null);

  constructor(@Inject(DOCUMENT) private document:Document) {
  }

  register():void {
    this.setupDropdownClick();
    this.closeOnBodyClick();
    this.accessibility();
    this.skipContentClickListener();
  }

  public activeDropdown$():Observable<HTMLElement|null> {
    return this.active$.asObservable();
  }

  // the entire menu gets closed, no hover possible afterwards
  public close():void {
    this.stopHover();
    this.closeAllItems();
    this.menuIsOpen = false;
    this.active$.next(null);
  }

  private skipContentClickListener():void {
    // Skip menu on content
    const skipLink = this.document.querySelector('#skip-navigation--content') as HTMLElement;
    skipLink?.addEventListener('click', () => {
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

  private accessibility():void {
    this
      .document
      .querySelectorAll('.op-app-menu--dropdown')
      .forEach((el) => el.setAttribute('aria-expanded', 'false'));
  }

  private toggleClick(dropdown:HTMLElement):void {
    if (this.menuIsOpen) {
      if (this.isOpen(dropdown)) {
        this.close();
      } else {
        this.openDropdown(dropdown);
      }
    } else {
      this.opening();
      this.openDropdown(dropdown);
    }
  }

  // somebody opens the menu via click, hover possible afterwards
  private opening():void {
    this.startHover();
    this.menuIsOpen = true;
  }

  private stopHover():void {
    this.hover = false;
    this.menuContainer?.classList.remove('hover');
  }

  private startHover():void {
    this.hover = true;
    this.menuContainer?.classList.add('hover');
  }

  private closeAllItems():void {
    this
      .openDropdowns()
      .forEach((item) => this.closeDropdown(item));
  }

  private closeOnBodyClick():void {
    const wrapper = document.getElementById('wrapper');
    if (!wrapper) {
      return;
    }

    wrapper.addEventListener('click', (evt) => {
      if (this.menuIsOpen && !this.openDropdowns()[0].contains(evt.target as HTMLElement)) {
        this.close();
      }
    }, true);
  }

  private openDropdowns():HTMLElement[] {
    const elements = this.menuContainer?.querySelectorAll<HTMLElement>('.op-app-menu--item_dropdown-open');
    return elements ? Array.from(elements) : [];
  }

  private dropdowns():HTMLElement[] {
    const elements = this.menuContainer?.querySelectorAll<HTMLElement>('.op-app-menu--item_has-dropdown');
    return elements ? Array.from(elements) : [];
  }

  private setupDropdownClick():void {
    this.dropdowns().forEach((el) => {
      const action = el.querySelector<HTMLElement>('.op-app-menu--item-action');
      action?.addEventListener('click', (evt) => {
        this.toggleClick(el);
        evt.preventDefault();
      });
    });
  }

  private isOpen(dropdown:HTMLElement):boolean {
    return dropdown.classList.contains('.op-app-menu--item_dropdown-open');
  }

  private isClosed(dropdown:HTMLElement):boolean {
    return !this.isOpen(dropdown);
  }

  private openDropdown(dropdown:HTMLElement):void {
    this.closeOtherItems(dropdown);
    this.slideAndFocus(dropdown, () => {
      this.active$.next(dropdown);
    });
  }

  private closeDropdown(dropdown:HTMLElement, immediate?:boolean):void {
    this.slideUp(dropdown, !!immediate);
    this.active$.next(null);
  }

  private closeOtherItems(dropdown:HTMLElement):void {
    this
      .openDropdowns()
      .forEach((other) => {
        if (other !== dropdown) {
          this.closeDropdown(other, true);
        }
      });
  }

  private slideAndFocus(dropdown:HTMLElement, callback:() => void):void {
    this.slideDown(dropdown, callback);
    setTimeout(() => this.focusFirstInputOrLink(dropdown), ANIMATION_RATE_MS);
  }

  private slideDown(dropdown:HTMLElement, callback:() => void):void {
    const toDrop = this.getDropdownContainer(dropdown);
    toDrop.setAttribute('aria-expanded', 'true');
    dropdown.classList.add('op-app-menu--item_dropdown-open');

    jQuery(toDrop)
      .slideDown(ANIMATION_RATE_MS, callback)
      .attr('aria-expanded', 'true');
  }

  private slideUp(dropdown:HTMLElement, immediate:boolean):void {
    const toDrop = this.getDropdownContainer(dropdown);
    toDrop.removeAttribute('aria-expanded');
    dropdown.classList.remove('op-app-menu--item_dropdown-open');

    if (immediate) {
      toDrop.style.display = 'none';
    } else {
      jQuery(toDrop).slideUp(ANIMATION_RATE_MS);
    }
  }

  // If there is ANY input, it will have precedence over links,
  // i.e. links will only get focused, if there is NO input whatsoever
  private focusFirstInputOrLink(dropdown:HTMLElement):void {
    const toDrop = this.getDropdownContainer(dropdown);
    const focusable = findAllFocusableElementsWithin(toDrop);
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

  private getDropdownContainer(dropdown:HTMLElement):HTMLElement {
    return dropdown.querySelector('.op-app-menu--dropdown') as HTMLElement;
  }
}
