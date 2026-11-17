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

import {
  compareByIdentity, entitySelectionToModel, referenceSource, trackByIdentity,
} from './entity-selection';

describe('compareByIdentity', () => {
  it('matches a scalar ID against an option with that ID', () => {
    expect(compareByIdentity(7, { id: 7, name: 'Seven', href: '/api/v3/users/7' })).toBe(true);
    expect(compareByIdentity('7', { id: 7, name: 'Seven', href: '/api/v3/users/7' })).toBe(true);
    expect(compareByIdentity(7, { id: 8, name: 'Eight', href: '/api/v3/users/8' })).toBe(false);
  });
});

describe('trackByIdentity', () => {
  it('tracks a scalar ID by itself', () => {
    expect(trackByIdentity(7)).toBe(7);
  });
});

describe('referenceSource', () => {
  const pathFor = (id:string|number) => `/api/v3/things/${id}`;

  it('builds the path for ID 0', () => {
    expect(referenceSource({ id: 0 }, pathFor)).toEqual({ id: 0, href: '/api/v3/things/0' });
  });

  it('prefers a supplied href over the built path', () => {
    expect(referenceSource({ id: 1, href: '/custom', name: 'One' }, pathFor)).toEqual({
      id: 1,
      href: '/custom',
      name: 'One',
    });
  });

  it('falls back to the path when the href is empty', () => {
    expect(referenceSource({ id: 2, href: '' }, pathFor)).toEqual({ id: 2, href: '/api/v3/things/2' });
  });
});

describe('entitySelectionToModel', () => {
  it('maps each selection kind to its raw model', () => {
    const option = { id: 1, name: 'One', href: null };
    const reference = { id: 2 };

    expect(entitySelectionToModel(null)).toBeNull();
    expect(entitySelectionToModel({ kind: 'option', option })).toBe(option);
    expect(entitySelectionToModel({ kind: 'reference', reference })).toBe(reference);
  });
});
