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
import { BrowserNotificationSyncService } from 'core-app/features/in-app-notifications/bell/browser-notification-sync.service';

describe('BrowserNotificationSyncService', () => {
  let loadedUnread$:Subject<number>;
  let getNotifications:ReturnType<typeof vi.fn>;
  let getRegistration:ReturnType<typeof vi.fn>;
  let postMessage:ReturnType<typeof vi.fn>;
  let meta:HTMLMetaElement;

  const notification = (tag:string) => ({ tag, close: vi.fn() });

  const setup = ({ permission = 'granted', loggedIn = 'true', flags = ['progressiveWebApp'] }:{ permission?:string; loggedIn?:string; flags?:string[] } = {}) => {
    meta.dataset.loggedIn = loggedIn;
    vi.stubGlobal('Notification', { permission });
    Object.defineProperty(navigator, 'serviceWorker', {
      configurable: true,
      value: { getRegistration, ready: Promise.resolve({ active: { postMessage } }) },
    });

    TestBed.configureTestingModule({
      providers: [
        { provide: IanBellService, useValue: { loadedUnread$ } },
        { provide: ConfigurationService, useValue: { activeFeatureFlags: flags } },
      ],
    });

    return TestBed.inject(BrowserNotificationSyncService);
  };

  const flush = () => new Promise((resolve) => { setTimeout(resolve); });

  beforeEach(() => {
    loadedUnread$ = new Subject<number>();
    getNotifications = vi.fn();
    getRegistration = vi.fn().mockResolvedValue({ getNotifications });
    postMessage = vi.fn();
    meta = document.createElement('meta');
    meta.name = 'current_user';
    meta.dataset.id = '7';
    document.head.appendChild(meta);
  });

  afterEach(() => {
    meta.remove();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
  });

  it('tells the worker which user is signed in', async () => {
    setup().initialize();
    await flush();

    expect(postMessage).toHaveBeenCalledWith({ type: 'account', userId: '7' });
  });

  it('asks the worker to reconcile whenever the unread count changes', async () => {
    setup().initialize();

    loadedUnread$.next(3);
    loadedUnread$.next(2);
    await flush();

    expect(postMessage.mock.calls.filter(([message]) => message.type === 'reconcile')).toHaveLength(2);
  });

  it('ignores the placeholder count before the first load', async () => {
    setup().initialize();

    loadedUnread$.next(-1);
    await flush();

    expect(postMessage).not.toHaveBeenCalledWith({ type: 'reconcile' });
  });

  it('closes every notification and stays quiet when signed out', async () => {
    const open = [notification('openproject-1-wp-1'), notification('openproject-more'), notification('other-app')];
    getNotifications.mockResolvedValue(open);
    setup({ loggedIn: 'false' }).initialize();

    loadedUnread$.next(3);
    await flush();

    expect(open[0].close).toHaveBeenCalled();
    expect(open[1].close).toHaveBeenCalled();
    expect(open[2].close).not.toHaveBeenCalled();
    expect(postMessage).not.toHaveBeenCalled();
  });

  it('stays inert without notification permission', async () => {
    setup({ permission: 'default' }).initialize();

    loadedUnread$.next(3);
    await flush();

    expect(postMessage).not.toHaveBeenCalled();
    expect(getRegistration).not.toHaveBeenCalled();
  });

  it('stays inert when the feature flag is off', async () => {
    setup({ flags: [] }).initialize();

    loadedUnread$.next(3);
    await flush();

    expect(postMessage).not.toHaveBeenCalled();
  });

  it('stays inert without service worker support', async () => {
    const service = setup();
    delete (navigator as { serviceWorker?:unknown }).serviceWorker;
    service.initialize();

    loadedUnread$.next(3);
    await flush();

    expect(postMessage).not.toHaveBeenCalled();
  });
});
