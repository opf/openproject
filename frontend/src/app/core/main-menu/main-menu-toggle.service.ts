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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, computed, debounced, effect, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { distinctUntilChanged, fromEvent, map, skip, startWith } from 'rxjs';
import { CookieService } from 'ngx-cookie-service';
import { DeviceService } from 'core-app/core/browser/device.service';
import { queryVisible } from 'core-app/shared/helpers/dom-helpers';

@Injectable({ providedIn: 'root' })
export class MainMenuToggleService {
  private readonly deviceService = inject(DeviceService);
  private readonly cookieService = inject(CookieService);

  private readonly defaultWidth = 280;

  private readonly minOpenWidth = 11;

  private readonly widthStorageKey = 'openProject-mainMenuWidth';

  private readonly collapsedStorageKey = 'openProject-mainMenuCollapsed';

  private readonly cookieName = 'op_main_menu_width';

  private readonly openWidth = signal(this.defaultWidth);

  private readonly collapsedByUser = signal(false);

  private readonly hiddenByViewport = signal(false);

  private readonly hydrated = signal(false);

  // The server lays out the next page from this value before any script
  // runs (OP-20429). A collapse forced by a narrow window is not the user's
  // choice, so it is not part of it.
  readonly preferredWidth = computed(() => (this.collapsedByUser() ? 0 : this.openWidth()));

  // The requested width, not the measured one: on narrow windows the
  // stylesheet gives an open menu its own width.
  readonly width = computed(() => (this.hiddenByViewport() ? 0 : this.preferredWidth()));

  readonly isOpen = computed(() => this.width() > 0);

  private readonly debouncedPreferredWidth = debounced(
    () => (this.hydrated() ? this.preferredWidth() : undefined),
    50,
  );

  private get mainMenu():HTMLElement|null {
    return document.querySelector<HTMLElement>('#main-menu');
  }

  constructor() {
    effect(() => this.render(this.width()));

    effect(() => {
      const width = this.debouncedPreferredWidth.value();
      if (width !== undefined) this.writeWidthCookie(width);
    });

    this.syncWithPage();

    // Only a changed innerWidth matters: a virtual keyboard opening resizes
    // the visual viewport alone and must not close the menu.
    fromEvent(window, 'resize')
      .pipe(
        map(() => window.innerWidth),
        startWith(window.innerWidth),
        distinctUntilChanged(),
        skip(1),
        takeUntilDestroyed(),
      )
      .subscribe(() => this.onViewportWidthChange());
  }

  // Turbo replaces the body without touching this service, so every page
  // with a main menu has to be brought back in line with the state.
  public syncWithPage():void {
    if (!this.mainMenu) return;

    this.readPreference();
    this.storePreference();
    this.onViewportWidthChange();
    this.hydrated.set(true);
    this.render(this.width());
  }

  public toggle():void {
    if (!this.mainMenu) return;

    if (this.isOpen()) {
      this.collapsedByUser.set(true);
    } else {
      this.collapsedByUser.set(false);
      this.hiddenByViewport.set(false);
    }
    this.storePreference();

    // The menu items only become focusable once the menu has been rendered open.
    setTimeout(() => {
      const mainMenu = this.mainMenu;
      if (!mainMenu) return;
      const firstVisibleMenuItem = queryVisible('[class*="-menu-item"]', mainMenu)[0];
      firstVisibleMenuItem?.focus();
    }, 500);
  }

  public resizeTo(width:number):void {
    if (width < this.minOpenWidth) {
      this.collapsedByUser.set(true);
      this.openWidth.set(this.defaultWidth);
    } else {
      this.openWidth.set(Math.round(width));
      this.collapsedByUser.set(false);
    }
    this.storePreference();
  }

  private onViewportWidthChange():void {
    if (!this.deviceService.isSmallDesktop) {
      this.hiddenByViewport.set(false);
    } else if (this.isOpen()) {
      this.hiddenByViewport.set(true);
    }
  }

  // localStorage is written synchronously and re-read on every page, so it
  // also carries changes made in another tab. The cookie is written late and
  // only stands in before the first page has been read.
  private readPreference():void {
    const storedWidth = this.parseOpenWidth(window.OpenProject.guardedLocalStorage(this.widthStorageKey));
    const storedCollapsed = window.OpenProject.guardedLocalStorage(this.collapsedStorageKey);
    let fallbackWidth = this.openWidth();
    let fallbackCollapsed = this.collapsedByUser();

    if (!this.hydrated()) {
      const cookie = this.cookieService.get(this.cookieName);
      fallbackWidth = this.parseOpenWidth(cookie) ?? this.defaultWidth;
      fallbackCollapsed = cookie === '0';
    }

    this.openWidth.set(storedWidth ?? fallbackWidth);
    this.collapsedByUser.set(storedCollapsed ? storedCollapsed === 'true' : fallbackCollapsed);
  }

  private storePreference():void {
    window.OpenProject.guardedLocalStorage(this.widthStorageKey, String(this.openWidth()));
    window.OpenProject.guardedLocalStorage(this.collapsedStorageKey, String(this.collapsedByUser()));
  }

  private parseOpenWidth(value:string|void):number|undefined {
    if (!value || !/^\d+$/.test(value)) return undefined;

    const width = parseInt(value, 10);
    return width >= this.minOpenWidth ? width : undefined;
  }

  private render(width:number):void {
    const mainMenu = this.mainMenu;
    if (!mainMenu) return;

    mainMenu.style.width = `${width}px`;
    document.documentElement.style.setProperty('--main-menu-width', `${width}px`);
    document
      .querySelectorAll<HTMLElement>('.can-hide-navigation')
      .forEach((element) => element.classList.toggle('hidden-navigation', width === 0));

    if (width === 0) {
      document.querySelectorAll<HTMLElement>('.searchable-menu--search-input').forEach((input) => input.blur());
    }
  }

  private writeWidthCookie(width:number):void {
    this.cookieService.set(this.cookieName, String(width), {
      expires: 365,
      path: window.appBasePath || '/',
      secure: window.location.protocol === 'https:',
      sameSite: 'Lax',
    });
  }
}
