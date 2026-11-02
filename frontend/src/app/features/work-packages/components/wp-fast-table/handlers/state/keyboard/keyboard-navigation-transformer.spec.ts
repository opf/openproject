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
import { userEvent } from 'vitest/browser';
import { usePlatform } from 'core-common/testing/platform';
import { States } from 'core-app/core/states/states.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { OpContextMenuHandler } from 'core-app/shared/components/op-context-menu/op-context-menu-handler';
import { buildQuery, buildTable, TableHarness, TableHarnessOptions } from '../../../testing/table-harness';
import { buildGroup } from '../../../testing/work-package-fixture';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import { KeyboardNavigation } from './keyboard-navigation-transformer';
import { headerRowKey, totalsRowKey } from './navigable-rows';
import { expansionStateOf } from '../../../helpers/row-expansion';
import { insideGrid, navigableCells } from './roving-tabindex';

class AnchorDisplayField extends TextDisplayField {
  public render(element:HTMLElement, displayText:string):void {
    const link = document.createElement('a');
    link.href = '#';
    link.textContent = displayText;
    element.appendChild(link);
  }
}

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

const grouped:Partial<TableHarnessOptions> = {
  workPackages: [
    { id: '1', attributes: { status: newStatus } },
    { id: '2', attributes: { status: newStatus } },
    { id: '3', attributes: { status: inProgressStatus } },
  ],
  groups: [
    { value: 'New', href: newStatus.href, count: 2 },
    { value: 'In progress', href: inProgressStatus.href, count: 1 },
  ],
};

describe('KeyboardNavigationTransformer', () => {
  usePlatform();
  const harnesses:TableHarness[] = [];

  const mount = async (options:Partial<TableHarnessOptions> = {}, beforeRender?:(table:TableHarness) => void) => {
    const table = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      productionMarkup: true,
      ...options,
      configuration: { keyboardNavigationEnabled: true, ...options.configuration },
    });
    harnesses.push(table);
    beforeRender?.(table);
    await table.render();
    return table;
  };

  const press = (element:Element, key:string, init:KeyboardEventInit = {}) => fireEvent.keyDown(element, { key, ...init });

  const pressActive = (key:string, init:KeyboardEventInit = {}) => press(document.activeElement!, key, init);

  const navigation = (table:TableHarness):KeyboardNavigation => table.table.keyboardNavigation!;

  const resource = (table:TableHarness, id:string) => table.injector.get(States).workPackages.get(id).value!;

  const cell = (row:HTMLTableRowElement, index:number) => navigableCells(row)[index];

  const selectedIds = (table:TableHarness) => table.selection.getSelectedWorkPackageIds().sort();

  const focusFromOutside = (element:HTMLElement) => {
    const outside = document.createElement('button');
    document.body.append(outside);
    try {
      outside.focus();
      element.focus();
    } finally {
      outside.remove();
    }
  };

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
  });

  it('Tab from a control before the table lands on the first work package row', async () => {
    const table = await mount();
    const before = document.createElement('button');
    before.textContent = 'Before';
    table.table.tableAndTimelineContainer.before(before);
    try {
      before.focus();

      await userEvent.tab();

      expect(table.row('1')).toHaveFocus();
      expect(table.row('1')).toHaveAttribute('tabindex', '0');
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    } finally {
      before.remove();
    }
  });

  it('Tab from a row leaves the grid even when a late control is tabbable', async () => {
    const table = await mount();
    const late = document.createElement('span');
    late.setAttribute('tabindex', '0');
    table.row('1').querySelector('td.subject')!.appendChild(late);
    table.row('1').focus();

    await userEvent.tab();

    expect(late).not.toHaveFocus();
    expect(insideGrid(table.table.scrollContainer, document.activeElement)).toBe(false);
  });

  it('Shift+Tab from a row sweeps late controls too', async () => {
    const table = await mount();
    const late = document.createElement('span');
    late.setAttribute('tabindex', '0');
    table.row('2').querySelector('td.subject')!.appendChild(late);
    table.row('2').focus();

    await userEvent.tab({ shift: true });

    expect(late).toHaveAttribute('tabindex', '-1');
    expect(late).not.toHaveFocus();
  });

  it('a refresh while the inline-create button has focus leaves it there', async () => {
    const table = await mount();
    table.row('1').focus();
    const button = within(table.container).getByRole('button', { name: 'Create new work package' });
    button.focus();

    table.table.refreshRows(resource(table, '2'));

    await waitFor(() => expect(button).toHaveFocus());
  });

  it('takes the scroll container and its wrapper out of the Tab order only when enabled', async () => {
    const enabled = await mount();
    expect(enabled.table.scrollContainer).toHaveAttribute('tabindex', '-1');
    expect(enabled.table.tableAndTimelineContainer).toHaveAttribute('tabindex', '-1');

    const disabled = await mount({ configuration: { keyboardNavigationEnabled: false } });
    expect(disabled.table.scrollContainer).not.toHaveAttribute('tabindex');
    expect(disabled.table.tableAndTimelineContainer).not.toHaveAttribute('tabindex');
  });

  it('ArrowDown/ArrowUp walk visible rows and reach the header and totals rows', async () => {
    const table = await mount();
    table.row('1').focus();

    expect(pressActive('ArrowUp')).toBe(false);
    expect(table.headerRow()).toHaveFocus();
    expect(table.headerRow()).toHaveAttribute('tabindex', '0');

    pressActive('ArrowDown');
    pressActive('ArrowDown');
    expect(table.row('2')).toHaveFocus();
    expect(table.row('1')).toHaveAttribute('tabindex', '-1');

    pressActive('ArrowDown');
    pressActive('ArrowDown');
    expect(table.totalsRow()).toHaveFocus();
  });

  it('ArrowRight enters the first cell, ArrowLeft on it returns to the row', async () => {
    const table = await mount();
    table.row('1').focus();

    pressActive('ArrowRight');
    expect(cell(table.row('1'), 0)).toHaveFocus();
    expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: 0, desiredColumn: 0 });

    pressActive('ArrowLeft');
    expect(table.row('1')).toHaveFocus();
  });

  it('ArrowUp from a cell keeps the column across a one-cell group header', async () => {
    const table = await mount(grouped);
    cell(table.row('3'), 1).focus();

    pressActive('ArrowUp');
    expect(cell(table.groupHeader(1), 0)).toHaveFocus();

    pressActive('ArrowUp');
    expect(cell(table.row('2'), 1)).toHaveFocus();
  });

  it('ArrowRight on a collapsed hierarchy parent expands it without moving focus', async () => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
    });
    const hierarchies = table.injector.get(WorkPackageViewHierarchiesService);
    hierarchies.collapse('1');
    await waitFor(() => expect(table.row('2')).not.toBeVisible());
    table.row('1').focus();

    expect(pressActive('ArrowRight')).toBe(false);

    expect(hierarchies.collapsed('1')).toBe(false);
    await waitFor(() => expect(table.row('2')).toBeVisible());
    expect(table.row('1')).toHaveFocus();
  });

  it('reports no expansion for a hierarchy parent without a rendered indicator', async () => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      columns: ['id'],
      showHierarchies: true,
    });
    const hierarchies = table.injector.get(WorkPackageViewHierarchiesService);
    const occurrence = table.table.ledger.byKey(wpOccurrenceKey('1'))!;
    hierarchies.collapse('1');
    table.row('1').focus();

    expect(expansionStateOf(table.table, hierarchies, occurrence, 'workPackage')).toBeNull();
    expect(pressActive('ArrowRight')).toBe(false);
    expect(hierarchies.collapsed('1')).toBe(true);
    expect(cell(table.row('1'), 0)).toHaveFocus();
    expect(pressActive('ArrowLeft')).toBe(false);
    expect(table.row('1')).toHaveFocus();
    expect(hierarchies.collapsed('1')).toBe(true);
  });

  it('ArrowLeft on an expanded group header collapses it', async () => {
    const table = await mount(grouped);
    const collapsedGroups = table.injector.get(WorkPackageViewCollapsedGroupsService);
    const identifier = table.groupHeader(0).dataset.groupIdentifier!;
    table.groupHeader(0).focus();

    expect(pressActive('ArrowLeft')).toBe(false);

    expect(collapsedGroups.config.state[identifier]).toBe(true);
    await waitFor(() => expect(table.row('1')).not.toBeVisible());
    expect(table.groupHeader(0)).toHaveFocus();
  });

  it('Enter on a work package row replaces the selection with that row and anchors it', async () => {
    const table = await mount();
    const clicked:string[] = [];
    table.outputs.itemClicked.subscribe(({ workPackageId }) => clicked.push(workPackageId));
    table.click('1');
    table.click('3', { ctrlKey: true });
    table.row('2').focus();

    expect(pressActive('Enter')).toBe(false);

    expect(selectedIds(table)).toEqual(['2']);
    expect(table.focus.focusedWorkPackage).toBe('2');
    expect(clicked).toEqual(['1', '2']);
    table.click('3', { shiftKey: true });
    expect(selectedIds(table)).toEqual(['2', '3']);
  });

  it('Enter on a group header toggles its collapse', async () => {
    const table = await mount(grouped);
    const collapsedGroups = table.injector.get(WorkPackageViewCollapsedGroupsService);
    const identifier = table.groupHeader(0).dataset.groupIdentifier!;
    table.groupHeader(0).focus();

    expect(pressActive('Enter')).toBe(false);

    expect(collapsedGroups.config.state[identifier]).toBe(true);
    expect(selectedIds(table)).toEqual([]);
  });

  it('Enter on a header cell clicks its sort link; on the configuration cell clicks the button', async () => {
    const table = await mount();
    const [idHeader, , configurationHeader] = table.headerCells();
    const linkClicked = vi.fn((event:Event) => event.preventDefault());
    const buttonClicked = vi.fn();
    idHeader.querySelector('a')!.addEventListener('click', linkClicked);
    configurationHeader.querySelector('button')!.addEventListener('click', buttonClicked);

    idHeader.focus();
    expect(pressActive('Enter')).toBe(false);
    configurationHeader.focus();
    expect(pressActive('Enter')).toBe(false);

    expect(linkClicked).toHaveBeenCalledOnce();
    expect(buttonClicked).toHaveBeenCalledOnce();
  });

  it('Enter on a non-sortable column header clicks its link without an href', async () => {
    const table = await mount({ columns: ['id', { id: 'subject', sortable: false }] });
    const [, subjectHeader] = table.headerCells();
    const link = subjectHeader.querySelector('a')!;
    expect(link).not.toHaveAttribute('href');
    const clicked = vi.fn();
    link.addEventListener('click', clicked);

    subjectHeader.focus();
    expect(pressActive('Enter')).toBe(false);

    expect(clicked).toHaveBeenCalledOnce();
  });

  it('Enter on an editable cell opens its inline editor', async () => {
    const table = await mount({ editing: {} });
    const subjectCell = table.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    subjectCell.focus();

    expect(pressActive('Enter')).toBe(false);

    await waitFor(() => expect(within(table.row('1')).getByRole('textbox')).toHaveFocus());
    expect(selectedIds(table)).toEqual([]);
  });

  it('Enter on a read-only cell does nothing', async () => {
    const table = await mount({ editing: {} });
    const idCell = table.row('1').querySelector<HTMLTableCellElement>('td.id')!;
    idCell.focus();

    expect(pressActive('Enter')).toBe(true);

    expect(within(table.row('1')).queryByRole('textbox')).toBeNull();
    expect(table.table.editing.forms['1']).toBeUndefined();
    expect(idCell).toHaveFocus();
    expect(selectedIds(table)).toEqual([]);
  });

  it.each([
    ['Alt', 'ArrowDown', { altKey: true }],
    ['composition', 'ArrowDown', { isComposing: true }],
    ['Ctrl', 'ArrowDown', { ctrlKey: true }],
    ['Shift', 'PageDown', { shiftKey: true }],
    ['Shift', 'End', { shiftKey: true }],
  ])('keys with %s (%s) are not handled', async (_name, key, init) => {
    const table = await mount();
    table.row('2').focus();

    expect(pressActive(key, init)).toBe(true);

    expect(table.row('2')).toHaveFocus();
    expect(navigation(table).position?.key).toBe(wpOccurrenceKey('2'));
  });

  it('Shift+Enter on a work package row changes no selection', async () => {
    const table = await mount();
    table.click('1');
    table.row('2').focus();

    expect(pressActive('Enter', { shiftKey: true })).toBe(true);

    expect(selectedIds(table)).toEqual(['1']);
    expect(table.focus.focusedWorkPackage).toBe('1');
  });

  it('keys from inside an inner control are not handled', async () => {
    const table = await mount({}, (harness) => {
      harness.injector.get(DisplayFieldService).addFieldType(AnchorDisplayField, 'text', ['String']);
    });
    const subjectCell = table.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
    subjectCell.focus();
    const link = within(subjectCell).getByRole('link');

    expect(press(link, 'ArrowDown')).toBe(true);
    expect(press(link, 'Enter')).toBe(true);

    expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: 1, desiredColumn: 1 });
    expect(subjectCell).toHaveFocus();
  });

  it('focus landing on a header sort link or a body inner control moves to its enclosing cell', async () => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
      columns: ['id', 'subject'],
    });
    const subjectHeader = table.headerCells()[1];

    focusFromOutside(within(subjectHeader).getByRole('link'));

    expect(subjectHeader).toHaveFocus();
    expect(subjectHeader).toHaveAttribute('tabindex', '0');
    expect(navigation(table).position).toEqual({ key: headerRowKey, cell: 1, desiredColumn: 1 });

    const toggle = table.row('1').querySelector<HTMLElement>('.wp-table--hierarchy-indicator')!;
    const toggleCell = toggle.closest('td')!;
    focusFromOutside(toggle);

    expect(toggleCell).toHaveFocus();
    expect(navigation(table).position).toEqual({
      key: wpOccurrenceKey('1'),
      cell: navigableCells(table.row('1')).indexOf(toggleCell),
      desiredColumn: navigableCells(table.row('1')).indexOf(toggleCell),
    });
  });

  it('focus moving onto an inner control from inside the table stays there', async () => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
    });
    const toggle = table.row('1').querySelector<HTMLElement>('.wp-table--hierarchy-indicator')!;
    cell(table.row('2'), 0).focus();
    const position = navigation(table).position;

    toggle.focus();

    expect(toggle).toHaveFocus();
    expect(navigation(table).position).toEqual(position);
  });

  it('focus from a pointer press on an inner control stays there until the press ends', async () => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
    });
    const toggle = table.row('1').querySelector<HTMLElement>('.wp-table--hierarchy-indicator')!;
    const toggleCell = toggle.closest('td')!;
    toggle.addEventListener('click', (event) => event.preventDefault());

    expect(fireEvent.mouseDown(toggle, { button: 0 })).toBe(true);
    toggle.focus();
    expect(toggle).toHaveFocus();

    fireEvent.mouseUp(toggle, { button: 0 });
    fireEvent.click(toggle);
    focusFromOutside(toggle);

    expect(toggleCell).toHaveFocus();
    expect(navigation(table).position).toEqual({
      key: wpOccurrenceKey('1'),
      cell: navigableCells(table.row('1')).indexOf(toggleCell),
      desiredColumn: navigableCells(table.row('1')).indexOf(toggleCell),
    });
  });

  it.each(['pointerUp', 'pointerCancel', 'dragEnd'] as const)('a pointer press ended by %s no longer holds back the redirect', async (end) => {
    const table = await mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
      showHierarchies: true,
    });
    const toggle = table.row('1').querySelector<HTMLElement>('.wp-table--hierarchy-indicator')!;

    fireEvent.mouseDown(toggle, { button: 0 });
    fireEvent[end](toggle);
    toggle.focus();

    expect(toggle.closest('td')).toHaveFocus();
  });

  it('focus inside an open inline editor stays where the editor puts it', async () => {
    const table = await mount({ editing: {} });
    table.row('1').querySelector<HTMLTableCellElement>('td.subject')!.focus();
    pressActive('Enter');
    const input = await waitFor(() => within(table.row('1')).getByRole('textbox'));
    const editorControl = document.createElement('span');
    editorControl.tabIndex = -1;
    input.after(editorControl);

    input.focus();
    expect(input).toHaveFocus();

    editorControl.focus();
    expect(editorControl).toHaveFocus();
  });

  it('focus movement never changes selection, anchor or the focus service', async () => {
    const table = await mount();
    table.click('2');
    table.row('1').focus();

    ['ArrowDown', 'ArrowDown', 'ArrowRight', 'ArrowUp', 'Home', 'End', 'ArrowLeft'].forEach((key) => pressActive(key));
    pressActive('Home', { ctrlKey: true });
    pressActive('End', { metaKey: true });

    expect(navigableCells(table.totalsRow()).at(-1)).toHaveFocus();
    expect(selectedIds(table)).toEqual(['2']);
    expect(table.focus.focusedWorkPackage).toBe('2');
    table.click('3', { shiftKey: true });
    expect(selectedIds(table)).toEqual(['2', '3']);
  });

  it('flag off: no keydown handling', async () => {
    const table = await mount({ configuration: { keyboardNavigationEnabled: false } });
    table.row('1').focus();

    expect(press(table.row('1'), 'ArrowDown')).toBe(true);

    expect(table.table.keyboardNavigation).toBeNull();
    expect(table.row('1')).toHaveFocus();
  });

  it('returnFocus ignores a vanished origin and focus that left the table', async () => {
    const table = await mount();
    const origin = { key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 };
    const outside = document.createElement('button');
    document.body.append(outside);
    try {
      cell(table.row('1'), 0).focus();
      outside.focus();
      outside.blur();

      navigation(table).returnFocus(origin);

      expect(document.body).toHaveFocus();
      outside.focus();
      navigation(table).returnFocus(origin);
      expect(outside).toHaveFocus();
      outside.remove();
      cell(table.row('1'), 0).focus();
      cell(table.row('1'), 0).blur();
      navigation(table).returnFocus({ key: wpOccurrenceKey('99'), cell: 1, desiredColumn: 1 });
      expect(cell(table.row('1'), 0)).toHaveFocus();
      navigation(table).returnFocus(origin);
      expect(cell(table.row('1'), 0)).toHaveFocus();
      cell(table.row('1'), 0).blur();
      navigation(table).returnFocus(origin);
      expect(cell(table.row('2'), 1)).toHaveFocus();
    } finally {
      outside.remove();
    }
  });

  it('returnFocus leaves focus alone after it left the grid for the inline-create button', async () => {
    const table = await mount();
    const button = within(table.container).getByRole('button', { name: 'Create new work package' });
    button.focus();
    button.remove();

    navigation(table).returnFocus({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });

    expect(document.body).toHaveFocus();
  });

  it('returnFocus leaves focus in another open editor of the table', async () => {
    const table = await mount({ editing: {} });
    table.row('2').querySelector<HTMLTableCellElement>('td.subject')!.focus();
    pressActive('Enter');
    const input = await waitFor(() => within(table.row('2')).getByRole('textbox'));
    await waitFor(() => expect(input).toHaveFocus());

    navigation(table).returnFocus({ key: wpOccurrenceKey('1'), cell: 1, desiredColumn: 1 });

    expect(input).toHaveFocus();
  });

  describe('returnFocusFromMenu', () => {
    const origin = { key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 };

    const visitMenu = (table:TableHarness) => {
      const menuItem = document.createElement('button');
      document.body.append(menuItem);
      cell(table.row('2'), 1).focus();
      menuItem.focus();
      return menuItem;
    };

    it('focuses the origin again after focus visited the menu portal', async () => {
      const table = await mount();
      visitMenu(table).remove();

      navigation(table).returnFocus(origin);
      expect(document.body).toHaveFocus();

      navigation(table).returnFocusFromMenu(origin);
      expect(cell(table.row('2'), 1)).toHaveFocus();
    });

    it('restores the origin after a full render the menu action started', async () => {
      const table = await mount();
      const menuItem = visitMenu(table);
      const rendered = table.nextRender();
      table.table.redrawTable();
      menuItem.remove();

      navigation(table).returnFocusFromMenu(origin);
      await rendered;

      expect(cell(table.row('2'), 1)).toHaveFocus();
    });

    it('leaves focus on a control outside the table', async () => {
      const table = await mount();
      const menuItem = visitMenu(table);
      const input = document.createElement('input');
      document.body.append(input);
      try {
        menuItem.remove();
        input.focus();

        navigation(table).returnFocusFromMenu(origin);

        expect(input).toHaveFocus();
      } finally {
        input.remove();
      }
    });

    it('keeps focus outside the table for later returns when the user moved elsewhere meanwhile', async () => {
      const table = await mount();
      visitMenu(table).remove();
      const moved = { key: wpOccurrenceKey('3'), cell: 1, desiredColumn: 1 };
      navigation(table).recordPosition(moved);

      navigation(table).returnFocusFromMenu(origin);
      navigation(table).returnFocus(moved);

      expect(document.body).toHaveFocus();
    });

    it('does nothing after the table is destroyed', async () => {
      const table = await mount();
      const keyboardNavigation = navigation(table);
      visitMenu(table).remove();
      await table.destroy();

      expect(() => keyboardNavigation.returnFocusFromMenu(origin)).not.toThrow();
      expect(document.body).toHaveFocus();
    });
  });

  it('consumes Home on the first cell without moving', async () => {
    const table = await mount();
    cell(table.row('1'), 0).focus();

    expect(pressActive('Home')).toBe(false);

    expect(cell(table.row('1'), 0)).toHaveFocus();
    expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: 0, desiredColumn: 0 });
  });

  it('two tables on one page do not share positions', async () => {
    const states = new States();
    const first = await mount({ states });
    const second = await mount({ states });
    first.row('1').focus();

    pressActive('ArrowDown');

    expect(first.row('2')).toHaveFocus();
    expect(navigation(first).position?.key).toBe(wpOccurrenceKey('2'));
    expect(navigation(second).position).toBeNull();
    expect(second.row('1')).toHaveAttribute('tabindex', '0');
    expect(second.row('2')).toHaveAttribute('tabindex', '-1');
  });

  describe('pointer bookkeeping', () => {
    const cellIndex = (row:HTMLTableRowElement, selector:string) => navigableCells(row).indexOf(row.querySelector<HTMLTableCellElement>(selector)!);

    it('mousedown on a cell records that row and cell without moving DOM focus', async () => {
      const table = await mount();
      const subject = table.row('2').querySelector<HTMLTableCellElement>('td.subject')!;

      fireEvent.mouseDown(subject, { button: 0 });

      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
      expect(document.body).toHaveFocus();
      expect(cell(table.row('2'), 1)).toHaveAttribute('tabindex', '0');
      expect(table.row('1')).toHaveAttribute('tabindex', '-1');
    });

    it('mousedown on the row outside navigable cells records row focus', async () => {
      const table = await mount();

      fireEvent.mouseDown(table.row('3'), { button: 0 });

      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('3'), cell: null, desiredColumn: null });
      expect(document.body).toHaveFocus();
      expect(table.row('3')).toHaveAttribute('tabindex', '0');
    });

    it('mousedown on the ID link, hierarchy toggle, relation indicator and group header records the position', async () => {
      const table = await mount({
        workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }],
        showHierarchies: true,
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        editing: { fields: ['id', 'subject'] },
      }, (harness) => {
        harness.injector.get(DisplayFieldService).addFieldType(AnchorDisplayField, 'text', ['String']);
      });
      const hierarchies = table.injector.get(WorkPackageViewHierarchiesService);
      const idCell = table.row('1').querySelector<HTMLTableCellElement>('td.id')!;
      const link = within(idCell).getByRole('link');
      const toggle = table.row('1').querySelector<HTMLElement>('.wp-table--hierarchy-indicator')!;
      const relation = table.row('1').querySelector<HTMLElement>('td.relationsOfTypeFollows *')!;

      expect(fireEvent.mouseDown(link, { button: 0 })).toBe(true);
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: cellIndex(table.row('1'), 'td.id'), desiredColumn: cellIndex(table.row('1'), 'td.id') });

      navigation(table).recordPosition({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
      const collapsedBefore = hierarchies.collapsed('1');
      fireEvent.mouseDown(toggle, { button: 0 });
      expect(navigation(table).position?.key).toBe(wpOccurrenceKey('1'));
      fireEvent.click(toggle);
      expect(hierarchies.collapsed('1')).toBe(!collapsedBefore);

      navigation(table).recordPosition({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
      fireEvent.mouseDown(relation, { button: 0 });
      expect(navigation(table).position).toEqual({
        key: wpOccurrenceKey('1'),
        cell: cellIndex(table.row('1'), 'td.relationsOfTypeFollows'),
        desiredColumn: cellIndex(table.row('1'), 'td.relationsOfTypeFollows'),
      });
    });

    it('closing the context menu opened by right-click on a display field returns focus to its cell', async () => {
      const table = await mount({ configuration: { contextMenuEnabled: true } });
      vi.spyOn(table.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions').mockReturnValue([]);
      let menu:OpContextMenuHandler|undefined;
      vi.spyOn(table.injector.get(OPContextMenuService), 'show').mockImplementation((handler) => { menu = handler; });
      const subjectCell = table.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
      const field = subjectCell.querySelector<HTMLElement>('.inline-edit--display-field')!;

      fireEvent.mouseDown(field, { button: 2 });
      fireEvent.contextMenu(field);
      menu!.onClose(true);

      expect(subjectCell).toHaveFocus();
    });

    it('mousedown on a group header records the group position', async () => {
      const table = await mount(grouped);
      const header = table.groupHeader(1);

      fireEvent.mouseDown(header.querySelector('td, th') ?? header, { button: 0 });

      expect(navigation(table).position).toMatchObject({
        key: table.table.ledger.byElement(header)!.key,
        groupIdentifier: header.dataset.groupIdentifier,
      });
    });

    it('mousedown on the timeline side or the inline-create row changes nothing', async () => {
      const table = await mount({ timelineVisible: true });
      const before = { key: wpOccurrenceKey('1'), cell: 0, desiredColumn: 0 };
      navigation(table).recordPosition(before);
      const inlineCreate = table.addInlineCreateRow();

      fireEvent.mouseDown(table.timelineRow('2'), { button: 0 });
      fireEvent.mouseDown(inlineCreate.querySelector('td') ?? inlineCreate, { button: 0 });

      expect(navigation(table).position).toEqual(before);
    });
  });

  describe('recovery', () => {
    it('after a full re-render the same occurrence keeps focus', async () => {
      const table = await mount();
      cell(table.row('2'), 1).focus();

      await table.render([{ id: '3' }, { id: '2' }, { id: '1' }]);

      expect(cell(table.row('2'), 1)).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
    });

    it('after a re-render that removed the focused row, the nearest visible row gets focus', async () => {
      const table = await mount();
      table.row('2').focus();

      await table.render([{ id: '1' }, { id: '3' }]);

      expect(table.row('3')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('3'), cell: null, desiredColumn: null });
    });

    it('a re-render while focus is in another table does not steal focus', async () => {
      const states = new States();
      const first = await mount({ states });
      const second = await mount({ states });
      first.row('2').focus();
      second.row('1').focus();

      await first.render();

      expect(second.row('1')).toHaveFocus();
      expect(navigation(first).position?.key).toBe(wpOccurrenceKey('2'));
      expect(first.row('2')).toHaveAttribute('tabindex', '0');
    });

    it('a row refresh re-focuses the replaced cell at the same column', async () => {
      const table = await mount();
      const replaced = cell(table.row('2'), 1);
      replaced.focus();

      table.table.refreshRows(resource(table, '2'));

      expect(replaced).not.toBeInTheDocument();
      expect(cell(table.row('2'), 1)).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
    });

    it('ifShouldFocus wins over the remembered position and becomes it', async () => {
      const table = await mount();
      const focusHelper = vi.spyOn(table.injector.get(FocusHelperService), 'focus');
      cell(table.row('1'), 1).focus();

      table.focus.updateFocus('3', true);
      await table.render();

      expect(table.row('3')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('3'), cell: null, desiredColumn: null });
      expect(focusHelper).not.toHaveBeenCalled();
    });

    it('a group header position survives an earlier group disappearing', async () => {
      const table = await mount(grouped);
      const identifier = table.groupHeader(1).dataset.groupIdentifier;
      table.groupHeader(1).focus();

      table.querySpace.groups.putValue([buildGroup({ value: 'In progress', href: inProgressStatus.href, count: 1 }, 'status', 0)]);
      await table.render([{ id: '3', attributes: { status: inProgressStatus } }]);

      expect(table.groupHeader(0)).toHaveFocus();
      expect(table.groupHeader(0).dataset.groupIdentifier).toBe(identifier);
      expect(navigation(table).position).toMatchObject({ key: table.table.ledger.byElement(table.groupHeader(0))!.key, groupIdentifier: identifier });
    });

    it('a group header position is dropped when groupBy changes', async () => {
      const table = await mount(grouped);
      table.groupHeader(1).focus();
      const bug = { href: '/api/v3/types/1' };
      const task = { href: '/api/v3/types/2' };

      table.querySpace.query.putValue(buildQuery(['id', 'subject'], 'type', false, false));
      table.querySpace.groups.putValue([
        buildGroup({ value: 'Bug', href: bug.href, count: 1 }, 'type', 0),
        buildGroup({ value: 'Task', href: task.href, count: 2 }, 'type', 1),
      ]);
      await table.render([
        { id: '1', attributes: { type: bug } },
        { id: '2', attributes: { type: task } },
        { id: '3', attributes: { type: task } },
      ]);

      expect(table.row('2')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
    });

    it('collapsing the focused row\'s parent moves focus to the parent', async () => {
      const table = await mount({
        workPackages: [
          { id: '1', children: [{ id: '2' }, { id: '3' }] },
          { id: '2', ancestors: [{ id: '1' }] },
          { id: '3', ancestors: [{ id: '1' }] },
          { id: '4' },
        ],
        showHierarchies: true,
      });
      table.row('3').focus();

      table.injector.get(WorkPackageViewHierarchiesService).collapse('1');

      await waitFor(() => expect(table.row('3')).not.toBeVisible());
      expect(table.row('1')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    });

    it('filtering to zero rows moves focus to the header row', async () => {
      const table = await mount();
      cell(table.row('2'), 1).focus();

      await table.render([]);

      expect(table.headerRow()).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: 'header', cell: null, desiredColumn: null });
    });

    it('does not restore after a render when focus left the grid and the outside control went away', async () => {
      const table = await mount();
      const outside = document.createElement('button');
      document.body.append(outside);
      try {
        table.row('1').focus();
        navigation(table).captureOwnership();
        outside.focus();
        outside.remove();

        table.table.refreshRows(resource(table, '1'));

        expect(document.body).toHaveFocus();
        expect(table.row('1')).toHaveAttribute('tabindex', '0');
      } finally {
        outside.remove();
      }
    });

    it('leaves focus on a still-connected inner control when another row refreshes', async () => {
      const table = await mount({}, (harness) => {
        harness.injector.get(DisplayFieldService).addFieldType(AnchorDisplayField, 'text', ['String']);
      });
      const subjectCell = table.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
      const link = within(subjectCell).getByRole('link');
      fireEvent.mouseDown(link, { button: 0 });
      link.focus();

      table.table.refreshRows(resource(table, '2'));

      expect(link).toHaveFocus();
      expect(subjectCell).toHaveAttribute('tabindex', '0');
      fireEvent.mouseUp(link, { button: 0 });
    });

    it('restores to the hiding parent when focus sits on a row a collapse hid without moving focus', async () => {
      const table = await mount({
        workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
        showHierarchies: true,
      });
      cell(table.row('2'), 1).focus();

      table.injector.get(WorkPackageViewHierarchiesService).collapse('1');

      await waitFor(() => expect(table.row('2')).not.toBeVisible());
      expect(table.row('1')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    });

    it('moves focus off a row the ledger hides while it stays focused and visible', async () => {
      const table = await mount();
      table.row('2').focus();

      table.table.setHidden(new Map([[wpOccurrenceKey('2'), true]]));

      expect(table.row('2')).toBeVisible();
      expect(table.row('1')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    });

    it('publishes a render when the collapse hides no stamped rows', async () => {
      const table = await mount(grouped);
      table.rows().forEach((row) => { delete row.dataset.occurrenceKey; });
      const header = table.groupHeader(0);
      header.focus();

      table.table.setGroupsCollapseState({ [header.dataset.groupIdentifier!]: true });

      expect(table.groupHeader(0)).not.toBe(header);
      expect(table.groupHeader(0)).toHaveFocus();
    });

    it('reaches the totals row after the sums row renders late', async () => {
      const table = await mount();
      const totals = table.totalsRow();
      const cells = totals.innerHTML;
      totals.innerHTML = '';
      await table.render();
      cell(table.row('3'), 0).focus();

      totals.innerHTML = cells;
      table.table.notifyRowsRefreshed(totalsRowKey);

      expect(navigableCells(totals).every((totalsCell) => totalsCell.getAttribute('tabindex') === '-1')).toBe(true);
      expect(pressActive('ArrowDown')).toBe(false);
      expect(navigableCells(totals)[0]).toHaveFocus();
    });

    it('keeps focus on the totals row across a sums refresh', async () => {
      const table = await mount();
      const totals = table.totalsRow();
      navigableCells(totals)[1].focus();

      navigation(table).captureOwnership();
      totals.innerHTML = totals.innerHTML.replaceAll(/ tabindex="[^"]*"/g, '');
      table.table.notifyRowsRefreshed(totalsRowKey);

      expect(navigableCells(totals)[1]).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: totalsRowKey, cell: 1, desiredColumn: 1 });
    });

    it('keeps ownership captured during a pending render when a second capture sees body', async () => {
      const table = await mount();
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
        .mockImplementation((callback) => frames.push(callback));
      try {
        table.row('2').focus();
        table.table.redrawTableAndTimeline();
        await Promise.resolve();
        table.row('2').blur();
        navigation(table).captureOwnership();
        await Promise.resolve();

        frames.splice(0).forEach((frame) => frame(0));

        expect(table.row('2')).toHaveFocus();
      } finally {
        frameSpy.mockRestore();
      }
    });

    it('a row refresh between scheduling a full render and its commit leaves focus to the commit', async () => {
      const table = await mount();
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
        .mockImplementation((callback) => frames.push(callback));
      try {
        table.row('2').focus();
        table.table.redrawTableAndTimeline();
        await Promise.resolve();
        table.table.refreshRows(resource(table, '2'));
        const refreshed = table.row('2');

        frames.splice(0).forEach((frame) => frame(0));

        expect(table.row('2')).not.toBe(refreshed);
        expect(table.row('2')).toHaveFocus();
      } finally {
        frameSpy.mockRestore();
      }
    });

    it('a table destroyed before the rAF commit restores nothing and throws nothing', async () => {
      const table = await mount();
      const frames:FrameRequestCallback[] = [];
      const frameSpy = vi.spyOn(window, 'requestAnimationFrame')
        .mockImplementation((callback) => frames.push(callback));
      try {
        table.row('2').focus();
        table.table.redrawTableAndTimeline();
        table.table.destroy();
        table.row('2').blur();

        expect(() => frames.splice(0).forEach((frame) => frame(0))).not.toThrow();
        table.querySpace.tableRendered.putValue(table.querySpace.tableRendered.value);

        expect(document.body).toHaveFocus();
      } finally {
        frameSpy.mockRestore();
      }
    });
  });

  describe('selection chords', () => {
    it('fire only on the roving stop', async () => {
      const table = await mount({}, (harness) => {
        harness.injector.get(DisplayFieldService).addFieldType(AnchorDisplayField, 'text', ['String']);
      });
      const subjectCell = table.row('1').querySelector<HTMLTableCellElement>('td.subject')!;
      subjectCell.focus();
      const link = within(subjectCell).getByRole('link');

      expect(press(link, ' ', { shiftKey: true })).toBe(true);
      expect(press(link, 'ArrowDown', { shiftKey: true })).toBe(true);

      expect(selectedIds(table)).toEqual([]);
      expect(subjectCell).toHaveFocus();
    });

    it('leave Shift+ArrowLeft and Shift+ArrowRight unconsumed and in place', async () => {
      const table = await mount();
      table.row('1').focus();

      expect(pressActive('ArrowRight', { shiftKey: true })).toBe(true);
      expect(pressActive('ArrowLeft', { shiftKey: true })).toBe(true);

      expect(table.row('1')).toHaveFocus();
      expect(navigation(table).position).toEqual({ key: wpOccurrenceKey('1'), cell: null, desiredColumn: null });
    });

    it('leave Tab handling unchanged with Shift held', async () => {
      const table = await mount();
      table.row('2').focus();

      expect(pressActive('Tab', { shiftKey: true })).toBe(true);

      expect(table.row('2')).toHaveAttribute('tabindex', '0');
      expect(selectedIds(table)).toEqual([]);
    });

    it('handle Ctrl+A once on a capability-on table', async () => {
      const table = await mount();
      const selectAll = vi.spyOn(table.selection, 'selectAll');
      table.row('1').focus();

      expect(pressActive('a', { code: 'KeyA', ctrlKey: true })).toBe(false);

      expect(selectAll).toHaveBeenCalledTimes(1);
      expect(selectedIds(table)).toEqual(['1', '2', '3']);
    });

    it.each([
      ['Ctrl+D', { code: 'KeyD', ctrlKey: true }],
      ['Meta+D', { code: 'KeyD', metaKey: true }],
    ])('leave %s to the browser on a capability-on table', async (_chord, init) => {
      const table = await mount();
      table.row('1').focus();
      expect(pressActive(' ', { shiftKey: true })).toBe(false);
      expect(selectedIds(table)).toEqual(['1']);

      expect(pressActive('d', init)).toBe(true);

      expect(selectedIds(table)).toEqual(['1']);
      expect(table.row('1')).toHaveFocus();
    });

    it('still select all through the legacy registration on a capability-off table', async () => {
      const table = await mount({ configuration: { keyboardNavigationEnabled: false } });
      const selectAll = vi.spyOn(table.selection, 'selectAll');

      expect(press(table.row('1'), 'a', { code: 'KeyA', ctrlKey: true })).toBe(false);

      expect(selectAll).toHaveBeenCalledTimes(1);
      expect(selectedIds(table)).toEqual(['1', '2', '3']);
    });
  });
});
