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

import { withOcticon, wpMenuOcticon } from './wp-menu-octicons';

describe('wpMenuOcticon', () => {
  it('maps the copy work package ID icon to the hash Octicon', () => {
    expect(wpMenuOcticon('icon-code-tag')).toBe('hash');
  });

  it('maps the delete icon to the trash Octicon', () => {
    expect(wpMenuOcticon('icon-delete')).toBe('trash');
  });

  it('maps the timer and configure icons', () => {
    expect(wpMenuOcticon('icon-time-tracking-start')).toBe('play');
    expect(wpMenuOcticon('icon-time-tracking-stop')).toBe('stop');
    expect(wpMenuOcticon('icon-settings3')).toBe('gear');
  });

  it('returns undefined for an unmapped icon or none', () => {
    expect(wpMenuOcticon('icon-unknown-plugin')).toBeUndefined();
    expect(wpMenuOcticon(undefined)).toBeUndefined();
  });

  it('does not resolve inherited object properties', () => {
    expect(wpMenuOcticon('toString')).toBeUndefined();
  });
});

describe('withOcticon', () => {
  it('replaces the icon class by the Octicon', () => {
    const item = withOcticon({ linkText: 'Delete', icon: 'icon-delete' });

    expect(item.octicon).toBe('trash');
    expect(item).not.toHaveProperty('icon');
  });

  it('leaves an item with an unmapped icon without any icon', () => {
    const item = withOcticon({ linkText: 'X', icon: 'icon-unknown-plugin' });

    expect(item).not.toHaveProperty('icon');
    expect(item).not.toHaveProperty('octicon');
  });

  it('keeps an Octicon the item already has', () => {
    expect(withOcticon({ linkText: 'Up', octicon: 'chevron-up' }).octicon).toBe('chevron-up');
  });
});
