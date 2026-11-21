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

import { fireEvent, waitFor } from '@testing-library/dom';
import { buildTable, TableHarness, TableHarnessOptions } from 'core-app/features/work-packages/components/wp-fast-table/testing/table-harness';
import { focusWorkPackageTableRowOffset } from './work-package-table-row-navigation';

describe('focusWorkPackageTableRowOffset', () => {
  const harnesses:TableHarness[] = [];
  const outsideButtons:HTMLButtonElement[] = [];

  const outsideButton = () => {
    const button = document.createElement('button');
    outsideButtons.push(button);
    return button;
  };

  const mountTable = async (ids:string[], options:Partial<TableHarnessOptions> = {}) => {
    const table = buildTable({
      workPackages: ids.map((id) => ({ id })),
      productionMarkup: true,
      ...options,
      configuration: { inlineCreateEnabled: true },
    });
    harnesses.push(table);
    table.tbody.closest('table')!.classList.add('keyboard-accessible-list');
    await table.render();
    return table;
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
    outsideButtons.splice(0).forEach((button) => button.remove());
  });

  describe('moving down', () => {
    it('moves within the table that holds focus', async () => {
      await mountTable(['1', '2', '3']);
      const second = await mountTable(['4', '5', '6']);
      second.row('4').focus();

      focusWorkPackageTableRowOffset(1);

      expect(second.row('5')).toHaveFocus();
      expect(second.row('5')).toHaveAttribute('tabindex', '0');
    });

    it('starts at the first row of the first table when nothing holds focus', async () => {
      const first = await mountTable(['1', '2', '3']);
      await mountTable(['4', '5', '6']);
      document.body.focus();

      focusWorkPackageTableRowOffset(1);

      expect(first.row('1')).toHaveFocus();
    });

    it('enters the table that follows focus outside every table', async () => {
      const first = await mountTable(['1', '2', '3']);
      const second = await mountTable(['4', '5', '6']);
      const between = outsideButton();
      first.tbody.closest('table')!.after(between);
      between.focus();

      focusWorkPackageTableRowOffset(1);

      expect(second.row('4')).toHaveFocus();
    });

    it('passes over a hidden table that follows focus', async () => {
      const first = await mountTable(['1', '2', '3']);
      const hidden = await mountTable(['4', '5', '6']);
      const third = await mountTable(['7', '8', '9']);
      hidden.tbody.closest('table')!.style.display = 'none';
      const between = outsideButton();
      first.tbody.closest('table')!.after(between);
      between.focus();

      focusWorkPackageTableRowOffset(1);

      expect(third.row('7')).toHaveFocus();
    });

    it('falls back to the first table when no table follows focus', async () => {
      const first = await mountTable(['1', '2', '3']);
      await mountTable(['4', '5', '6']);
      const after = outsideButton();
      document.body.append(after);
      after.focus();

      focusWorkPackageTableRowOffset(1);

      expect(first.row('1')).toHaveFocus();
    });

    it('stays on the last work package row instead of entering the create row', async () => {
      const first = await mountTable(['1', '2', '3']);
      const createRow = first.tbody.closest('table')!.querySelector<HTMLElement>('tbody[wpInlineCreate] > tr')!;
      createRow.setAttribute('tabindex', '-1');
      expect(createRow).toBeVisible();
      first.row('3').focus();

      focusWorkPackageTableRowOffset(1);

      expect(first.row('3')).toHaveFocus();
    });
  });

  describe('from the totals row', () => {
    it('moves up to the last work package row and stays on the totals row going down', async () => {
      const table = await mountTable(['1', '2', '3']);
      const totalsCell = table.totalsRow().cells[0];
      totalsCell.tabIndex = -1;

      totalsCell.focus();
      focusWorkPackageTableRowOffset(-1);
      expect(table.row('3')).toHaveFocus();

      totalsCell.focus();
      focusWorkPackageTableRowOffset(1);
      expect(totalsCell).toHaveFocus();
    });
  });

  describe('in a grouped table', () => {
    const groupedOptions:Partial<TableHarnessOptions> = {
      workPackages: [
        { id: '1', attributes: { status: { href: '/api/v3/statuses/1' } } },
        { id: '2', attributes: { status: { href: '/api/v3/statuses/2' } } },
      ],
      groups: [
        { value: 'One', href: '/api/v3/statuses/1', count: 1 },
        { value: 'Two', href: '/api/v3/statuses/2', count: 1 },
      ],
    };

    it('skips the sums row that ends a group', async () => {
      const table = await mountTable([], {
        ...groupedOptions,
        groups: [
          { value: 'One', href: '/api/v3/statuses/1', count: 1, sums: { storyPoints: 13 } },
          { value: 'Two', href: '/api/v3/statuses/2', count: 1, sums: { storyPoints: 21 } },
        ],
      });
      const sumsRow = table.row('1').nextElementSibling as HTMLElement;
      expect(sumsRow).toHaveClass('wp-table--sums-row');
      expect(sumsRow).toBeVisible();
      table.row('1').focus();

      focusWorkPackageTableRowOffset(1);

      expect(table.groupHeader(1)).toHaveFocus();
    });

    it('moves on from a focused sums row in both directions', async () => {
      const table = await mountTable([], {
        ...groupedOptions,
        groups: [
          { value: 'One', href: '/api/v3/statuses/1', count: 1, sums: { storyPoints: 13 } },
          { value: 'Two', href: '/api/v3/statuses/2', count: 1, sums: { storyPoints: 21 } },
        ],
      });
      const sumsCell = (table.row('1').nextElementSibling as HTMLTableRowElement).cells[0];
      sumsCell.tabIndex = -1;

      sumsCell.focus();
      focusWorkPackageTableRowOffset(1);
      expect(table.groupHeader(1)).toHaveFocus();

      sumsCell.focus();
      focusWorkPackageTableRowOffset(-1);
      expect(table.row('1')).toHaveFocus();
    });

    it('walks from a group header to the next group header, skipping the rows of a collapsed group', async () => {
      const table = await mountTable([], groupedOptions);
      table.groupHeader(0).focus();
      fireEvent.keyDown(document.activeElement!, { key: 'ArrowLeft' });
      await waitFor(() => expect(table.row('1')).not.toBeVisible());

      focusWorkPackageTableRowOffset(1);

      expect(table.groupHeader(1)).toHaveFocus();

      focusWorkPackageTableRowOffset(-1);

      expect(table.groupHeader(0)).toHaveFocus();
    });
  });

  describe('moving up', () => {
    it('moves up within the table that holds focus', async () => {
      await mountTable(['1', '2', '3']);
      const second = await mountTable(['4', '5', '6']);
      second.row('6').focus();

      focusWorkPackageTableRowOffset(-1);

      expect(second.row('5')).toHaveFocus();
    });

    it('enters the table that precedes focus outside every table at its last row', async () => {
      const first = await mountTable(['1', '2', '3']);
      await mountTable(['4', '5', '6']);
      const between = outsideButton();
      first.tbody.closest('table')!.after(between);
      between.focus();

      focusWorkPackageTableRowOffset(-1);

      expect(first.row('3')).toHaveFocus();
    });

    it('enters the last row of the nearest table above focus after every table', async () => {
      await mountTable(['1', '2', '3']);
      const second = await mountTable(['4', '5', '6']);
      const after = outsideButton();
      document.body.append(after);
      after.focus();

      focusWorkPackageTableRowOffset(-1);

      expect(second.row('6')).toHaveFocus();
    });
  });
});
