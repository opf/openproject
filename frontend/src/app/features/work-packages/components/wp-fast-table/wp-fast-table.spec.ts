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
import { buildWorkPackage } from './testing/work-package-fixture';
import { Highlighting } from './builders/highlighting/highlighting.functions';

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

  it('mirrors each row identifier onto its timeline cell', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });

    await harness.render();

    const cells = Array.from(harness.table.timelineBody.querySelectorAll<HTMLElement>('.wp-timeline-cell'));
    expect(cells.map((cell) => cell.dataset.classIdentifier)).toEqual(['wp-row-1', 'wp-row-2']);
    expect(cells.map((cell) => cell.dataset.workPackageId)).toEqual(['1', '2']);
  });

  it('renders existing selection and the current work package on initial render', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }] });
    harness.selection.initializeSelection(['2']);
    harness.focus.updateFocus('3', false, false);

    await harness.render();

    expect(harness.row('2')).toHaveClass('-checked');
    expect(harness.row('3')).toHaveClass('-pressed');
    expect(harness.row('1')).not.toHaveClass('-checked');
    expect(harness.row('1')).not.toHaveClass('-pressed');
  });

  it('repaints when the current work package changes', async () => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }] });
    await harness.render();

    harness.focus.updateFocus('1', false, false);
    harness.focus.updateFocus('2', false, false);

    expect(harness.row('1')).not.toHaveClass('-pressed');
    expect(harness.row('2')).toHaveClass('-pressed');
  });
  it('highlights the row of each work package when a relation row is spliced above it', async () => {
    const status = (id:string) => ({ status: { id, href: `/api/v3/statuses/${id}` } });
    harness = buildTable({
      workPackages: [
        { id: '1', attributes: status('11') },
        { id: '2', attributes: status('12') },
        { id: '3', attributes: status('13') },
      ],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      highlightingMode: 'status',
    });
    harness.expand('1', 'relationsOfTypeFollows');

    await harness.render();

    const relationRow = harness.tbody.querySelector('[data-occurrence-key="relation:ofType:1:2"]');
    expect(relationRow).toBe(harness.row('1').nextElementSibling);
    expect(harness.row('3')).toHaveClass(...Highlighting.backgroundClass('status', '13').split(' '));
    expect(relationRow).not.toHaveClass(Highlighting.resourceClass('status', '13'));
  });

  it('renders the children of a work package once when it is also a relation target', async () => {
    harness = buildTable({
      workPackages: [{ id: '2' }, { id: '1', children: [{ id: '3' }] }, { id: '3' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }, { id: 'children', children: true }],
      relations: [{ from: '2', to: '1', type: 'follows', reverseType: 'precedes' }],
      loadChildren: true,
    });
    harness.expand('2', 'relationsOfTypeFollows');
    harness.expand('1', 'children');

    await harness.render();

    expect(harness.tbody.querySelectorAll('[data-occurrence-key="relation:ofType:2:1"]')).toHaveLength(1);
    expect(harness.tbody.querySelectorAll('[data-occurrence-key="relation:children:1:3"]')).toHaveLength(1);
  });

  describe('refreshing a work package shown in several rows', () => {
    const occurrence = (key:string) => harness.tbody.querySelector<HTMLTableRowElement>(`[data-occurrence-key="${key}"]`)!;
    const subjectOf = (key:string) => occurrence(key).querySelector('td.subject')!.textContent.trim();
    const labelOf = (key:string) => occurrence(key).querySelector('.relation-row--type-label')?.textContent;
    const relationKeys = ['relation:ofType:1:2', 'relation:children:1:2'];

    beforeEach(async () => {
      harness = buildTable({
        workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }, { id: 'children', children: true }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      });
      harness.expand('1', 'relationsOfTypeFollows');
      await harness.render();
    });

    it('refreshes every row, including relation rows sharing one row identifier', () => {
      const labels = relationKeys.map(labelOf);
      expect(occurrence(relationKeys[0]).dataset.classIdentifier).toBe(occurrence(relationKeys[1]).dataset.classIdentifier);

      harness.table.refreshRows(buildWorkPackage({ id: '2', subject: 'Renamed' }));

      expect(['wp:2', ...relationKeys].map(subjectOf)).toEqual(['Renamed', 'Renamed', 'Renamed']);
      expect(relationKeys.map(labelOf)).toEqual(labels);
      expect(labels.every(Boolean)).toBe(true);
    });

    it('keeps the refreshed row registered with its occurrence', () => {
      harness.table.refreshRows(buildWorkPackage({ id: '1', subject: 'Renamed' }));

      expect(subjectOf('wp:1')).toBe('Renamed');
      expect(harness.table.ledger.byElement(harness.row('1'))?.key).toBe('wp:1');
    });
  });
});
