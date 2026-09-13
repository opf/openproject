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

import { within } from '@testing-library/dom';
import { buildTable, TableHarness } from './testing/table-harness';

describe('WorkPackageTable', () => {
  let harness:TableHarness;

  afterEach(() => harness?.destroy());

  it('renders one row per work package in result order', async () => {
    harness = buildTable({ workPackages: [{ id: '3' }, { id: '1' }, { id: '2' }] });

    const rendered = await harness.render();

    expect(harness.rows().map((row) => row.dataset.workPackageId)).toEqual(['3', '1', '2']);
    expect(rendered.map((row) => row.workPackageId)).toEqual(['3', '1', '2']);
  });

  it('renders one cell per configured column', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }], columns: ['id', 'subject', 'status'] });

    await harness.render();

    const cells = within(harness.row('1')).getAllByRole('cell');
    expect(cells).toHaveLength(3);
    expect(cells[0]).not.toHaveClass('subject');
    expect(cells[1]).toHaveClass('subject');
    expect(cells[2]).not.toHaveClass('subject');
  });
});
