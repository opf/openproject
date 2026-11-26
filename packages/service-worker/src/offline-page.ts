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

export class OfflinePage {
  static async precache():Promise<void> {
    const response = await fetch(new Request(Config.urls.offline, { credentials: 'omit', cache: 'reload' }));
    if (!response.ok || response.redirected) throw new Error('Offline page unavailable');

    const cache = await caches.open(Config.cache.name);
    await cache.put(Config.urls.offline, response);
  }

  static async deleteStaleCaches():Promise<void> {
    for (const name of await caches.keys()) {
      if (name.startsWith(Config.cache.prefix) && name !== Config.cache.name && name !== Config.cache.state) await caches.delete(name);
    }
  }

  static respondTo(event:FetchEvent):Promise<Response>|undefined {
    const { request } = event;
    if (request.mode !== 'navigate' || request.destination !== 'document' || request.method !== 'GET') return undefined;

    const response = OfflinePage.load(event);
    event.respondWith(response);
    return response;
  }

  static async load(event:FetchEvent):Promise<Response> {
    let preloaded:Response|undefined;
    try {
      preloaded = await (event.preloadResponse as Promise<Response|undefined>);
    } catch {
      preloaded = undefined;
    }

    try {
      return preloaded ?? (await fetch(event.request));
    } catch {
      const cache = await caches.open(Config.cache.name);
      return (await cache.match(Config.urls.offline)) ?? Response.error();
    }
  }
}
