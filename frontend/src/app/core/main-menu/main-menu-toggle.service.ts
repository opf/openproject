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

import { Injectable, Injector, inject } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { queryVisible } from 'core-app/shared/helpers/dom-helpers';

@Injectable({ providedIn: 'root' })
export class MainMenuToggleService {
  injector = inject(Injector);
  readonly deviceService = inject(DeviceService);

  private elementWidth:number;

  private elementMinWidth = 11;

  private readonly defaultWidth:number = 280;

  private readonly localStorageKey:string = 'openProject-mainMenuWidth';

  private readonly localStorageStateKey:string = 'openProject-mainMenuCollapsed';

  readonly currentProject = inject(CurrentProjectService);

  private htmlNode = document.getElementsByTagName('html')[0];

  private get mainMenu():HTMLElement|null {
    return document.querySelector<HTMLElement>('#main-menu');
  }

  // Notes all changes of the menu size (currently needed in wp-resizer.component.ts)
  private changeData = new BehaviorSubject<number|undefined>(undefined);
  public changeData$ = this.changeData.asObservable();

  private wasHiddenDueToResize = false;

  private wasCollapsedByUser = false;

  constructor() {
    this.initializeMenu();
    // Add resize event listener
    window.addEventListener('resize', this.onWindowResize.bind(this));
  }

  public initializeMenu():void {
    const mainMenu = this.mainMenu;
    if (!mainMenu) {
      return;
    }

    this.elementWidth = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string, 10);
    const menuCollapsed = window.OpenProject.guardedLocalStorage(this.localStorageStateKey) === 'true';

    // Set the initial value of the collapse tracking flag
    this.wasCollapsedByUser = menuCollapsed;

    if (!this.elementWidth) {
      this.saveWidth(mainMenu.offsetWidth);
    } else if (menuCollapsed) {
      this.closeMenu();
    } else {
      this.setWidth();
    }

    this.adjustMenuVisibility();
  }

  private onWindowResize():void {
    this.adjustMenuVisibility();
  }

  private adjustMenuVisibility():void {
    if (window.innerWidth >= 1012) {
      // On larger screens, reopen the menu if it was hidden only due to screen resizing
      if (this.wasHiddenDueToResize && !this.wasCollapsedByUser) {
        this.setWidth(this.defaultWidth);
        this.wasHiddenDueToResize = false; // Reset the flag since the menu is now shown
      }
    } else if (this.showNavigation) {
        this.closeMenu();
        this.wasHiddenDueToResize = true; // Indicate that the menu was hidden due to resize
    }
  }

  public toggleNavigation(event?:Event):void {
    if (event) {
      event.stopPropagation();
      event.preventDefault();
    }

    // Update the user collapse flag and clear `wasHiddenDueToResize`
    this.wasCollapsedByUser = this.showNavigation;
    this.wasHiddenDueToResize = false; // Reset because a manual toggle overrides any resize behavior

    if (this.showNavigation) {
      this.closeMenu();
    } else {
      this.openMenu();
    }

    // Save the collapsed state in localStorage
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, String(!this.showNavigation));
    // Set focus on first visible main menu item.
    // This needs to be called after AngularJS has rendered the menu, which happens some when after(!) we leave this
    // method here. So we need to set the focus after a timeout.
    setTimeout(() => {
      const mainMenu = this.mainMenu;
      if (!mainMenu) return;
      const firstVisibleMenuItem = queryVisible('[class*="-menu-item"]', mainMenu)[0];
      firstVisibleMenuItem?.focus();
    }, 500);
  }

  public closeMenu():void {
    this.setWidth(0);
    this.changeData.next(0);
    document.querySelectorAll<HTMLElement>('.searchable-menu--search-input').forEach((input) => input.blur());
  }

  public openMenu():void {
    const width = parseInt(window.OpenProject.guardedLocalStorage(this.localStorageKey) as string, 10) || this.defaultWidth;
    this.setWidth(width);
    this.changeData.next(width);
  }

  public setWidth(width?:number):void {
    if (width !== undefined) {
      this.elementWidth = width;
    }

    const mainMenu = this.mainMenu;
    if (!mainMenu) return;

    // Apply the width directly to the main menu
    mainMenu.style.width = `${this.elementWidth}px`;

    // Apply to root CSS variable for any related layout adjustments
    this.htmlNode.style.setProperty('--main-menu-width', `${this.elementWidth}px`);

    // Check if menu is open or closed and apply CSS class if needed
    this.toggleClassHidden();
    this.snapBack();

    // Save the width if it's open
    if (this.elementWidth > 0) {
      window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    }
  }

  public saveWidth(width?:number):void {
    this.setWidth(width);
    window.OpenProject.guardedLocalStorage(this.localStorageKey, String(this.elementWidth));
    window.OpenProject.guardedLocalStorage(this.localStorageStateKey, String(this.elementWidth === 0));
  }

  public get showNavigation():boolean {
    return this.elementWidth >= this.elementMinWidth;
  }

  private snapBack():void {
    if (this.elementWidth < this.elementMinWidth) {
      this.elementWidth = 0;
    }
  }

  private toggleClassHidden():void {
    const isHidden = this.elementWidth < this.elementMinWidth;
    const hideElements = document.querySelectorAll<HTMLElement>('.can-hide-navigation');
    hideElements.forEach((hideElement) => hideElement.classList.toggle('hidden-navigation', isHidden));
  }
}
