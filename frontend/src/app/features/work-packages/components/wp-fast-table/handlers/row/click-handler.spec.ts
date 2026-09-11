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

import { fireEvent } from '@testing-library/dom';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('RowClickHandler', () => {
  let harness:TableHarness;

  beforeEach(async () => {
    harness = buildTable({ workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }] });
    await harness.render();
  });

  afterEach(() => harness.destroy());

  const selectedIds = () => harness.selection.getSelectedWorkPackageIds().sort();
  const checkedIds = () => harness
    .rows()
    .filter((row) => row.classList.contains('-checked'))
    .map((row) => row.dataset.workPackageId);

  it('replaces the selection on a plain click', () => {
    harness.click('1');
    harness.click('3');

    expect(selectedIds()).toEqual(['3']);
    expect(checkedIds()).toEqual(['3']);
  });

  it('emits the clicked work package and the new selection', () => {
    const clicked:string[] = [];
    const selections:string[][] = [];
    harness.outputs.itemClicked.subscribe(({ workPackageId }) => clicked.push(workPackageId));
    harness.outputs.selectionChanged.subscribe((ids) => selections.push(ids));

    harness.click('2');

    expect(clicked).toEqual(['2']);
    expect(selections).toEqual([['2']]);
  });

  it.each([
    { modifiers: { shiftKey: true }, expected: ['1', '2', '3'] },
    { modifiers: { ctrlKey: true }, expected: ['1', '3'] },
    { modifiers: { metaKey: true }, expected: ['1', '3'] },
  ])('emits only selection changes for $modifiers', ({ modifiers, expected }) => {
    harness.click('1');
    const itemClicked = vi.fn();
    const selectionChanged = vi.fn();
    harness.outputs.itemClicked.subscribe(itemClicked);
    harness.outputs.selectionChanged.subscribe(selectionChanged);

    harness.click('3', modifiers);

    expect(itemClicked).not.toHaveBeenCalled();
    expect(selectionChanged).toHaveBeenCalledExactlyOnceWith(expected);
  });

  it('selects the range from the anchor on shift-click', () => {
    harness.click('2');
    harness.click('4', { shiftKey: true });

    expect(selectedIds()).toEqual(['2', '3', '4']);
    expect(checkedIds()).toEqual(['2', '3', '4']);
  });

  it.each([false, true])('uses the clicked occurrence when a work package appears twice (reverse: %s)', async (reverse) => {
    await harness.render([{ id: '1' }, { id: '3' }, { id: '2' }, { id: '4' }]);
    const primaryRow = harness.row('2');
    const relationRow = primaryRow.cloneNode(true) as HTMLTableRowElement;
    relationRow.dataset.classIdentifier = 'wp-relation-row-1-to-2';
    harness.row('1').after(relationRow);
    const rendered = [...harness.table.renderedRows];
    rendered.splice(1, 0, { classIdentifier: 'wp-relation-row-1-to-2', workPackageId: '2', hidden: false });
    harness.querySpace.tableRendered.putValue(rendered);

    const rows = reverse ? [harness.row('4'), primaryRow] : [primaryRow, harness.row('4')];
    rows.forEach((row, index) => fireEvent.click(row, { shiftKey: index === 1 }));

    expect(selectedIds()).toEqual(['2', '4']);
  });

  it('clears an anchor when only its other occurrence survives', () => {
    const primaryRow = harness.row('2');
    const relationRow = primaryRow.cloneNode(true) as HTMLTableRowElement;
    relationRow.dataset.classIdentifier = 'wp-relation-row-1-to-2';
    harness.row('1').after(relationRow);
    const rendered = [...harness.table.renderedRows];
    rendered.splice(1, 0, { classIdentifier: 'wp-relation-row-1-to-2', workPackageId: '2', hidden: false });
    harness.querySpace.tableRendered.putValue(rendered);
    fireEvent.click(primaryRow);
    primaryRow.remove();
    harness.querySpace.tableRendered.putValue(rendered.filter((row) => row.classIdentifier !== primaryRow.dataset.classIdentifier));
    harness.click('4', { shiftKey: true });
    expect(selectedIds()).toEqual(['4']);
    expect(harness.row('4')).toHaveClass('-checked');
    expect(relationRow).not.toHaveClass('-checked');
  });

  it('keeps the range anchored to the first selected row', () => {
    harness.click('2');
    harness.click('4', { shiftKey: true });
    harness.click('1', { shiftKey: true });

    expect(selectedIds()).toEqual(['1', '2']);
  });

  it('toggles single rows with ctrl or meta', () => {
    harness.click('1');
    harness.click('3', { ctrlKey: true });
    expect(selectedIds()).toEqual(['1', '3']);

    harness.click('1', { metaKey: true });
    expect(selectedIds()).toEqual(['3']);
    expect(checkedIds()).toEqual(['3']);
  });

  it('keeps the last row deselected after the focus update', () => {
    harness.click('2');
    harness.click('2', { ctrlKey: true });
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual([]);
    expect(harness.selection.isEmpty).toBe(true);
    expect(harness.row('2')).not.toHaveClass('-checked');
    harness.click('4', { shiftKey: true });
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2', '3', '4']);
  });

  it.each([false, true])('initializes selection before double-click focus (selected: %s)', (alreadySelected) => {
    if (alreadySelected) harness.selection.initializeSelection(['1']);
    const expected = alreadySelected ? ['1'] : ['2'];
    const focusStates:string[] = [];
    const observedMembers:string[][] = [];
    harness.focus.updates$().subscribe((state) => {
      observedMembers.push(harness.selection.getSelectedWorkPackageIds());
      expect(state).toEqual({ workPackageId: '2', focusAfterRender: false, navigate: true });
      focusStates.push(state.workPackageId);
    });
    fireEvent.doubleClick(harness.row('2').querySelector('td')!);
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(expected);
    expect(focusStates).toEqual(['2']);
    expect(observedMembers).toEqual([expected]);
  });

  it('marks the clicked row as the current work package', () => {
    harness.click('2');

    expect(harness.focus.focusedWorkPackage).toBe('2');
    expect(harness.row('2')).toHaveClass('-pressed');
  });
});
