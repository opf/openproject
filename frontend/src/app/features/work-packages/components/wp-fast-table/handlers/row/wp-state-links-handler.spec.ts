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

import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { fireEvent } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { buildTable, TableHarness } from '../../testing/table-harness';
import { UiStateLinkBuilder, uiStateLinkClass } from '../../builders/ui-state-link-builder';
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
    table.table.keyboardNavigation.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
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
    table.table.keyboardNavigation.focusPosition({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
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

describe('WorkPackageStateLinksHandler state routes', () => {
  let table:TableHarness;
  let builder:UiStateLinkBuilder;

  beforeEach(async () => {
    table = buildTable({ workPackages: [{ id: '42' }], productionMarkup: true });
    await table.render();
    builder = new UiStateLinkBuilder(
      table.injector.get(KeepTabService),
      table.injector.get(CurrentProjectService),
      table.injector.get(PathHelperService),
      table.injector.get(UrlParamsService),
    );
  });

  afterEach(async () => {
    await table.destroy();
  });

  it.each(['split', 'show'])('emits the %s route with the numeric work package identity', (state) => {
    const received = vi.fn();
    table.outputs.stateLinkClicked.subscribe(received);
    const { link, element } = state === 'split'
      ? builder.linkToDetails('42', 'Details', 'Open', 'PROJ-7')
      : builder.linkToShow('42', 'Show', 'Open', 'PROJ-7');
    table.row('42').firstElementChild!.appendChild(element);

    expect(fireEvent.click(link)).toBe(false);
    expect(received).toHaveBeenCalledExactlyOnceWith({ workPackageId: '42', requestedState: state });
  });

  it('leaves unsupported dataset states to normal link processing', () => {
    const received = vi.fn();
    table.outputs.stateLinkClicked.subscribe(received);
    const { link, element } = builder.linkToShow('42', 'Show', 'Open');
    table.row('42').firstElementChild!.appendChild(element);
    link.dataset.wpState = 'unsupported';
    link.removeAttribute('href');

    expect(fireEvent.click(link)).toBe(true);
    expect(received).not.toHaveBeenCalled();
  });
});
