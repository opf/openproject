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

import { buildTable, TableHarness } from '../../../testing/table-harness';
import { hierarchyOrder } from './hierarchy-order';

describe('Hierarchy ordering across query windows', () => {
  let harness:TableHarness;
  const parent = { id: '1' };
  const child = { id: '2', ancestors: [parent] };
  const other = { id: '3' };

  afterEach(() => harness?.destroy());

  it('inserts a parent absent from the result window before its first child', async () => {
    harness = buildTable({ workPackages: [child, other], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });

  it('renders a parent before a child that precedes it in the results', async () => {
    harness = buildTable({ workPackages: [child, other, parent], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });

  it('keeps a child under an earlier parent', async () => {
    harness = buildTable({ workPackages: [parent, other, child], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });
});

describe('hierarchyOrder', () => {
  const node = (id:string, ...ancestorIds:string[]) => ({ id, ancestorIds });

  it.each([
    ['flat results', [node('a'), node('b')], ['a', 'b']],
    ['a child before its parent', [node('c', 'p'), node('o'), node('p')], ['p', 'c', 'o']],
    ['a contextual parent', [node('c', 'p'), node('o')], ['p', 'c', 'o']],
    ['nested contextual ancestors', [node('g', 'r', 'm'), node('r2')], ['r', 'm', 'g', 'r2']],
    ['siblings under a shared contextual parent', [node('c1', 'p'), node('o'), node('c2', 'p')], ['p', 'c1', 'c2', 'o']],
    ['a parent ranked before its children', [node('p'), node('o'), node('c', 'p')], ['p', 'c', 'o']],
  ])('orders %s depth first by earliest rank', (_name, results, expected) => {
    expect(hierarchyOrder(results)).toEqual(expected);
  });

  it('follows server positions over the page rank', () => {
    const results = [node('y'), node('x2', 'x')];
    const positions = {
      x: { position: 1, parent: null },
      x2: { position: 3, parent: 'x' },
      y: { position: 5, parent: null },
    };
    expect(hierarchyOrder(results, positions)).toEqual(['x', 'x2', 'y']);
  });

  it.each([
    ['an entry is missing', { x: { position: 1, parent: null }, x2: { position: 3, parent: 'x' } }],
    ['a parent disagrees', { x: { position: 1, parent: null }, x2: { position: 3, parent: null }, y: { position: 5, parent: null } }],
  ])('falls back to the page rank when %s', (_name, positions) => {
    expect(hierarchyOrder([node('y'), node('x2', 'x')], positions)).toEqual(['y', 'x', 'x2']);
  });
});
