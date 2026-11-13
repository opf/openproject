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

import type { NotificationClick as NotificationClickType } from './notification-click';

describe('NotificationClick.sameOriginUrl', () => {
  let NotificationClick:typeof NotificationClickType;

  beforeAll(async () => {
    vi.stubGlobal('OP_SW', { urls: { home: '/' } });
    ({ NotificationClick } = await import('./notification-click'));
  });

  it.each([
    ['a relative path', '/work_packages/7', 'https://openproject.test/work_packages/7'],
    ['a foreign origin', 'https://evil.example/phish', 'https://openproject.test/'],
    ['a protocol-relative URL', '//evil.example/phish', 'https://openproject.test/'],
    ['a javascript: URL', 'javascript:alert(1)', 'https://openproject.test/'],
  ])('resolves %s to a same-origin page', (_case, url, expected) => {
    expect(NotificationClick.sameOriginUrl(url)).toBe(expected);
  });
});

describe('NotificationClick.open', () => {
  let NotificationClick:typeof NotificationClickType;

  beforeAll(async () => {
    vi.stubGlobal('OP_SW', { urls: { home: '/' } });
    ({ NotificationClick } = await import('./notification-click'));
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('opens a new window when no controlled window is in scope', async () => {
    const matchAll = vi.fn().mockResolvedValue([]);
    const openWindow = vi.fn().mockResolvedValue(null);
    vi.stubGlobal('clients', { matchAll, openWindow });
    vi.stubGlobal('registration', { scope: 'https://openproject.test/' });

    await NotificationClick.open('/work_packages/7');

    expect(openWindow).toHaveBeenCalledWith('https://openproject.test/work_packages/7');
    expect(matchAll).toHaveBeenCalledTimes(1);
    expect(matchAll).not.toHaveBeenCalledWith(expect.objectContaining({ includeUncontrolled: true }));
  });
});
