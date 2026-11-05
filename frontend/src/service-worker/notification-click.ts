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

import { Config } from './config';
import { sw } from './sw-global';

/** Focuses an existing controlled window of the app and opens a clicked notification's page there, or in a new one. */
export class NotificationClick {
  static sameOriginUrl(url:string):string {
    const resolved = new URL(url, sw.location.href);
    return resolved.origin === sw.location.origin ? resolved.href : new URL(Config.urls.home, sw.location.href).href;
  }

  static async windowsInScope():Promise<WindowClient[]> {
    const windows = await sw.clients.matchAll({ type: 'window' });
    return windows.filter((candidate) => candidate.url.startsWith(sw.registration.scope));
  }

  static async open(requestedUrl:string):Promise<WindowClient|null|undefined> {
    const url = NotificationClick.sameOriginUrl(requestedUrl);
    const clients = await NotificationClick.windowsInScope();

    const client =
      clients.find((candidate) => candidate.visibilityState === 'visible' || candidate.focused) ?? clients[0];
    if (!client) return sw.clients.openWindow(url);

    try {
      await client.focus();
      await client.navigate(url);
    } catch {
      return sw.clients.openWindow(url);
    }
    return undefined;
  }
}
