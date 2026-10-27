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
import { buildTable, consumerConfiguration, ConsumerName, TableHarness } from '../wp-fast-table/testing/table-harness';
import { WorkPackageTableConfigurationObject } from 'core-app/features/work-packages/components/wp-table/wp-table-configuration';
import { States } from 'core-app/core/states/states.service';
import { HAL_NEW_RESOURCE_ID } from 'core-app/features/hal/helpers/is-new-resource';
import { InlineCreateRowBuilder, inlineCreateCancelClassName } from './inline-create-row-builder';

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
    return table;
  };

  const cancelLinks = (row:HTMLElement) => row.querySelectorAll(`.${inlineCreateCancelClassName}`);

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  describe('without a trailing column', () => {
    it('renders as many cells as the header', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
    });

    it('keeps a single Cancel link in the last rendered cell', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      expect(cancelLinks(row)).toHaveLength(1);
      expect(row.lastElementChild!.querySelector(`.${inlineCreateCancelClassName}`)).toHaveAccessibleName('Cancel');
      expect(row.querySelectorAll('td.wp-table--cancel-create-td')).toHaveLength(0);
    });

    it('renders the Cancel link as a keyboard-operable anchor in the last cell', async () => {
      const table = await mount('macro');

      const row = table.addInlineCreateRow();

      const link = within(row.lastElementChild as HTMLElement).getByRole('link', { name: 'Cancel' });
      expect(link).toHaveClass(inlineCreateCancelClassName);
      expect(link).toHaveAttribute('href', '#');
    });

    it('keeps the cell count and link after refreshRow', async () => {
      const table = await mount('macro');
      const row = table.addInlineCreateRow();
      const builder = new InlineCreateRowBuilder(table.injector, table.table);
      const workPackage = table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!;

      builder.refreshRow(workPackage, row);

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(cancelLinks(row)).toHaveLength(1);
    });
  });

  describe('with a trailing column', () => {
    it('keeps the Cancel link in its own cell', async () => {
      const table = await mount('search', undefined, { inlineCreateEnabled: true });

      const row = table.addInlineCreateRow();

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(row.querySelectorAll('td.wp-table--cancel-create-td')).toHaveLength(1);
      expect(cancelLinks(row)).toHaveLength(1);
    });
  });

  describe('while editing', () => {
    it('keeps the cell count and link while the last column is being edited', async () => {
      const table = await mount('macro', {});
      const row = table.addInlineCreateRow();
      const form = Object.values(table.table.editing.forms)[0];
      const handler = await form.activate('subject');
      handler!.focus();
      const editor = row.querySelector('input.inline-edit--field')!;
      await waitFor(() => expect(editor).toHaveFocus());
      const builder = new InlineCreateRowBuilder(table.injector, table.table);

      builder.refreshRow(table.injector.get(States).workPackages.get(HAL_NEW_RESOURCE_ID).value!, row);

      expect(row.cells).toHaveLength(table.headerRow().cells.length);
      expect(cancelLinks(row)).toHaveLength(1);
      expect(row.contains(editor)).toBe(true);
    });
  });
});
