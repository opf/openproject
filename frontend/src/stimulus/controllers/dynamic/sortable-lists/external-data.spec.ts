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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { webLinkHref } from './external-data';

describe('webLinkHref', () => {
  const webUrls = [
    'http://example.org/a',
    'https://example.org/a',
    'HTTPS://example.org/WP/123',
    'hTtP://example.org/a',
  ];
  const unsupportedUrls = [
    '',
    '/work_packages/1',
    '//example.org',
    'javascript:alert(1)',
    'data:text/html,hello',
    'mailto:a@example.org',
  ];

  it.each(webUrls)('preserves HTTP(S) URL %s', (url) => {
    expect(webLinkHref(url)).toBe(url);
  });

  it.each(unsupportedUrls)('rejects unsupported prefix %s', (url) => {
    expect(webLinkHref(url)).toBeNull();
  });
});
