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

  it('currently defers the child when its parent is in the same window', async () => {
    harness = buildTable({ workPackages: [child, other, parent], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['3', '1', '2']);
  });

  it('keeps a child under an earlier parent', async () => {
    harness = buildTable({ workPackages: [parent, other, child], showHierarchies: true });
    await harness.render();
    expect(harness.rowIds()).toEqual(['1', '2', '3']);
  });
});
