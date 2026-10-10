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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { BehaviorSubject } from 'rxjs';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { AppBadgeService } from 'core-app/features/in-app-notifications/bell/app-badge.service';

describe('AppBadgeService', () => {
  let unread$:BehaviorSubject<number>;
  let setAppBadge:ReturnType<typeof vi.fn>;
  let clearAppBadge:ReturnType<typeof vi.fn>;
  let meta:HTMLMetaElement;

  const setup = ({
    flags = ['progressiveWebApp'],
    loggedIn = true,
    badgeApi = true,
    standalone = false,
  }:{ flags?:string[], loggedIn?:boolean, badgeApi?:boolean, standalone?:boolean } = {}) => {
    meta.dataset.loggedIn = String(loggedIn);
    vi.stubGlobal('navigator', badgeApi ? { setAppBadge, clearAppBadge } : {});
    vi.stubGlobal('matchMedia', (query:string) => ({ matches: standalone && query === '(display-mode: standalone)' }));

    TestBed.configureTestingModule({
      providers: [
        { provide: IanBellService, useValue: { unread$ } },
        { provide: ConfigurationService, useValue: { activeFeatureFlags: flags } },
      ],
    });

    return TestBed.inject(AppBadgeService);
  };

  beforeEach(() => {
    unread$ = new BehaviorSubject<number>(0);
    setAppBadge = vi.fn().mockResolvedValue(undefined);
    clearAppBadge = vi.fn().mockResolvedValue(undefined);
    meta = document.createElement('meta');
    meta.name = 'current_user';
    document.head.appendChild(meta);
  });

  afterEach(() => {
    meta.remove();
    vi.unstubAllGlobals();
  });

  describe('when running as an installed app', () => {
    it('mirrors the unread count on the badge', () => {
      setup().initialize();

      unread$.next(7);
      expect(setAppBadge).toHaveBeenLastCalledWith(7);
    });

    it('caps large counts at 99', () => {
      setup().initialize();

      unread$.next(1500);
      expect(setAppBadge).toHaveBeenLastCalledWith(99);
    });

    it('clears the badge at zero unread', () => {
      unread$.next(3);
      setup().initialize();

      unread$.next(0);
      expect(clearAppBadge).toHaveBeenCalledTimes(1);
    });

    it('leaves the badge unchanged when the count could not be fetched', () => {
      setup().initialize();

      unread$.next(4);
      setAppBadge.mockClear();
      clearAppBadge.mockClear();
      unread$.next(-1);

      expect(setAppBadge).not.toHaveBeenCalled();
      expect(clearAppBadge).not.toHaveBeenCalled();
    });

    it('ignores repeated identical counts', () => {
      setup().initialize();

      unread$.next(4);
      unread$.next(4);
      expect(setAppBadge).toHaveBeenCalledTimes(1);
    });

    it('does not surface a rejected badge call', async () => {
      setAppBadge.mockRejectedValue(new DOMException('not installed', 'NotAllowedError'));
      setup().initialize();

      unread$.next(2);
      await new Promise((resolve) => { setTimeout(resolve, 0); });

      expect(setAppBadge).toHaveBeenCalledWith(2);
    });

    it('does not surface a synchronously throwing badge call', () => {
      setAppBadge.mockImplementation(() => { throw new TypeError('unsupported'); });
      setup().initialize();

      expect(() => unread$.next(2)).not.toThrow();
    });
  });

  it('clears the badge and stops when signed out', () => {
    setup({ loggedIn: false }).initialize();

    expect(clearAppBadge).toHaveBeenCalledTimes(1);

    unread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
  });

  it('does nothing when the feature flag is off', () => {
    setup({ flags: [], loggedIn: false }).initialize();

    unread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
    expect(clearAppBadge).not.toHaveBeenCalled();
  });

  it('does nothing when the Badging API is missing', () => {
    expect(() => setup({ badgeApi: false }).initialize()).not.toThrow();

    unread$.next(5);
    expect(setAppBadge).not.toHaveBeenCalled();
  });

  describe('backgroundPollingFactor', () => {
    it('polls a hidden installed app more often than a hidden browser tab', () => {
      expect(setup({ standalone: true }).backgroundPollingFactor).toBe(3);
    });

    it('keeps the slow cadence for a hidden browser tab', () => {
      expect(setup({ standalone: false }).backgroundPollingFactor).toBe(10);
    });

    it('keeps the slow cadence when the feature flag is off', () => {
      expect(setup({ standalone: true, flags: [] }).backgroundPollingFactor).toBe(10);
    });
  });
});
