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

import { ChangeItem } from 'core-app/shared/components/fields/changeset/changeset';
import { listNeedsReload } from './board-list.component';

describe('listNeedsReload', () => {
  const newStatus = '/api/v3/statuses/1';
  const inProgress = '/api/v3/statuses/7';
  const toInProgress:ChangeItem = { from: { href: newStatus }, to: { href: inProgress } };
  const cards = (...ids:string[]) => ids.map((id) => ({ id }));

  it('is false when the card was already moved into the target list', () => {
    expect(listNeedsReload(inProgress, cards('1', '42'), '42', toInProgress)).toBe(false);
  });

  it('is false when the card was already removed from the source list', () => {
    expect(listNeedsReload(newStatus, cards('1'), '42', toInProgress)).toBe(false);
  });

  it('is true when the target list does not show the card yet', () => {
    expect(listNeedsReload(inProgress, cards('1'), '42', toInProgress)).toBe(true);
  });

  it('is true when the source list still shows the card', () => {
    expect(listNeedsReload(newStatus, cards('1', '42'), '42', toInProgress)).toBe(true);
  });

  it('is false for a list the change does not touch', () => {
    expect(listNeedsReload('/api/v3/statuses/3', cards('1'), '42', toInProgress)).toBe(false);
  });

  it('is false without an action resource', () => {
    expect(listNeedsReload(undefined, cards('1'), '42', toInProgress)).toBe(false);
  });

  it('handles multi value attributes', () => {
    const versions:ChangeItem = { from: [], to: [{ href: '/api/v3/versions/1' }, { href: '/api/v3/versions/2' }] };

    expect(listNeedsReload('/api/v3/versions/2', cards('42'), '42', versions)).toBe(false);
    expect(listNeedsReload('/api/v3/versions/2', cards(), '42', versions)).toBe(true);
  });
});
