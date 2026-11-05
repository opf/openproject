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

import { fireEvent } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';
import { navigableCells } from '../state/keyboard/roving-tabindex';
import { wpOccurrenceKey } from '../../rendered-occurrence-ledger';

describe('WorkPackageStateLinksHandler', () => {
  const harnesses:TableHarness[] = [];

  const stateLink = (workPackageId = '1') => {
    const link = document.createElement('a');
    link.href = '#';
    link.classList.add(uiStateLinkClass);
    link.dataset.wpState = 'show';
    link.dataset.workPackageId = workPackageId;
    return link;
  };

  const mount = async (ids = ['1']) => {
    const table = buildTable({
      workPackages: ids.map((id) => ({ id })),
      productionMarkup: true,
    });
    harnesses.push(table);
    await table.render();
    const cell = navigableCells(table.row('1'))[0];
    const link = stateLink();
    cell.append(link);
    return { table, cell, link };
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('returns a walked state link to its row origin', async () => {
    const { table, link } = await mount();
    const clicked = vi.fn();
    table.outputs.stateLinkClicked.subscribe(clicked);
    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    await userEvent.tab();
    expect(link).toHaveFocus();

    fireEvent.click(link);

    expect(table.row('1')).toHaveFocus();
    expect(document.body).not.toHaveFocus();
    expect(clicked).toHaveBeenCalledWith({ workPackageId: '1', requestedState: 'show' });
  });

  it('returns a link focused outside the walk to its own cell', async () => {
    const { table, link } = await mount(['1', '2']);
    const otherCell = navigableCells(table.row('2'))[0];
    const other = stateLink('2');
    otherCell.append(other);
    table.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    await userEvent.tab();
    expect(link).toHaveFocus();
    other.focus();

    fireEvent.click(other);

    expect(otherCell).toHaveFocus();
  });

  it('returns a pointer-activated state link to its enclosing cell', async () => {
    const { cell, link } = await mount();
    fireEvent.mouseDown(link, { button: 0 });

    fireEvent.click(link);

    expect(cell).toHaveFocus();
    expect(document.body).not.toHaveFocus();
  });

  it('blurs a state link outside any table position', async () => {
    const table = buildTable({ workPackages: [{ id: '1' }], timelineVisible: true });
    harnesses.push(table);
    await table.render();
    const link = stateLink();
    table.timelineRow('1').append(link);
    link.focus();
    expect(link).toHaveFocus();

    fireEvent.click(link);

    expect(link).not.toHaveFocus();
    expect(document.body).toHaveFocus();
  });
});
