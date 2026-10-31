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

import '@primer/view-components/app/components/primer/alpha/tool_tip';
import { fireEvent, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { buildTable, TableHarness } from '../../../testing/table-harness';

describe('Read-only table tooltips', () => {
  let harness:TableHarness;

  afterEach(async () => harness.destroy());

  it('keeps native action labels usable without enabling inline editing', async () => {
    harness = buildTable({
      workPackages: [{ id: '1', subject: 'Read-only record' }],
      productionMarkup: true,
      editing: {},
      configuration: { inlineEditEnabled: false, actionsColumnEnabled: true },
      translations: { 'js.label_open_context_menu': 'Open context menu' },
    });
    await harness.render();
    harness.click('1');
    const row = harness.row('1');
    const link = within(row).getByRole('link', { name: 'Open context menu' });
    const tooltip = link.nextElementSibling!;

    expect(link).toHaveAccessibleDescription('');
    expect(link).toHaveAttribute('title', '');
    expect(within(row).getByRole('rowheader', { name: 'Read-only record' })).toHaveAttribute('data-row-header-name', 'Read-only record');
    fireEvent.mouseEnter(link);
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(true));
    fireEvent.mouseLeave(link);
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(false));
    const navigation = harness.table.keyboardNavigation!;
    navigation.focusPosition(navigation.positionOfCell(link.closest('td')!)!);
    await userEvent.tab();
    expect(link).toHaveFocus();
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(true));
    await userEvent.keyboard('{Escape}');
    await waitFor(() => expect(tooltip.matches(':popover-open')).toBe(false));
    expect(link).toHaveFocus();
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);

    const subject = row.querySelector<HTMLElement>(':scope > .wp-table--cell-td.subject .inline-edit--display-field')!;
    const cell = subject.closest<HTMLTableCellElement>('td, th')!;
    navigation.focusPosition(navigation.positionOfCell(cell)!);
    fireEvent.click(subject);
    fireEvent.keyDown(cell, { key: 'Enter' });
    fireEvent.keyDown(cell, { key: 'F2' });
    expect(subject).toHaveClass('-read-only');
    expect(harness.table.editing.forms).toEqual({});
    expect(within(row).queryByRole('textbox')).not.toBeInTheDocument();
  });

  it('keeps the displayed ID as the row-header fallback', async () => {
    harness = buildTable({
      workPackages: [{ id: '1', subject: 'Hidden subject' }],
      columns: ['id'],
      configuration: { inlineEditEnabled: false },
    });
    await harness.render();

    const header = within(harness.row('1')).getByRole('rowheader', { name: '1' });
    expect(header).toHaveAttribute('data-row-header-name', '1');
    expect(header).toHaveAccessibleDescription('');
  });
});
