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
import { MainMenuToggleService } from './main-menu-toggle.service';

describe('MainMenuToggleService', () => {
  const cookieName = 'op_main_menu_width';
  let originalOpenProject:OpenProject;
  let wrapper:HTMLElement;

  function cookieValue():string|undefined {
    return document.cookie
      .split('; ')
      .find((pair) => pair.startsWith(`${cookieName}=`))
      ?.split('=')[1];
  }

  beforeEach(() => {
    originalOpenProject = window.OpenProject;
    window.OpenProject = new OpenProject();
    window.localStorage.clear();
    vi.useFakeTimers();
    vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(1280);

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
    document.cookie = `${cookieName}=; path=/; max-age=0`;
    window.localStorage.clear();
    window.OpenProject = originalOpenProject;
  });

  function resizeWindowTo(width:number):void {
    vi.spyOn(window, 'innerWidth', 'get').mockReturnValue(width);
    window.dispatchEvent(new Event('resize'));
  }

  async function flushCookieWrite():Promise<void> {
    TestBed.tick();
    await vi.advanceTimersByTimeAsync(50);
    TestBed.tick();
  }

  it('initialises via dependency injection', () => {
    expect(TestBed.inject(MainMenuToggleService)).toBeTruthy();
  });

  it('mirrors a collapsed menu into the cookie', async () => {
    const service = TestBed.inject(MainMenuToggleService);

    service.closeMenu();
    await flushCookieWrite();

    expect(cookieValue()).toBe('0');
    expect(wrapper).toHaveClass('hidden-navigation');
  });

  it('mirrors the open width into the cookie', async () => {
    const service = TestBed.inject(MainMenuToggleService);

    service.setWidth(320);
    await flushCookieWrite();

    expect(cookieValue()).toBe('320');
    expect(wrapper).not.toHaveClass('hidden-navigation');
  });

  it('writes the cookie once a burst of width changes settles', async () => {
    const service = TestBed.inject(MainMenuToggleService);
    service.setWidth(300);
    await flushCookieWrite();

    service.saveWidth(310);
    service.saveWidth(320);

    expect(cookieValue()).toBe('300');

    await flushCookieWrite();

    expect(cookieValue()).toBe('320');
  });

  it('rounds a fractional width before mirroring it', async () => {
    const service = TestBed.inject(MainMenuToggleService);

    service.setWidth(319.5);
    await flushCookieWrite();

    expect(cookieValue()).toBe('320');
  });

  it('keeps the cookie when a narrow window hides the menu', async () => {
    const service = TestBed.inject(MainMenuToggleService);
    service.setWidth(320);

    resizeWindowTo(800);
    await flushCookieWrite();

    expect(wrapper).toHaveClass('hidden-navigation');
    expect(cookieValue()).toBe('320');
  });

  it('mirrors the reopened width when the window widens again', async () => {
    const service = TestBed.inject(MainMenuToggleService);
    service.setWidth(320);
    resizeWindowTo(800);

    resizeWindowTo(1280);
    await flushCookieWrite();

    expect(wrapper).not.toHaveClass('hidden-navigation');
    expect(cookieValue()).toBe('280');
  });
});
