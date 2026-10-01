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

import { fireEvent, waitFor, within } from '@testing-library/dom';
import { HalResourceNotificationService } from 'core-app/features/hal/services/hal-resource-notification.service';
import { buildTable, TableHarness, TableHarnessOptions } from '../../testing/table-harness';

describe('Edit cell entry', () => {
  let harness:TableHarness;

  const renderTable = async (options:Partial<TableHarnessOptions>) => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }], ...options });
    await harness.render();
    harness.click('2');
  };

  const subjectField = (workPackageId:string) => harness.row(workPackageId).querySelector<HTMLElement>('td.subject .inline-edit--display-field')!;

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

    it('opens the editor on Enter', async () => {
      fireEvent.keyDown(subjectField('1'), { key: 'Enter' });

      await waitFor(() => expect(within(harness.row('1')).getByRole('textbox')).toHaveFocus());
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
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

  describe('without an editable subject', () => {
    beforeEach(() => renderTable({}));

    it('does not open an editor', async () => {
      fireEvent.click(subjectField('1'));

      await expect(waitFor(() => within(harness.row('1')).getByRole('textbox'), { timeout: 300 })).rejects.toThrow();
      expect(subjectField('1')).toHaveClass('-read-only');
    });

    it('selects the row when clicking elsewhere in the cell', () => {
      fireEvent.click(harness.row('1').querySelector('td.subject')!);

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
      expect(harness.focus.focusedWorkPackage).toBe('1');
    });
  });
});
