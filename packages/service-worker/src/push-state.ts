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
import type { PushStateMap } from './notification-rules';

export class PushState {
  static get shownUrl():string {
    return `${Config.urls.push}?shown`;
  }

  static async read():Promise<PushStateMap> {
    const cache = await caches.open(Config.cache.state);
    const stored = await cache.match(PushState.shownUrl);
    return stored ? (stored.json() as Promise<PushStateMap>) : {};
  }

  static async write(state:PushStateMap):Promise<void> {
    const cache = await caches.open(Config.cache.state);
    await cache.put(PushState.shownUrl, new Response(JSON.stringify(state), { headers: { 'Content-Type': 'application/json' } }));
  }

  static clear():Promise<void> {
    return PushState.write({});
  }
}
