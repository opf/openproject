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

import { States } from 'core-app/core/states/states.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { nextFrame } from 'core-common/testing/timing';
import { buildColumn, buildTable, TableHarness } from '../../testing/table-harness';
import { buildWorkPackage } from '../../testing/work-package-fixture';
import { SingleRowBuilder } from './single-row-builder';

describe('SingleRowBuilder with two tables showing the same work package', () => {
  const harnesses:TableHarness[] = [];
  let first:TableHarness;
  let second:TableHarness;

  const mount = async (states:States) => {
    const table = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], states });
    harnesses.push(table);
    await table.render();
    return table;
  };

  const subjectCell = (table:TableHarness) => table.row('1').querySelector('td.subject');

  beforeEach(async () => {
    const states = new States();
    first = await mount(states);
    second = await mount(states);
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('keeps the changed cells in the table that is editing', async () => {
    const openChange = { isEmpty: () => false, changedAttributes: ['subject'] };
    vi.spyOn(second.injector.get(HalResourceEditingService), 'typedState').mockImplementation(
      (resource:HalResource) => ({
        hasValue: () => false,
        value: resource.id === '1' ? openChange : undefined,
      }) as unknown as ReturnType<HalResourceEditingService['typedState']>,
    );
    const editedCell = subjectCell(second);
    const otherCell = subjectCell(first);

    second.table.redrawTable();
    await nextFrame();

    expect(subjectCell(second)).toBe(editedCell);
    expect(subjectCell(first)).toBe(otherCell);
  });
});

describe('SingleRowBuilder physical columns', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  const spannedColumns = (row:HTMLTableRowElement) => Array.from(row.cells)
    .reduce((total, cell) => total + cell.colSpan, 0);

  const mount = async (configuration:Record<string, boolean>, baseline:boolean) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      configuration,
      baseline,
    });
    harness.expand('1', 'relationsOfTypeFollows');
    await harness.render();
  };

  describe.each([true, false])('with drag and drop %s', (drag) => {
    describe.each([true, false])('and baseline %s', (baseline) => {
      it.each([true, false])('spans the same columns in every row with a trailing column %s', async (trailing) => {
        await mount({
          dragAndDropEnabled: drag,
          columnMenuEnabled: trailing,
        }, baseline);
        const expected = 3 + Number(drag) + Number(baseline) + Number(trailing);

        expect(spannedColumns(harness.row('1'))).toBe(expected);
        expect(spannedColumns(harness.row('2'))).toBe(expected);
        expect(spannedColumns(harness.relationRow('1', '2'))).toBe(expected);
        expect(new SingleRowBuilder(harness.injector, harness.table).placeholderRow.cells[0].colSpan).toBe(expected);
      });
    });
  });
});

describe('SingleRowBuilder baseline status text', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  const labels = {
    added: 'Added to view within the comparison time period',
    removed: 'Removed from view within the comparison time period',
    updated: 'Modified within the comparison time period',
  };

  const mount = async () => {
    harness = buildTable({
      workPackages: [{ id: '1', baseline: 'added' }, { id: '2', baseline: 'removed' }, { id: '3', baseline: 'updated' }, { id: '4' }],
      baseline: true,
      translations: {
        'js.work_packages.baseline.addition_label': labels.added,
        'js.work_packages.baseline.removal_label': labels.removed,
        'js.work_packages.baseline.modification_label': labels.updated,
      },
    });
    await harness.render();
  };

  const baselineCell = (workPackageId:string) => harness.row(workPackageId).querySelector<HTMLTableCellElement>('td.op-table-baseline--column-cell')!;

  it.each([
    ['1', 'added'],
    ['2', 'removed'],
    ['3', 'updated'],
  ] as const)('names row %s with its %s status', async (workPackageId, state) => {
    await mount();

    expect(harness.row(workPackageId)).toHaveAccessibleName(expect.stringContaining(labels[state]));
  });

  it('adds no status text to unchanged rows', async () => {
    await mount();

    expect(baselineCell('4')).toBeEmptyDOMElement();
    Object.values(labels).forEach((label) => {
      expect(harness.row('4')).not.toHaveAccessibleName(expect.stringContaining(label));
    });
  });

  it('rebuilds icon and status text together when the baseline state changes', async () => {
    await mount();

    harness.table.refreshRows(buildWorkPackage({ id: '1', baseline: 'removed' }));

    expect(baselineCell('1').querySelector('.op-table-baseline--icon-removed')).toBeInTheDocument();
    expect(baselineCell('1').querySelector('.op-table-baseline--icon-added')).not.toBeInTheDocument();
    expect(harness.row('1')).toHaveAccessibleName(expect.stringContaining(labels.removed));
    expect(harness.row('1')).not.toHaveAccessibleName(expect.stringContaining(labels.added));
    expect(baselineCell('1')).toHaveAttribute('role', 'gridcell');
  });
});

describe('SingleRowBuilder refresh with an active editor', () => {
  let harness:TableHarness;

  afterEach(() => harness.destroy());

  it('keeps the editor input focused while replacing non-retained cells', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }],
      editing: {},
      productionMarkup: true,
    });
    await harness.render();
    const subjectCell = harness.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    subjectCell.focus();
    fireEvent.keyDown(subjectCell, { key: 'Enter' });
    await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
    const input = within(harness.row('1')).getByRole('textbox');
    const idCell = harness.row('1').querySelector('td.id');

    harness.table.refreshRows(harness.injector.get(States).workPackages.get('1').value!);

    expect(input.isConnected).toBe(true);
    expect(input).toHaveFocus();
    expect(harness.row('1').querySelector('td.subject')).toBe(subjectCell);
    expect(harness.row('1').querySelector('td.id')).not.toBe(idCell);
  });

  it('replaces an untagged column menu cell instead of shifting the rebuilt cells', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }],
      editing: {},
      productionMarkup: true,
      configuration: { actionsColumnEnabled: false, columnMenuEnabled: true },
    });
    await harness.render();
    const subjectCell = harness.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    subjectCell.focus();
    fireEvent.keyDown(subjectCell, { key: 'Enter' });
    await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
    const cellCount = harness.row('1').cells.length;

    harness.table.refreshRows(harness.injector.get(States).workPackages.get('1').value!);

    expect(harness.row('1').cells).toHaveLength(cellCount);
    expect(harness.row('1').cells[0]).toHaveClass('id');
    expect(harness.row('1').cells[1]).toBe(subjectCell);
  });

  it('keeps an inline-create editor focused during refresh', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }],
      editing: {},
      productionMarkup: true,
    });
    await harness.render();
    const row = harness.addInlineCreateRow();
    const form = Object.values(harness.table.editing.forms)[0];
    const handler = await form.activate('subject');
    handler!.focus();
    const input = within(row).getByRole('textbox');
    const idCell = row.querySelector('td.id');
    const wp = form.resource;

    new SingleRowBuilder(harness.injector, harness.table).refreshRow(wp, row);

    expect(input.isConnected).toBe(true);
    expect(input).toHaveFocus();
    expect(row.querySelector('td.id')).not.toBe(idCell);
  });

  it('preserves augmented-column order around multiple retained editors', async () => {
    harness = buildTable({
      workPackages: [{ id: '1', attributes: { location: 'Here' } }],
      columns: ['id', 'subject', 'location'],
      editing: { fields: ['subject', 'location'] },
      productionMarkup: true,
    });
    await harness.render();
    const wp = harness.injector.get(States).workPackages.get('1').value!;
    harness.table.editing.startEditing(wp, harness.row('1').dataset.classIdentifier!);
    const form = harness.table.editing.forms['1'];
    const subject = await form.activate('subject');
    const location = await form.activate('location');
    subject!.focus();
    location!.focus();
    const input = within(harness.row('1').querySelector('td.location')!).getByRole('textbox');
    const columnClasses = () => Array.from(harness.row('1').querySelectorAll('td.wp-table--cell-td'))
      .map((cell) => cell.classList.contains('created_at') ? 'created_at'
        : cell.classList.contains('location') ? 'location'
          : cell.classList.contains('subject') ? 'subject' : 'id');
    const refreshWith = (columns:string[]) => {
      const builder = new SingleRowBuilder(harness.injector, harness.table);
      Object.defineProperty(builder, 'augmentedColumns', { value: columns.map(buildColumn) });
      builder.refreshRow(wp, harness.row('1'));
    };

    refreshWith(['location', 'subject', 'id']);
    expect(columnClasses()).toEqual(['location', 'subject', 'id']);
    expect(input).toHaveFocus();

    refreshWith(['id', 'created_at', 'location', 'subject']);
    expect(columnClasses()).toEqual(['id', 'created_at', 'location', 'subject']);
    expect(input).toHaveFocus();

    refreshWith(['location', 'subject']);
    expect(columnClasses()).toEqual(['location', 'subject']);
    expect(input).toHaveFocus();
  });

  it('retains the editor cell with its role, the row level and selection', async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      editing: {},
    });
    await harness.render();
    harness.click('1');
    const subjectCell = harness.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    subjectCell.focus();
    fireEvent.keyDown(subjectCell, { key: 'Enter' });
    await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
    expect(within(harness.row('1')).getByRole('textbox').closest('td')).toBe(subjectCell);

    harness.table.refreshRows(harness.injector.get(States).workPackages.get('1').value!);

    expect(within(harness.row('1')).getByRole('textbox').closest('td')).toBe(subjectCell);
    expect(subjectCell).toHaveAttribute('role', 'rowheader');
    expect(subjectCell).toHaveAccessibleName('Work package 1');
    expect(harness.row('1')).toHaveAttribute('aria-level', '1');
    expect(harness.row('1')).toHaveAttribute('aria-selected', 'true');
  });

  it('refreshes duplicate displays while retaining only the active occurrence editor', async () => {
    harness = buildTable({
      workPackages: [
        { id: '1', children: [{ id: '2', subject: 'Original' }] },
        { id: '3', children: [{ id: '2', subject: 'Original' }] },
        { id: '2', subject: 'Original' },
      ],
      columns: [
        'id', 'subject',
        { id: 'relationsOfTypeFollows', relationType: 'follows' },
        { id: 'children', children: true },
      ],
      relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
      editing: {},
    });
    harness.expand('1', 'relationsOfTypeFollows');
    harness.expand('3', 'children');
    await harness.render();

    [harness.row('2'), harness.relationRow('1', '2'), harness.relationRow('3', '2', 'children')]
      .forEach((row) => {
        expect(within(row).getAllByRole('rowheader')).toHaveLength(1);
        expect(within(row).getByRole('rowheader', { name: 'Original' })).toHaveClass('subject');
      });

    const origin = harness.row('2').querySelector<HTMLTableCellElement>('td.subject')!;
    const siblingCells = [
      harness.relationRow('1', '2').querySelector('td.subject'),
      harness.relationRow('3', '2', 'children').querySelector('td.subject'),
    ];

    const navigation = harness.table.keyboardNavigation!;
    navigation.focusPosition(navigation.positionOfCell(origin)!);
    fireEvent.keyDown(origin, { key: 'Enter' });
    const input = await waitFor(() => within(origin).getByRole<HTMLInputElement>('textbox'));
    await waitFor(() => expect(input).toHaveFocus());
    input.value = 'Draft in the origin';

    const form = harness.table.editing.forms['2'];
    const handler = form.activeFields.subject;
    const renamed = buildWorkPackage({ id: '2', subject: 'Renamed' });
    form.resource = renamed;
    harness.injector.get(States).workPackages.get('2').putValue(renamed);

    await waitFor(() => {
      [harness.relationRow('1', '2'), harness.relationRow('3', '2', 'children')]
        .forEach((row, index) => {
          const cell = row.querySelector('td.subject')!;
          expect(cell).not.toBe(siblingCells[index]);
          expect(within(row).getByRole('rowheader', { name: 'Renamed' })).toBe(cell);
          expect(cell.querySelector('.inline-edit--display-field')).toHaveTextContent('Renamed');
          expect(within(row).queryByRole('textbox')).toBeNull();
        });
    });

    expect(harness.row('2').querySelector('td.subject')).toBe(origin);
    expect(within(origin).getByRole('textbox')).toBe(input);
    expect(input).toHaveFocus();
    expect(input).toHaveValue('Draft in the origin');
    expect(form.activeFields.subject).toBe(handler);
    expect(origin).toHaveAccessibleName('Original');

    handler.deactivate(true, true);
    await waitFor(() => expect(within(origin).queryByRole('textbox')).toBeNull());

    expect(origin).toHaveFocus();
    expect(origin.querySelector('.inline-edit--display-field')).toHaveTextContent('Renamed');
    [harness.row('2'), harness.relationRow('1', '2'), harness.relationRow('3', '2', 'children')]
      .forEach((row) => {
        expect(within(row).getAllByRole('rowheader')).toHaveLength(1);
        expect(within(row).getByRole('rowheader', { name: 'Renamed' })).toHaveClass('subject');
        expect(within(row).queryByRole('rowheader', { name: 'Original', hidden: true })).toBeNull();
      });
  });
});
