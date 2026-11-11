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
import { FETCH_TIMEOUT_MS } from './constants';
import type { SummaryGroup, SummaryMore } from './notification-rules';

export type UnreadOutcome =
  | { outcome:'signedOut'|'unavailable'|'empty' }
  | { outcome:'unread'; count:number; groups:SummaryGroup[]; more?:SummaryMore };

interface SummaryResponse {
  count:number;
  groups:SummaryGroup[];
  more?:SummaryMore;
}

/** Fetches the unread summary with the user's session and reduces the response to one outcome. */
export class UnreadSummary {
  static async fetch():Promise<UnreadOutcome> {
    try {
      const response = await fetch(Config.urls.push, {
        credentials: 'include',
        cache: 'no-store',
        headers: { Accept: 'application/json' },
        signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
      });
      if (response.status === 401 || response.status === 403) return { outcome: 'signedOut' };
      if (!response.ok) return { outcome: 'unavailable' };

      const data = await response.json() as SummaryResponse|null;
      if (!data) return { outcome: 'unavailable' };
      if (data.count === 0) return { outcome: 'empty' };
      return { outcome: 'unread', count: data.count, groups: data.groups, more: data.more };
    } catch {
      return { outcome: 'unavailable' };
    }
  }
}
