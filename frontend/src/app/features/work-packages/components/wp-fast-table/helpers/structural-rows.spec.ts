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

import { buildTable, TableHarness } from '../testing/table-harness';
import { groupOccurrenceKey, placeholderOccurrenceKey, type RenderedOccurrence } from '../rendered-occurrence-ledger';
import {
  classifyRow, headerRowOf, isEmptyResultsRow, isExposedRow, isInlineCreateRow, isTotalsRow, occurrenceRowKind, totalsRowOf,
} from './structural-rows';

describe('structural rows', () => {
  let harness:TableHarness;

  afterEach(() => harness?.destroy());

  it('classifies the totals row below the results but not a group sums row', async () => {
    const status = { href: '/api/v3/statuses/1' };
    harness = buildTable({
      workPackages: [{ id: '1', attributes: { status } }],
      productionMarkup: true,
      groups: [{ value: 'G', href: status.href, count: 1, sums: { storyPoints: 1 } }],
    });
    await harness.render();
    const groupSums = harness.table.ledger.byKey(groupOccurrenceKey(0, 'sums'))!.element!;
    expect(isTotalsRow(harness.table, harness.totalsRow())).toBe(true);
    expect(isTotalsRow(harness.table, groupSums)).toBe(false);
    expect(totalsRowOf(harness.table)).toBe(harness.totalsRow());
    expect(headerRowOf(harness.table)).toBe(harness.headerRow());
  });

  it('classifies the create and empty-results rows by their sections', async () => {
    harness = buildTable({ workPackages: [], productionMarkup: true });
    await harness.render();
    const createRow = harness.table.tbody.closest('table')!.querySelector<HTMLTableRowElement>('tbody[wpInlineCreate] tr')!;
    const empty = document.createElement('tbody');
    empty.className = 'work-package--empty-tbody';
    const emptyRow = empty.insertRow();
    harness.tbody.before(empty);
    expect(isInlineCreateRow(createRow)).toBe(true);
    expect(isInlineCreateRow(harness.totalsRow())).toBe(false);
    expect(isEmptyResultsRow(emptyRow)).toBe(true);
    expect(isEmptyResultsRow(createRow)).toBe(false);
  });

  it('treats rows hidden themselves or by their section as not exposed', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }], productionMarkup: true });
    await harness.render();
    const row = harness.row('1');
    expect(isExposedRow(row)).toBe(true);
    row.setAttribute('aria-hidden', 'true');
    expect(isExposedRow(row)).toBe(false);
    row.removeAttribute('aria-hidden');
    row.hidden = true;
    expect(isExposedRow(row)).toBe(false);
    row.hidden = false;
    harness.tbody.setAttribute('aria-hidden', 'true');
    expect(isExposedRow(row)).toBe(false);
  });

  describe('classifyRow', () => {
    const createRow = () => harness.table.tbody.closest('table')!.querySelector<HTMLTableRowElement>('tbody[wpInlineCreate] tr')!;

    it('names every row of a grouped table once', async () => {
      const status = { href: '/api/v3/statuses/1' };
      harness = buildTable({
        workPackages: [{ id: '1', attributes: { status } }],
        productionMarkup: true,
        groups: [{ value: 'G', href: status.href, count: 1, sums: { storyPoints: 1 } }],
      });
      await harness.render();
      const kind = (row:HTMLTableRowElement) => classifyRow(harness.table, row);
      expect(kind(harness.groupHeader(0))).toBe('groupHeader');
      expect(kind(harness.row('1'))).toBe('workPackage');
      expect(kind(harness.table.ledger.byKey(groupOccurrenceKey(0, 'sums'))!.element!)).toBe('sums');
      expect(kind(harness.totalsRow())).toBe('totals');
      expect(kind(createRow())).toBe('create');
    });

    it('names placeholder, empty, unexposed and unknown rows', async () => {
      harness = buildTable({ workPackages: [], productionMarkup: true, configuration: { dragAndDropEnabled: true } });
      await harness.render();
      const kind = (row:HTMLTableRowElement) => classifyRow(harness.table, row);
      const empty = document.createElement('tbody');
      empty.className = 'work-package--empty-tbody';
      const emptyRow = empty.insertRow();
      harness.tbody.before(empty);
      const unknown = harness.tbody.closest('table')!.createTBody().insertRow();
      expect(kind(harness.table.ledger.byKey(placeholderOccurrenceKey())!.element!)).toBe('placeholder');
      expect(kind(emptyRow)).toBe('empty');
      expect(kind(unknown)).toBe('foreign');
      unknown.hidden = true;
      expect(kind(unknown)).toBe('unexposed');
    });

    it('treats an occurrence it cannot name as foreign', () => {
      const occurrence = { key: 'banner', workPackageId: null } as RenderedOccurrence;
      expect(occurrenceRowKind(occurrence)).toBe('foreign');
    });
  });
});
