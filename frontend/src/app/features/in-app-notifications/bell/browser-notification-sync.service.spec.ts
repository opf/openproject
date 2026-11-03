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
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { BrowserNotificationSyncService } from 'core-app/features/in-app-notifications/bell/browser-notification-sync.service';

describe('BrowserNotificationSyncService', () => {
  let loadedUnread$:Subject<number>;
  let getNotifications:ReturnType<typeof vi.fn>;
  let getRegistration:ReturnType<typeof vi.fn>;
  let fetchMock:ReturnType<typeof vi.fn>;
  let meta:HTMLMetaElement;

  const notification = (tag:string) => ({ tag, close: vi.fn() });

  const setup = ({ permission = 'granted' }:{ permission?:string } = {}) => {
    meta.dataset.loggedIn = 'true';
    vi.stubGlobal('Notification', { permission });
    vi.stubGlobal('fetch', fetchMock);
    Object.defineProperty(navigator, 'serviceWorker', { configurable: true, value: { getRegistration } });

    TestBed.configureTestingModule({
      providers: [
        { provide: IanBellService, useValue: { loadedUnread$ } },
        { provide: ConfigurationService, useValue: { activeFeatureFlags: ['progressiveWebApp'] } },
        { provide: PathHelperService, useValue: { appBasePath: '' } },
      ],
    });

    return TestBed.inject(BrowserNotificationSyncService);
  };

  const flush = () => new Promise((resolve) => { setTimeout(resolve); });

  beforeEach(() => {
    loadedUnread$ = new Subject<number>();
    getNotifications = vi.fn();
    getRegistration = vi.fn().mockResolvedValue({ getNotifications });
    fetchMock = vi.fn();
    meta = document.createElement('meta');
    meta.name = 'current_user';
    document.head.appendChild(meta);
  });

  afterEach(() => {
    meta.remove();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
  });

  it('closes notifications for work packages that are no longer unread', async () => {
    const [wp1, wp2, more] = [notification('openproject-wp-1'), notification('openproject-wp-2'), notification('openproject-more')];
    getNotifications.mockResolvedValue([wp1, wp2, more]);
    fetchMock.mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ count: 1, groups: [{ tag: 'openproject-wp-1' }], more: null }),
    });
    setup().initialize();

    loadedUnread$.next(1);
    await flush();

    expect(wp1.close).not.toHaveBeenCalled();
    expect(wp2.close).toHaveBeenCalled();
    expect(more.close).toHaveBeenCalled();
  });

  it('closes every notification without fetching when nothing is unread', async () => {
    const open = [notification('openproject-wp-1'), notification('openproject-unread')];
    getNotifications.mockResolvedValue(open);
    setup().initialize();

    loadedUnread$.next(0);
    await flush();

    open.forEach((item) => expect(item.close).toHaveBeenCalled());
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('does nothing when no OpenProject notification is open', async () => {
    getNotifications.mockResolvedValue([notification('other-app')]);
    setup().initialize();

    loadedUnread$.next(3);
    await flush();

    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('stays inert without notification permission', async () => {
    setup({ permission: 'default' }).initialize();

    loadedUnread$.next(3);
    await flush();

    expect(loadedUnread$.observed).toBe(false);
    expect(getRegistration).not.toHaveBeenCalled();
  });
});
