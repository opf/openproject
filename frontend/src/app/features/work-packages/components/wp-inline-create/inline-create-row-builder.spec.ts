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

import { waitFor, within } from '@testing-library/dom';
import { buildColumn, buildTable, consumerConfiguration, ConsumerName, TableHarness } from '../wp-fast-table/testing/table-harness';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { QueryColumn } from 'core-app/features/work-packages/components/wp-query/query-column';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { States } from 'core-app/core/states/states.service';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { inlineCreateCancelClassName } from './inline-create-cancel-button';

describe('InlineCreateRowBuilder', () => {
  const harnesses:TableHarness[] = [];

  const mount = async (name:ConsumerName, editing?:{ fields?:string[] }, overrides:WorkPackageTableConfigurationObject = {}) => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      productionMarkup: true,
      editing,
      translations: { 'js.button_cancel': 'Cancel' },
      configuration: { ...consumerConfiguration(name), ...overrides },
    });
    harnesses.push(table);
    await table.render();
    table.table.tbody.closest('table')!.classList.add('generic-table');
    return table;
  };

  const cancelButtons = (row:HTMLElement) => row.querySelectorAll(`.${inlineCreateCancelClassName}`);

  const expectCancelBesideField = async (row:HTMLTableRowElement) => {
    const cell = row.lastElementChild as HTMLTableCellElement;
    const cellBox = cell.getBoundingClientRect();
    const fieldBox = cell.querySelector('.wp-table--cell-container')!.getBoundingClientRect();
    const buttonBox = (await within(cell).findByRole('button', { name: 'Cancel' })).getBoundingClientRect();

    expect(getComputedStyle(cell).display).toBe('table-cell');
    expect(cellBox.height).toBe(row.getBoundingClientRect().height);
    expect(buttonBox.top).toBeGreaterThanOrEqual(cellBox.top);
    expect(buttonBox.bottom).toBeLessThanOrEqual(cellBox.bottom);
    expect(buttonBox.left).toBeGreaterThanOrEqual(cellBox.left);
    expect(buttonBox.right).toBeLessThanOrEqual(cellBox.right);
    expect(buttonBox.left >= fieldBox.right || buttonBox.right <= fieldBox.left).toBe(true);
    expect(buttonBox.top).toBeLessThan(fieldBox.bottom);
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  describe('without a trailing column', () => {
    it('renders as many cells as the header', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
    });

    it('keeps a single Cancel button in the last rendered cell', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      expect(cancelButtons(row)).toHaveLength(1);
      expect(await within(row.lastElementChild as HTMLElement).findByRole('button', { name: 'Cancel' })).toBeInTheDocument();
      expect(row.querySelectorAll('td.wp-table--cancel-create-td')).toHaveLength(0);
    });

    it('renders the Cancel control as an icon button in the last cell', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      const button = await within(row.lastElementChild as HTMLElement).findByRole('button', { name: 'Cancel' });
      expect(button).toHaveAttribute('type', 'button');
      expect(button.closest(`.${inlineCreateCancelClassName}`)).not.toBeNull();
    });

    it('lays out the Cancel button beside the field in a cell that fills the row height', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      expect(cancelButtons(row)).toHaveLength(1);
      await expectCancelBesideField(row);
    });

    it('keeps the Cancel button beside the field in a right-to-left table', async () => {
      const table = await mount('macro');
      table.table.tbody.closest('.work-package-table--container')!.setAttribute('dir', 'rtl');

      const row = table.addInlineCreateRow();

      const cell = row.lastElementChild as HTMLTableCellElement;
      const field = cell.querySelector('.wp-table--cell-container')!;
      expect((await within(cell).findByRole('button', { name: 'Cancel' })).getBoundingClientRect().right)
        .toBeLessThanOrEqual(field.getBoundingClientRect().left);
      await expectCancelBesideField(row);
    });

    it('keeps the Cancel button beside an effort field', async () => {
      const table = await mount('macro');
      const columns = table.injector.get(WorkPackageViewColumnsService);
      vi.spyOn(columns, 'getColumns').mockReturnValue([...columns.getColumns(), buildColumn('estimatedTime') as QueryColumn]);

      const row = table.addInlineCreateRow();

      expect(row.lastElementChild).toHaveClass('estimatedTime');
      await expectCancelBesideField(row);
    });

    it('keeps the cell count and button after refreshRow', async () => {
      const table = await mount('macro');
      const row = table.addInlineCreateRow();
      const builder = table.inlineCreateRowBuilder();
      const workPackage = table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!;

      builder.refreshRow(workPackage, row);

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(cancelButtons(row)).toHaveLength(1);
    });
  });

  it.each([['subject'], ['id', 'subject']])('keeps %j columns as native data cells through refresh', async (...columns) => {
    const table = await mount('macro');
    const columnService = table.injector.get(WorkPackageViewColumnsService);
    vi.spyOn(columnService, 'getColumns').mockReturnValue(columns.map((id) => buildColumn(id) as QueryColumn));
    const row = table.addInlineCreateRow();
    const builder = table.inlineCreateRowBuilder();
    const workPackage = table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!;

    for (const refresh of [false, true]) {
      if (refresh) builder.refreshRow(workPackage, row);
      expect(Array.from(row.cells).every((cell) => cell.tagName === 'TD')).toBe(true);
      expect(within(row).queryAllByRole('rowheader')).toEqual([]);
      expect(row).not.toHaveAttribute('aria-labelledby');
      expect(await within(row.lastElementChild as HTMLElement).findByRole('button', { name: 'Cancel' })).toBeInTheDocument();
    }
  });

  describe('with a trailing column', () => {
    it('keeps the Cancel button in its own cell', async () => {
      const table = await mount('search', undefined, { inlineCreateEnabled: true });

      const row = table.addInlineCreateRow();

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(row.querySelectorAll('td.wp-table--cancel-create-td')).toHaveLength(1);
      expect(cancelButtons(row)).toHaveLength(1);
    });
  });

  describe('while editing', () => {
    it('keeps the Cancel button beside the field editor in the last column', async () => {
      const table = await mount('macro', {});
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      const handler = await form.activate('subject');
      handler!.focus();
      const editedCell = row.querySelector<HTMLTableCellElement>('td.subject')!;
      await waitFor(() => expect(editedCell.querySelector('input.inline-edit--field')).toHaveFocus());

      expect(row.lastElementChild).toBe(editedCell);
      await expectCancelBesideField(row);
    });

    it('keeps the cell count and button while the last column is being edited', async () => {
      const table = await mount('macro', {});
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      const handler = await form.activate('subject');
      handler!.focus();
      const editor = row.querySelector('input.inline-edit--field')!;
      await waitFor(() => expect(editor).toHaveFocus());
      const builder = table.inlineCreateRowBuilder();

      builder.refreshRow(table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!, row);

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(cancelButtons(row)).toHaveLength(1);
      expect(row.contains(editor)).toBe(true);
    });

    it('moves the Cancel button to a column appended while the last column is being edited', async () => {
      const table = await mount('macro', {});
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      const handler = await form.activate('subject');
      handler!.focus();
      const editedCell = row.querySelector<HTMLTableCellElement>('td.subject')!;
      await waitFor(() => expect(editedCell.querySelector('input.inline-edit--field')).toHaveFocus());
      const columns = table.injector.get(WorkPackageViewColumnsService);
      const appended = [...columns.getColumns(), buildColumn('status') as QueryColumn];
      vi.spyOn(columns, 'getColumns').mockReturnValue(appended);
      const builder = table.inlineCreateRowBuilder();

      builder.refreshRow(table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!, row);

      expect(row.querySelector('td.subject')).toBe(editedCell);
      expect(cancelButtons(row)).toHaveLength(1);
      expect(row.lastElementChild!.querySelector(`.${inlineCreateCancelClassName}`)).not.toBeNull();
      expect(editedCell).not.toHaveClass('wp-table--cancel-create-host');
    });

    it('moves the Cancel button onto the edited cell when the column after it is removed', async () => {
      const table = await mount('macro', {});
      const columns = table.injector.get(WorkPackageViewColumnsService);
      const original = columns.getColumns();
      const getColumns = vi.spyOn(columns, 'getColumns').mockReturnValue([...original, buildColumn('status') as QueryColumn]);
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      const handler = await form.activate('subject');
      handler!.focus();
      const editedCell = row.querySelector<HTMLTableCellElement>('td.subject')!;
      await waitFor(() => expect(editedCell.querySelector('input.inline-edit--field')).toHaveFocus());
      expect(editedCell.querySelector(`.${inlineCreateCancelClassName}`)).toBeNull();
      getColumns.mockReturnValue(original);
      const builder = table.inlineCreateRowBuilder();

      builder.refreshRow(table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!, row);

      expect(row.lastElementChild).toBe(editedCell);
      expect(cancelButtons(row)).toHaveLength(1);
      expect(await within(editedCell).findByRole('button', { name: 'Cancel' })).toBeInTheDocument();
      expect(editedCell).toHaveClass('wp-table--cancel-create-host');
    });
  });
});
