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
import { activeFieldClassName } from 'core-app/shared/components/fields/edit/edit-form/edit-form';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { readOnlyClassName } from 'core-app/shared/components/fields/display/display-field-renderer';
import { buildTable, TableHarness, TableHarnessOptions } from '../../testing/table-harness';
import { activateTableField } from './edit-cell-handler';

describe('Edit cell entry', () => {
  let harness:TableHarness;

  const renderTable = async (options:Partial<TableHarnessOptions>) => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], ...options });
    await harness.render();
    harness.click('2');
  };

  const subjectField = (workPackageId:string) => harness.row(workPackageId).querySelector<HTMLElement>(':scope > .wp-table--cell-td.subject .inline-edit--display-field')!;

  const controlNestedInOpenEditor = async (workPackageId:string) => {
    fireEvent.click(subjectField(workPackageId));
    const textbox = await within(harness.row(workPackageId)).findByRole('textbox');
    const host = document.createElement('div');
    host.classList.add(activeFieldClassName);
    const nested = document.createElement('button');
    host.append(nested);
    textbox.closest('td, th')!.append(host);
    return nested;
  };

  afterEach(() => harness.destroy());

  describe('with an editable subject', () => {
    beforeEach(() => renderTable({ editing: {} }));

    it('opens the editor in the clicked cell and leaves selection and the current work package alone', async () => {
      fireEvent.click(subjectField('1'));

      await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
      expect(within(harness.row('2')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(harness.focus.focusedWorkPackage).toBe('2');
    });

    it('abandons an activation when the table is torn down mid-load', async () => {
      const field = subjectField('1');

      fireEvent.click(field);
      harness.table.destroy();
      await new Promise((resolve) => { setTimeout(resolve, 50); });

      expect(field).not.toHaveClass(readOnlyClassName);
      expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
    });

    it('opens the editor on Enter', async () => {
      fireEvent.keyDown(subjectField('1'), { key: 'Enter' });

      await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
    });

    it('does not open the work package when double clicking a control nested in the open editor', async () => {
      const itemClicked = vi.fn();
      harness.outputs.itemClicked.subscribe(itemClicked);
      const nested = await controlNestedInOpenEditor('1');

      fireEvent.dblClick(nested);

      expect(itemClicked).not.toHaveBeenCalled();
    });

    it('leaves selection and the current work package alone when clicking a control nested in the open editor', async () => {
      const nested = await controlNestedInOpenEditor('1');

      fireEvent.click(nested);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
      expect(harness.focus.focusedWorkPackage).toBe('2');
    });
  });

  describe('when the user requires a double click', () => {
    beforeEach(() => renderTable({ editing: {}, requireDoubleClickForInlineEdit: true }));

    it('selects the row on a single click instead of opening the editor', async () => {
      fireEvent.click(subjectField('1'));

      await expect(waitFor(() => within(harness.row('1')).getByRole('textbox'), { timeout: 300 })).rejects.toThrow();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
      expect(harness.focus.focusedWorkPackage).toBe('1');
    });

    it('opens the editor on a double click without opening the work package', async () => {
      const itemClicked = vi.fn();
      harness.outputs.itemClicked.subscribe(itemClicked);

      fireEvent.dblClick(subjectField('1'));

      await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
      expect(itemClicked).not.toHaveBeenCalled();
    });

    it('opens the editor on Enter', async () => {
      fireEvent.keyDown(subjectField('1'), { key: 'Enter' });

      await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
    });
  });

  describe('when the loaded form refuses the field', () => {
    beforeEach(() => renderTable({ editing: { formWritable: false } }));

    it('marks the field read-only and reports the blocked edit instead of opening an editor', async () => {
      const blocked = vi.spyOn(harness.injector.get(HalResourceNotificationService), 'showEditingBlockedError');

      fireEvent.click(subjectField('1'));

      await waitFor(() => expect(subjectField('1')).toHaveClass('-read-only'));
      expect(blocked).toHaveBeenCalledWith('subject');
      expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
    });
  });

  describe('when inline edit is disabled', () => {
    beforeEach(() => renderTable({ editing: {}, configuration: { inlineEditEnabled: false } }));

    it('refuses to open an editor through cell activation', () => {
      expect(activateTableField(harness.table, subjectField('1'))).toBe(false);

      expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(harness.table.editing.forms).toEqual({});
    });

    it('does not open an editor or mark the field', () => {
      fireEvent.click(subjectField('1'));

      expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(subjectField('1')).not.toHaveClass('-editable');
      expect(subjectField('1')).not.toHaveClass('-read-only');
      expect(harness.table.editing.forms).toEqual({});
    });

    it.each(['Enter', 'F2'])('does not open an editor with %s in a focused cell', (key) => {
      const cell = subjectField('1').closest<HTMLTableCellElement>('td, th')!;
      const navigation = harness.table.keyboardNavigation;
      navigation.focusPosition(navigation.positionOfCell(cell)!);

      fireEvent.keyDown(cell, { key });

      expect(within(harness.row('1')).queryByRole('textbox')).not.toBeInTheDocument();
      expect(cell).toHaveFocus();
      expect(subjectField('1')).not.toHaveClass('-read-only');
      expect(harness.table.editing.forms).toEqual({});
    });

    it('selects the row when clicking the field text', () => {
      fireEvent.click(subjectField('1'));

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    });

    it('opens the row when double clicking the field text', () => {
      const itemClicked = vi.fn();
      harness.outputs.itemClicked.subscribe(itemClicked);

      fireEvent.dblClick(subjectField('1'));

      expect(itemClicked).toHaveBeenCalledWith({ workPackageId: '1', double: true });
    });

    it('keeps row navigation and keyboard selection available', () => {
      const cell = subjectField('1').closest<HTMLTableCellElement>('td, th')!;
      const navigation = harness.table.keyboardNavigation;
      navigation.focusPosition(navigation.positionOfCell(cell)!);

      fireEvent.keyDown(cell, { key: 'ArrowLeft' });
      fireEvent.keyDown(document.activeElement!, { key: 'ArrowLeft' });
      expect(harness.row('1')).toHaveFocus();
      fireEvent.keyDown(harness.row('1'), { key: ' ', code: 'Space', shiftKey: true });
      expect(harness.selection.getSelectedWorkPackageIds()).toContain('1');
      fireEvent.keyDown(harness.row('1'), { key: 'ArrowDown' });
      expect(harness.row('2')).toHaveFocus();
      expect(harness.table.editing.forms).toEqual({});
    });
  });

  describe('without an editable subject', () => {
    beforeEach(() => renderTable({}));

    it('does not open an editor', async () => {
      fireEvent.click(subjectField('1'));

      await expect(waitFor(() => within(harness.row('1')).getByRole('textbox'), { timeout: 300 })).rejects.toThrow();
      expect(subjectField('1')).toHaveClass('-read-only');
    });

    it('selects the row when clicking elsewhere in the cell', () => {
      fireEvent.click(harness.row('1').querySelector(':scope > .wp-table--cell-td.subject')!);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
      expect(harness.focus.focusedWorkPackage).toBe('1');
    });
  });
});
