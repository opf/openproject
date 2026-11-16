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

import type { Notifications as NotificationsType } from './notifications';

describe('Notifications.display', () => {
  let Notifications:typeof NotificationsType;
  const tag = 'openproject-2-wp-1';

  const showNotification = vi.fn();
  const getNotifications = vi.fn();
  const open = (notificationTag:string) => ({ tag: notificationTag, close: vi.fn() });

  beforeAll(async () => {
    vi.stubGlobal('OP_SW', {
      urls: { home: '/', push: '/api/v3/notifications/summary', signOut: '/logout' },
      push: { fallbackTitle: 'OpenProject', allReadTitle: 'All read', icon: '/icon.png' },
    });
    ({ Notifications } = await import('./notifications'));
  });

  beforeEach(() => {
    showNotification.mockReset().mockResolvedValue(undefined);
    getNotifications.mockReset().mockResolvedValue([]);
    vi.stubGlobal('registration', { showNotification, getNotifications });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  describe('in a browser without renotify support (Notification undefined, as in a Safari worker)', () => {
    beforeEach(() => {
      vi.stubGlobal('Notification', undefined);
    });

    it('closes the open notification with the same tag before showing the new one', async () => {
      const stale = open(tag);
      getNotifications.mockResolvedValue([stale]);

      await Notifications.display('Title', { tag });

      expect(stale.close).toHaveBeenCalledOnce();
      expect(stale.close.mock.invocationCallOrder[0]).toBeLessThan(showNotification.mock.invocationCallOrder[0]);
    });

    it('leaves a notification with another tag open', async () => {
      const stale = open(tag);
      const unrelated = open('openproject-2-wp-9');
      getNotifications.mockResolvedValue([stale, unrelated]);

      await Notifications.display('Title', { tag });

      expect(stale.close).toHaveBeenCalledOnce();
      expect(unrelated.close).not.toHaveBeenCalled();
    });

    it('shows the notification when looking up the open notifications fails', async () => {
      getNotifications.mockImplementation(() => { throw new Error('lookup failed'); });

      await Notifications.display('Title', { tag });

      expect(showNotification).toHaveBeenCalledWith('Title', expect.objectContaining({ tag }));
    });
  });

  describe('in a browser with renotify support', () => {
    beforeEach(() => {
      vi.stubGlobal('Notification', { prototype: { renotify: false } });
    });

    it('leaves the replacement to the browser', async () => {
      const stale = open(tag);
      getNotifications.mockResolvedValue([stale]);

      await Notifications.display('Title', { tag });

      expect(getNotifications).not.toHaveBeenCalled();
      expect(stale.close).not.toHaveBeenCalled();
      expect(showNotification).toHaveBeenCalledWith('Title', expect.objectContaining({ tag }));
    });
  });
});
