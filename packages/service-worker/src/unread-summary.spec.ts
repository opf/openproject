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

import type { UnreadSummary as UnreadSummaryType } from './unread-summary';

describe('UnreadSummary.fetch', () => {
  let UnreadSummary:typeof UnreadSummaryType;

  beforeAll(async () => {
    vi.stubGlobal('OP_SW', { urls: { push: '/api/v3/notifications/summary' } });
    ({ UnreadSummary } = await import('./unread-summary'));
  });

  afterEach(() => vi.restoreAllMocks());

  const respondWith = (response:Response) => vi.spyOn(globalThis, 'fetch').mockResolvedValue(response);
  const json = (body:unknown, status = 200) => respondWith(new Response(JSON.stringify(body), { status }));

  it('reports a signed-out session for 401', async () => {
    respondWith(new Response(null, { status: 401 }));

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'signedOut' });
  });

  it.each([404, 503])('reports unavailable for a %i response', async (status) => {
    respondWith(new Response(null, { status }));

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'unavailable' });
  });

  it('reports empty for a zero count', async () => {
    json({ count: 0, groups: [] });

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'empty' });
  });

  it('returns the groups for unread notifications', async () => {
    const groups = [{ tag: 'openproject-1-wp-1', title: 'A', url: '/work_packages/1', revision: 'rev:1' }];
    json({ count: 2, groups });

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'unread', count: 2, groups, more: undefined });
  });

  it('reports unavailable for a body that is not JSON', async () => {
    respondWith(new Response('<html>', { status: 200 }));

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'unavailable' });
  });

  it('reports unavailable when the request fails or times out', async () => {
    vi.spyOn(globalThis, 'fetch').mockRejectedValue(new DOMException('timeout', 'TimeoutError'));

    expect(await UnreadSummary.fetch()).toEqual({ outcome: 'unavailable' });
  });
});
