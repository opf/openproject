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

import { WorkPackageTableConfiguration } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { buildTable, TableHarness } from './table-harness';

describe('table harness production markup', () => {
  let harness:TableHarness|undefined;

  afterEach(async () => {
    await harness?.destroy();
    harness = undefined;
  });

  it('renders a sticky header row with one cell per column plus the configuration cell, and a totals row', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }], columns: ['id', 'subject'], productionMarkup: true });
    await harness.render();

    expect(harness.headerCells().map((th) => th.textContent?.trim())).toEqual(['id', 'subject', '']);
    expect(harness.headerRow().closest('thead')).toHaveClass('-sticky');
    expect(harness.totalsRow()).toHaveClass('wp-table--sums-row');
    expect(harness.headerCells()[0].querySelector('a[href]')).not.toBeNull();
    expect(harness.headerCells()[2].querySelector('button.wp-table--columns-selection')).not.toBeNull();
  });

  it('keyboardNavigationEnabled defaults to false and can be turned on', () => {
    expect(new WorkPackageTableConfiguration({}).keyboardNavigationEnabled).toBe(false);
    expect(new WorkPackageTableConfiguration({ keyboardNavigationEnabled: true }).keyboardNavigationEnabled).toBe(true);
  });
});
