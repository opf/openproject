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
import { Subject } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { AppBadgeService } from 'core-app/features/in-app-notifications/bell/app-badge.service';

describe('AppBadgeService', () => {
  let loadedUnread$:Subject<number>;
  let setAppBadge:ReturnType<typeof vi.fn>;
  let clearAppBadge:ReturnType<typeof vi.fn>;
  let meta:HTMLMetaElement;

  const setup = ({
    flags = ['progressiveWebApp'],
    loggedIn = true,
    badgeApi = true,
    installed = true,
    displayMode = 'standalone',
  }:{ flags?:string[], loggedIn?:boolean, badgeApi?:boolean, installed?:boolean, displayMode?:string } = {}) => {
    meta.dataset.loggedIn = String(loggedIn);
    if (badgeApi) {
      Object.defineProperty(navigator, 'setAppBadge', { configurable: true, value: setAppBadge });
      Object.defineProperty(navigator, 'clearAppBadge', { configurable: true, value: clearAppBadge });
    } else {
      Object.defineProperty(navigator, 'setAppBadge', { configurable: true, value: undefined });
      Object.defineProperty(navigator, 'clearAppBadge', { configurable: true, value: undefined });
    }
    vi.stubGlobal('matchMedia', (query:string) => ({ matches: installed && query === `(display-mode: ${displayMode})` }));

    TestBed.configureTestingModule({
      providers: [
        { provide: IanBellService, useValue: { loadedUnread$ } },
        { provide: ConfigurationService, useValue: { activeFeatureFlags: flags } },
      ],
    });

    return TestBed.inject(AppBadgeService);
  };

  beforeEach(() => {
    loadedUnread$ = new Subject<number>();
    setAppBadge = vi.fn().mockResolvedValue(undefined);
    clearAppBadge = vi.fn().mockResolvedValue(undefined);
    meta = document.createElement('meta');
    meta.name = 'current_user';
    document.head.appendChild(meta);
  });

  afterEach(() => {
    meta.remove();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    delete (navigator as { setAppBadge?:unknown }).setAppBadge;
    delete (navigator as { clearAppBadge?:unknown }).clearAppBadge;
  });

  describe('when running as an installed app', () => {
    it('mirrors the unread count on the badge', () => {
      setup().initialize();

      loadedUnread$.next(7);
      expect(setAppBadge).toHaveBeenLastCalledWith(7);
    });

    it('mirrors the unread count in a window-controls-overlay window', () => {
      setup({ displayMode: 'window-controls-overlay' }).initialize();

      loadedUnread$.next(7);
      expect(setAppBadge).toHaveBeenLastCalledWith(7);
    });

    it('passes the real count to the badge', () => {
      setup().initialize();

      loadedUnread$.next(1500);
      expect(setAppBadge).toHaveBeenLastCalledWith(1500);
    });

    it('does not clear the badge before the first count is loaded', () => {
      setup().initialize();
      expect(clearAppBadge).not.toHaveBeenCalled();

      loadedUnread$.next(0);
      expect(clearAppBadge).toHaveBeenCalledTimes(1);
    });

    it('clears the badge at zero unread', () => {
      setup().initialize();

      loadedUnread$.next(3);
      loadedUnread$.next(0);
      expect(clearAppBadge).toHaveBeenCalledTimes(1);
    });

    it('leaves the badge unchanged when the count could not be fetched', () => {
      setup().initialize();

      loadedUnread$.next(4);
      setAppBadge.mockClear();
      clearAppBadge.mockClear();
      loadedUnread$.next(-1);

      expect(setAppBadge).not.toHaveBeenCalled();
      expect(clearAppBadge).not.toHaveBeenCalled();
    });

    it('does not surface a rejected badge call', async () => {
      setAppBadge.mockRejectedValue(new DOMException('not installed', 'NotAllowedError'));
      setup().initialize();

      loadedUnread$.next(2);
      await Promise.resolve();

      expect(setAppBadge).toHaveBeenCalledWith(2);
    });
  });

  it('does nothing in a plain browser tab', () => {
    setup({ installed: false }).initialize();

    loadedUnread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
    expect(clearAppBadge).not.toHaveBeenCalled();
  });

  it('does nothing in a browser tab that is in fullscreen display mode', () => {
    setup({ displayMode: 'fullscreen' }).initialize();

    loadedUnread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
    expect(clearAppBadge).not.toHaveBeenCalled();
  });

  it('clears the badge and stops when signed out', () => {
    setup({ loggedIn: false }).initialize();

    expect(clearAppBadge).toHaveBeenCalledTimes(1);

    loadedUnread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
  });

  it('clears a stale badge when the feature flag is off in an installed app', () => {
    setup({ flags: [], loggedIn: true, installed: true }).initialize();

    loadedUnread$.next(5);
    expect(clearAppBadge).toHaveBeenCalledTimes(1);
    expect(setAppBadge).not.toHaveBeenCalled();
  });

  it('does nothing when the feature flag is off in a plain tab', () => {
    setup({ flags: [], installed: false }).initialize();

    loadedUnread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
    expect(clearAppBadge).not.toHaveBeenCalled();
  });

  it('does nothing when the Badging API is missing', () => {
    expect(() => setup({ badgeApi: false }).initialize()).not.toThrow();

    expect(loadedUnread$.observed).toBe(false);
    expect(() => loadedUnread$.next(5)).not.toThrow();
    expect(setAppBadge).not.toHaveBeenCalled();
    expect(clearAppBadge).not.toHaveBeenCalled();
  });

  describe('hiddenPollingFactor', () => {
    it('polls a hidden installed app more often than a hidden browser tab', () => {
      expect(setup({ installed: true }).hiddenPollingFactor).toBe(3);
    });

    it('keeps the slow cadence for a hidden browser tab', () => {
      expect(setup({ installed: false }).hiddenPollingFactor).toBe(10);
    });

    it('keeps the slow cadence when the feature flag is off', () => {
      expect(setup({ installed: true, flags: [] }).hiddenPollingFactor).toBe(10);
    });
  });
});
