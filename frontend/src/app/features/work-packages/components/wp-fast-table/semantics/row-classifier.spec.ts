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

import { buildTable, TableHarness, TableHarnessOptions } from '../testing/table-harness';
import type { WorkPackageFixture } from '../testing/work-package-fixture';
import { ancestorOccurrenceKey, groupOccurrenceKey, wpOccurrenceKey } from '../rendered-occurrence-ledger';
import type { RowRecord } from './row-classifier';

const newStatus = { href: '/api/v3/statuses/1' };
const parent:WorkPackageFixture = { id: '1' };

describe('RowClassifier', () => {
  let harness:TableHarness;

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], productionMarkup: true, ...options });
    await harness.render();
  };
  const rows = () => harness.table.rows.rows();
  const byKey = (key:string):RowRecord => rows().find((row) => row.key === key)!;

  afterEach(() => harness?.destroy());

  it('lists the header, every rendered occurrence and the trailing rows in document order', async () => {
    await mount();

    expect(rows().map(({ key, state }) => [key, state.kind])).toEqual([
      ['header', 'header'],
      [wpOccurrenceKey('1'), 'workPackage'],
      [wpOccurrenceKey('2'), 'workPackage'],
      ['totals', 'totals'],
    ]);
    expect(byKey(wpOccurrenceKey('1')).element).toBe(harness.row('1'));
    expect(byKey('header').element).toBe(harness.headerRow());
  });

  it('reports selection only for work package occurrences', async () => {
    await mount();
    harness.click('2');

    expect(byKey(wpOccurrenceKey('1')).state.selected).toBe(false);
    expect(byKey(wpOccurrenceKey('2')).state.selected).toBe(true);
    expect(byKey('header').state.selected).toBeNull();
  });

  it('classifies group headers and sums with their expansion', async () => {
    await mount({
      workPackages: [{ id: '1', attributes: { status: newStatus } }],
      groups: [{ value: 'New', href: newStatus.href, count: 1, sums: { storyPoints: 5 } }],
    });

    expect(byKey(groupOccurrenceKey(0, 'header')).state).toMatchObject({ kind: 'groupHeader', expanded: true, exposed: true });
    expect(byKey(groupOccurrenceKey(0, 'sums')).state).toMatchObject({ kind: 'sums', expanded: null });
  });

  it('marks hierarchy parents expandable and leaves leaves without expansion', async () => {
    await mount({ workPackages: [{ id: '2', ancestors: [parent] }], showHierarchies: true });

    expect(byKey(ancestorOccurrenceKey('1')).state).toMatchObject({ kind: 'workPackage', expanded: true, level: 1 });
    expect(byKey(wpOccurrenceKey('2')).state).toMatchObject({ kind: 'workPackage', expanded: null, level: 2 });
  });

  it('includes the empty-results row and the inline-create row with fixed keys', async () => {
    await mount({ workPackages: [], configuration: { inlineCreateEnabled: true } });
    const emptyBody = harness.tbody.closest('table')!.createTBody();
    emptyBody.classList.add('work-package--empty-tbody');
    const empty = emptyBody.insertRow();
    empty.insertCell().textContent = 'No work packages';
    const create = harness.addInlineCreateRow();

    expect(byKey('emptyResults').element).toBe(empty);
    expect(byKey('inlineCreate')).toMatchObject({ element: create, state: { kind: 'inlineCreate' } });
  });

  it('reports a row no producer declared as foreign rather than skipping it', async () => {
    await mount();
    const stray = harness.tbody.insertRow();
    stray.insertCell().textContent = 'stray';

    expect(rows().find((row) => row.element === stray)).toMatchObject({ key: null, state: { kind: 'foreign' } });
  });
});
