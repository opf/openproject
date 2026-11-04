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

/*
 * Service worker of the progressive web app.
 *
 *   - Offline fallback: navigations that cannot reach the server get a precached offline page.
 *   - Push wake-ups: a push carries no content, so the worker fetches the unread summary and
 *     renders one notification per work package.
 *   - Notification clicks open or focus a window on the target page.
 *   - Signing out clears every notification, the remembered state and the app badge.
 *
 *   OpenProject --push--> push service --wake-up--> worker --GET push summary--> OpenProject
 *   worker --show / close--> notifications, app badge
 *   logout navigation --> worker --clears--> notifications, remembered state, app badge
 */
import { Config } from './config';
import { NotificationClick } from './notification-click';
import { OfflinePage } from './offline-page';
import { PushHandler } from './push-handler';
import { sw } from './sw-global';

/*****************************************************************************************
 * BROWSER EVENTS
 *
 * The browser calls the worker only through these listeners: install, activate, fetch,
 * push and notificationclick. Each one delegates to the classes above.
 *****************************************************************************************/
const pushHandler = new PushHandler();

sw.addEventListener('install', (event) => {
  event.waitUntil(
    OfflinePage.precache()
      .catch((error:unknown) => {
        console.warn('Offline page could not be precached', error);
        throw error;
      })
      .then(() => sw.skipWaiting()),
  );
});

sw.addEventListener('activate', (event) => {
  event.waitUntil(
    OfflinePage.deleteStaleCaches()
      .then(() => sw.registration.navigationPreload?.enable())
      .then(() => sw.clients.claim()),
  );
});

// Sign-out is detected on navigation because the worker is the only place that sees every logout, including SSO redirects.
sw.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.mode === 'navigate' && request.method === 'GET' && pushHandler.isSignOut(request)) {
    event.waitUntil(pushHandler.signOut());
  }
  OfflinePage.respondTo(event);
});

sw.addEventListener('push', (event) => pushHandler.onPush(event));

sw.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const requestedUrl = (event.notification.data as { url?:string }|null)?.url;
  event.waitUntil(NotificationClick.open(requestedUrl?.length ? requestedUrl : Config.urls.home));
});
