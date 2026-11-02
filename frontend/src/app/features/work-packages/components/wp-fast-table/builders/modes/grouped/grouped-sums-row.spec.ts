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

import { fireEvent, waitFor, within } from '@testing-library/dom';
import { groupOccurrenceKey } from '../../../rendered-occurrence-ledger';
import { buildTable, TableHarness } from '../../../testing/table-harness';
import { GroupSumsBuilder } from './group-sums-builder';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

describe('Grouped table sums rows', () => {
  let harness:TableHarness;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: newStatus } },
        { id: '3', attributes: { status: inProgressStatus } },
        { id: '4', attributes: { status: inProgressStatus } },
      ],
      groups: [
        { value: 'New', href: newStatus.href, count: 2, sums: { storyPoints: 13 } },
        { value: 'In progress', href: inProgressStatus.href, count: 2, sums: { storyPoints: 21 } },
      ],
      timelineVisible: true,
    });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const toggleGroup = (index:number) => {
    fireEvent.click(harness.groupHeader(index).querySelector('.expander')!);
  };

  const sumLabels = () => within(harness.tbody).getAllByText('js.label_sum');
  const sumsRow = (index:number) => sumLabels()[index].closest('tr')!;
  const sumsTimelineRow = (index:number) => harness.timelineRowOf(sumsRow(index));
  const sumOf = (value:number) => within(harness.tbody).getByText(String(value));

  const addStoryPointsColumn = async () => {
    harness.setColumns(['id', 'subject', 'storyPoints']);
    await waitFor(() => expect(sumOf(21)).toBeVisible());
  };

  it('ends every group with a sums row', () => {
    expect(sumLabels()).toHaveLength(2);
    expect(harness.row('2').nextElementSibling).toContainElement(sumLabels()[0]);
    expect(harness.row('4').nextElementSibling).toContainElement(sumLabels()[1]);
    sumLabels().forEach((label) => expect(label).toBeVisible());
    expect(sumsTimelineRow(0)).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();
  });

  it('hides the sums row of a collapsed group', async () => {
    toggleGroup(0);

    await waitFor(() => expect(sumLabels()[0]).not.toBeVisible());
    expect(sumsTimelineRow(0)).not.toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();

    toggleGroup(0);

    await waitFor(() => expect(sumLabels()[0]).toBeVisible());
    expect(sumsTimelineRow(0)).toBeVisible();
  });

  it('keeps the sums row of a collapsed group hidden when a column is added', async () => {
    toggleGroup(0);
    await waitFor(() => expect(sumLabels()[0]).not.toBeVisible());

    await addStoryPointsColumn();

    expect(harness.row('1')).not.toBeVisible();
    expect(sumLabels()[0]).not.toBeVisible();
    expect(sumOf(13)).not.toBeVisible();
    expect(sumsTimelineRow(0)).not.toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();

    toggleGroup(0);

    await waitFor(() => expect(sumOf(13)).toBeVisible());
    expect(sumLabels()[0]).toBeVisible();
    expect(sumsTimelineRow(0)).toBeVisible();
  });

  it('shows the sums row of an expanded group when a column is added', async () => {
    await addStoryPointsColumn();

    expect(sumLabels()[0]).toBeVisible();
    expect(sumOf(13)).toBeVisible();
    expect(sumLabels()[1]).toBeVisible();
    expect(sumsTimelineRow(0)).toBeVisible();
    expect(sumsTimelineRow(1)).toBeVisible();
  });

  it('tags group header and sums occurrences with the group identifier', () => {
    const identifier = harness.groupHeader(1).dataset.groupIdentifier;

    expect(identifier).toBeTruthy();
    expect(harness.table.ledger.byKey(groupOccurrenceKey(1, 'header'))?.groupIdentifier).toBe(identifier);
    expect(harness.table.ledger.byKey(groupOccurrenceKey(1, 'sums'))?.groupIdentifier).toBe(identifier);
  });
});

describe('Grouped table sums physical columns', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  const mount = async (configuration:Record<string, boolean>, baseline:boolean) => {
    harness = buildTable({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: newStatus } },
      ],
      groups: [{ value: 'New', href: newStatus.href, count: 2, sums: { storyPoints: 13 } }],
      columns: ['id', 'subject'],
      configuration,
      baseline,
    });
    await harness.render();
  };

  const spannedColumns = (row:HTMLTableRowElement) => Array.from(row.cells)
    .reduce((total, cell) => total + cell.colSpan, 0);

  describe.each([true, false])('on an enabled table with drag and drop %s', (drag) => {
    describe.each([true, false])('and baseline %s', (baseline) => {
      it.each([true, false])('spans the same columns in sums and totals rows with a trailing column %s', async (trailing) => {
        await mount({
          keyboardNavigationEnabled: true,
          dragAndDropEnabled: drag,
          columnMenuEnabled: trailing,
        }, baseline);
        const expected = 2 + Number(drag) + Number(baseline) + Number(trailing);
        const totals = document.createElement('tr');
        new GroupSumsBuilder(harness.injector, harness.table).renderColumns({ storyPoints: 34 }, totals, 'total');

        expect(spannedColumns(harness.row('2').nextElementSibling as HTMLTableRowElement)).toBe(expected);
        expect(spannedColumns(totals)).toBe(expected);
      });
    });
  });

  it('keeps the trailing sums cell of a capability-off table', async () => {
    await mount({ dragAndDropEnabled: true, columnMenuEnabled: false, actionsColumnEnabled: false }, true);

    expect((harness.row('2').nextElementSibling as HTMLTableRowElement).cells).toHaveLength(2 + 1 + 1 + 1);
  });
});

describe('Grouped table sums labels on an enabled table', () => {
  const harnesses:TableHarness[] = [];

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  const mount = async (dragAndDropEnabled:boolean) => {
    const harness = buildTable({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: inProgressStatus } },
      ],
      groups: [
        { value: 'New', href: newStatus.href, count: 1, sums: { storyPoints: 13 } },
        { value: 'In progress', href: inProgressStatus.href, count: 1, sums: { storyPoints: 21 } },
      ],
      columns: ['id', 'subject', 'storyPoints'],
      translations: { 'js.label_sum': 'Sum' },
      configuration: { keyboardNavigationEnabled: true, dragAndDropEnabled },
    });
    harnesses.push(harness);
    await harness.render();
    return harness;
  };

  const sumsRowAfter = (harness:TableHarness, workPackageId:string) => harness.row(workPackageId).nextElementSibling as HTMLTableRowElement;
  const sumLabel = (row:HTMLTableRowElement) => within(row).getByText('Sum');

  it.each([true, false])('names the sums row and describes its values with drag and drop %s', async (drag) => {
    const harness = await mount(drag);
    const row = sumsRowAfter(harness, '1');
    const valueCell = within(row).getByText('13').closest('td')!;

    expect(row).toHaveAccessibleName(expect.stringContaining('Sum'));
    expect(row).toHaveAccessibleName(expect.stringContaining('13'));
    expect(valueCell).toHaveAccessibleDescription('Sum');
    Array.from(row.cells).filter((cell) => cell !== valueCell).forEach((cell) => {
      expect(cell).not.toHaveAttribute('aria-describedby');
    });
  });

  it('gives every sums label an ID unique to its table and group', async () => {
    const first = await mount(false);
    const second = await mount(false);
    const ids = [
      sumLabel(sumsRowAfter(first, '1')).id,
      sumLabel(sumsRowAfter(first, '2')).id,
      sumLabel(sumsRowAfter(second, '1')).id,
    ];

    ids.forEach((id) => expect(id).toBeTruthy());
    expect(new Set(ids).size).toBe(3);
  });

  it('adds no label IDs or descriptions on a capability-off table', async () => {
    const harness = buildTable({
      workPackages: [{ id: '1', attributes: { status: newStatus } }],
      groups: [{ value: 'New', href: newStatus.href, count: 1, sums: { storyPoints: 13 } }],
      columns: ['id', 'subject', 'storyPoints'],
      translations: { 'js.label_sum': 'Sum' },
    });
    harnesses.push(harness);
    await harness.render();
    const row = sumsRowAfter(harness, '1');

    expect(sumLabel(row)).not.toHaveAttribute('id');
    Array.from(row.cells).forEach((cell) => expect(cell).not.toHaveAttribute('aria-describedby'));
  });
});
