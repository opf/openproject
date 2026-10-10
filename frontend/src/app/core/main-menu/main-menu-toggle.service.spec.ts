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

import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';
import { provideHttpClient, withInterceptorsFromDi, withXhr } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { OpenProject } from 'core-app/core/setup/globals/openproject';
import { CookieService } from 'ngx-cookie-service';
import { MainMenuToggleService } from './main-menu-toggle.service';

describe('MainMenuToggleService', () => {
  const cookieName = 'op_main_menu_width';
  const widthStorageKey = 'openProject-mainMenuWidth';
  const collapsedStorageKey = 'openProject-mainMenuCollapsed';
  let originalOpenProject:OpenProject;
  let wrapper:HTMLElement;

  function cookieValue():string|undefined {
    return document.cookie
      .split('; ')
      .find((pair) => pair.startsWith(`${cookieName}=`))
      ?.split('=')[1];
  }

  function setCookie(value:string):void {
    document.cookie = `${cookieName}=${value}; path=/`;
  }

  function renderedWidth():string {
    return document.documentElement.style.getPropertyValue('--main-menu-width');
  }

  function setWindowWidth(width:number):void {
    vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(width);
  }

  function resizeWindowTo(width:number):void {
    setWindowWidth(width);
    window.dispatchEvent(new Event('resize'));
  }

  async function settle():Promise<void> {
    TestBed.tick();
    await vi.advanceTimersByTimeAsync(50);
    TestBed.tick();
  }

  async function createService():Promise<MainMenuToggleService> {
    const service = TestBed.inject(MainMenuToggleService);
    await settle();
    return service;
  }

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
    window.localStorage.clear();
    vi.useFakeTimers();
    setWindowWidth(1280);

    wrapper = document.createElement('div');
    wrapper.id = 'wrapper';
    wrapper.className = 'can-hide-navigation';
    wrapper.innerHTML = '<nav id="main-menu" class="main-menu"></nav>';
    document.body.appendChild(wrapper);

    TestBed.configureTestingModule({
      providers: [
        { provide: States, useValue: new States() },
        { provide: ConfigurationService, useValue: {} },
        provideHttpClient(withXhr(), withInterceptorsFromDi()),
        provideHttpClientTesting(),
      ],
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
    wrapper.remove();
    document.documentElement.style.removeProperty('--main-menu-width');
    document.cookie = `${cookieName}=; path=/; max-age=0`;
    window.localStorage.clear();
    window.OpenProject = originalOpenProject;
  });

  it('initialises via dependency injection', () => {
    expect(TestBed.inject(MainMenuToggleService)).toBeTruthy();
  });

  describe('on a wide window', () => {
    it('starts open at the default width', async () => {
      const service = await createService();

      expect(service.isOpen()).toBe(true);
      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('280px');
      expect(cookieValue()).toBe('280');
    });

    it('collapses on toggle and persists the collapse', async () => {
      const service = await createService();

      service.toggle();
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('0px');
      expect(cookieValue()).toBe('0');
      expect(window.localStorage.getItem(collapsedStorageKey)).toBe('true');
    });

    it('expands again at the width it had', async () => {
      const service = await createService();
      service.resizeTo(320);
      service.toggle();
      await settle();

      service.toggle();
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('320px');
      expect(cookieValue()).toBe('320');
      expect(window.localStorage.getItem(collapsedStorageKey)).toBe('false');
    });

    it('persists a resized width', async () => {
      const service = await createService();

      service.resizeTo(320);
      await settle();

      expect(renderedWidth()).toBe('320px');
      expect(cookieValue()).toBe('320');
      expect(window.localStorage.getItem(widthStorageKey)).toBe('320');
    });

    it('rounds a fractional width', async () => {
      const service = await createService();

      service.resizeTo(319.5);
      await settle();

      expect(cookieValue()).toBe('320');
    });

    it('writes the cookie once a burst of width changes settles', async () => {
      const service = await createService();
      const writeCookie = vi.spyOn(TestBed.inject(CookieService), 'set');

      service.resizeTo(310);
      TestBed.tick();
      await vi.advanceTimersByTimeAsync(30);
      service.resizeTo(320);
      TestBed.tick();
      await vi.advanceTimersByTimeAsync(30);

      expect(renderedWidth()).toBe('320px');
      expect(writeCookie).not.toHaveBeenCalled();

      await settle();

      expect(writeCookie).toHaveBeenCalledTimes(1);
      expect(cookieValue()).toBe('320');
    });

    it('collapses when resized below the minimum width and expands at the default', async () => {
      const service = await createService();
      service.resizeTo(320);

      service.resizeTo(10.6);
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('0px');
      expect(cookieValue()).toBe('0');

      service.toggle();
      await settle();

      expect(renderedWidth()).toBe('280px');
    });
  });

  describe('when the window narrows', () => {
    it('hides the menu and keeps the cookie', async () => {
      const service = await createService();
      service.resizeTo(320);
      await settle();

      resizeWindowTo(800);
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('320');
    });

    it('reopens at the remembered width when the window widens again', async () => {
      const service = await createService();
      service.resizeTo(320);
      resizeWindowTo(800);
      await settle();

      resizeWindowTo(1280);
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('320px');
      expect(cookieValue()).toBe('320');
    });

    it('stays collapsed when the user had collapsed it', async () => {
      const service = await createService();
      service.toggle();
      resizeWindowTo(800);
      await settle();

      resizeWindowTo(1280);
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
    });

    it('reopens a menu that was collapsed and then dragged open', async () => {
      const service = await createService();
      service.toggle();
      service.resizeTo(320);
      resizeWindowTo(800);
      await settle();

      resizeWindowTo(1280);
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('320px');
    });
  });

  describe('on a narrow window', () => {
    beforeEach(() => setWindowWidth(800));

    it('starts hidden without recording a collapse', async () => {
      const service = await createService();

      expect(service.isOpen()).toBe(false);
      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('280');
      expect(window.localStorage.getItem(collapsedStorageKey)).toBe('false');
    });

    it('opens on toggle', async () => {
      const service = await createService();

      service.toggle();
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
    });

    it('keeps the menu open when a resize leaves the window width unchanged', async () => {
      const service = await createService();
      service.toggle();

      resizeWindowTo(800);
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
    });

    it('hides the menu again when the window width changes', async () => {
      const service = await createService();
      service.toggle();

      resizeWindowTo(700);
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
    });

    it('hides the menu again on the next page', async () => {
      const service = await createService();
      service.toggle();
      await settle();

      service.syncWithPage();
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
    });

    it('stays collapsed on a wide window after the user closed it', async () => {
      const service = await createService();
      service.toggle();
      service.toggle();
      await settle();

      resizeWindowTo(1280);
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('0');
    });
  });

  describe('restoring the preference', () => {
    it('prefers the stored width and collapse', async () => {
      window.localStorage.setItem(widthStorageKey, '400');
      window.localStorage.setItem(collapsedStorageKey, 'true');
      setCookie('320');

      const service = await createService();

      expect(wrapper).toHaveClass('hidden-navigation');

      service.toggle();
      await settle();

      expect(renderedWidth()).toBe('400px');
    });

    it('falls back to the width in the cookie', async () => {
      setCookie('320');

      await createService();

      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('320px');
      expect(cookieValue()).toBe('320');
    });

    it('falls back to the collapse in the cookie', async () => {
      setCookie('0');

      await createService();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('0');
    });

    it.each(['0', 'wide'])('ignores a stored width of "%s"', async (stored) => {
      window.localStorage.setItem(widthStorageKey, stored);
      window.localStorage.setItem(collapsedStorageKey, 'true');

      const service = await createService();

      expect(wrapper).toHaveClass('hidden-navigation');

      service.toggle();
      await settle();

      expect(wrapper).not.toHaveClass('hidden-navigation');
      expect(renderedWidth()).toBe('280px');
    });

    it('keeps a toggle that the next page follows straight away', async () => {
      const service = await createService();

      service.toggle();
      service.syncWithPage();
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('0');
    });

    it('keeps a resize that the next page follows straight away', async () => {
      const service = await createService();

      service.resizeTo(320);
      service.syncWithPage();
      await settle();

      expect(renderedWidth()).toBe('320px');
      expect(cookieValue()).toBe('320');
    });

    it('keeps a toggle without localStorage while the cookie write is pending', async () => {
      vi.spyOn(window.OpenProject, 'guardedLocalStorage').mockReturnValue(undefined);
      const service = await createService();

      service.toggle();
      service.syncWithPage();
      await settle();

      expect(wrapper).toHaveClass('hidden-navigation');
      expect(cookieValue()).toBe('0');
    });

    it('picks up a preference stored by another tab', async () => {
      const service = await createService();
      window.localStorage.setItem(widthStorageKey, '400');

      service.syncWithPage();
      await settle();

      expect(renderedWidth()).toBe('400px');
    });

    it('rerenders a replaced page from the current state', async () => {
      const service = await createService();
      service.toggle();
      await settle();
      wrapper.classList.remove('hidden-navigation');

      service.syncWithPage();

      expect(wrapper).toHaveClass('hidden-navigation');
    });
  });

  describe('on a page without a main menu', () => {
    beforeEach(() => wrapper.querySelector('#main-menu')!.remove());

    it('persists nothing', async () => {
      const service = await createService();

      service.toggle();
      await settle();

      expect(cookieValue()).toBeUndefined();
      expect(window.localStorage.getItem(widthStorageKey)).toBeNull();
      expect(window.localStorage.getItem(collapsedStorageKey)).toBeNull();
    });
  });
});
