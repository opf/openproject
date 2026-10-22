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
import { States } from 'core-app/core/states/states.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { TextDisplayField } from 'core-app/shared/components/fields/display/field-types/text-display-field.module';
import { WorkPackageViewCollapsedGroupsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-collapsed-groups.service';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { buildTable, TableHarness, TableHarnessOptions } from '../../../testing/table-harness';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import { KeyboardNavigation } from './keyboard-navigation-transformer';
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

  const cell = (row:HTMLTableRowElement, index:number) => navigableCells(row)[index];

  const selectedIds = (table:TableHarness) => table.selection.getSelectedWorkPackageIds().sort();

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
    ['Alt', { altKey: true }],
    ['composition', { isComposing: true }],
    ['Ctrl', { ctrlKey: true }],
    ['Shift', { shiftKey: true }],
  ])('keys with %s are not handled', async (_name, init) => {
    const table = await mount();
    table.row('2').focus();

    expect(pressActive('ArrowDown', init)).toBe(true);

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
      });
      const hierarchies = table.injector.get(WorkPackageViewHierarchiesService);
      const idCell = table.row('1').querySelector<HTMLTableCellElement>('td.id')!;
      const link = idCell.querySelector('a') ?? idCell;
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
});
