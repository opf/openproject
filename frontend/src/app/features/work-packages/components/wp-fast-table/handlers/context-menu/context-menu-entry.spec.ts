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
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-table-context-menu.directive';
import { buildTable, TableHarness } from '../../testing/table-harness';

describe('Context menu entry', () => {
  let harness:TableHarness;
  let menuTargets:string[][];
  let opened:ReturnType<typeof vi.spyOn>;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      configuration: { contextMenuEnabled: true },
    });
    await harness.render();

    menuTargets = [];
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((workPackages:WorkPackageResource[]) => {
        menuTargets.push(workPackages.map((wp) => wp.id!));
        return [];
      });
    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  });

  afterEach(() => harness.destroy());

  const openFromKeyboard = (workPackageId:string) => fireEvent.keyDown(
    harness.row(workPackageId),
    { key: 'F10', shiftKey: true, altKey: true },
  );

  it('selects an unselected row and opens the menu for it alone', () => {
    harness.click('2');

    expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(harness.focus.focusedWorkPackage).toBe('2');
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1']]);
  });

  it('keeps a batch selection and opens the menu for the whole batch', () => {
    harness.click('1');
    harness.click('2', { shiftKey: true });

    fireEvent.contextMenu(harness.row('2'));

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1', '2']]);
  });

  it('selects an unselected row from the keyboard and opens the menu for it alone', () => {
    harness.click('2');

    expect(openFromKeyboard('1')).toBe(false);

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1']]);
  });

  it('selects the row from the keyboard when nothing is selected', () => {
    openFromKeyboard('1');

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(menuTargets).toEqual([['1']]);
  });

  it('keeps a batch selection from the keyboard and ranges from the menu row afterwards', () => {
    harness.click('1');
    harness.click('2', { shiftKey: true });

    openFromKeyboard('2');

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
    expect(menuTargets).toEqual([['1', '2']]);

    openFromKeyboard('3');
    harness.click('1', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2', '3']);
  });

  it('anchors a following range at the occurrence the keyboard menu was opened on', () => {
    harness.click('2');
    const relationRow = harness.addRelationRow('1', '3');

    fireEvent.keyDown(relationRow, { key: 'F10', shiftKey: true, altKey: true });
    harness.click('3', { shiftKey: true });

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
  });

  it('targets only the menu row when it is outside the selection', () => {
    harness.click('2');

    new WorkPackageTableContextMenu(harness.injector, '1', harness.row('1'), {}, harness.table);

    expect(menuTargets).toEqual([['1']]);
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });
});

describe('Context menu entry from the actions column button', () => {
  let harness:TableHarness;
  let menuTargets:string[][];
  let opened:ReturnType<typeof vi.spyOn>;

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      configuration: { contextMenuEnabled: true, actionsColumnEnabled: true },
    });
    await harness.render();

    menuTargets = [];
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((workPackages:WorkPackageResource[]) => {
        menuTargets.push(workPackages.map((wp) => wp.id!));
        return [];
      });
    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  });

  afterEach(() => harness.destroy());

  const menuButton = (workPackageId:string) => within(harness.row(workPackageId))
    .getByRole('link', { name: 'js.label_open_context_menu' });

  it('selects an unselected row and opens the menu for it alone', () => {
    harness.click('2');

    fireEvent.click(menuButton('1'));

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);
    expect(opened).toHaveBeenCalledTimes(1);
    expect(menuTargets).toEqual([['1']]);
  });

  it('keeps a batch selection and opens the menu for the whole batch', () => {
    harness.click('1');
    harness.click('2', { shiftKey: true });

    fireEvent.click(menuButton('2'));

    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
    expect(menuTargets).toEqual([['1', '2']]);
  });
});

describe('Context menu entry on the inline-create row', () => {
  let harness:TableHarness;
  let inlineCreateRow:HTMLTableRowElement;
  let opened:ReturnType<typeof vi.spyOn>;

  const menuShortcut = { key: 'F10', shiftKey: true, altKey: true };

  const openSubjectEditor = async () => {
    fireEvent.click(inlineCreateRow.querySelector<HTMLElement>('td.subject .inline-edit--display-field')!);
    await waitFor(() => expect(within(inlineCreateRow).getByRole('textbox')).toHaveFocus());

    return within(inlineCreateRow).getByRole('textbox');
  };

  beforeEach(async () => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }],
      configuration: { contextMenuEnabled: true, inlineCreateEnabled: true },
      editing: {},
    });
    await harness.render();
    inlineCreateRow = harness.addInlineCreateRow();
    harness.click('2');

    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  });

  afterEach(() => harness.destroy());

  it('opens no menu and keeps the selection on right-click of a cell', () => {
    fireEvent.contextMenu(inlineCreateRow.querySelector('td.subject')!);

    expect(opened).not.toHaveBeenCalled();
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  it('leaves the browser context menu alone on right-click inside the subject editor', async () => {
    const editor = await openSubjectEditor();

    expect(fireEvent.contextMenu(editor)).toBe(true);

    expect(opened).not.toHaveBeenCalled();
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  it('opens no menu and keeps the selection on the keyboard menu shortcut', async () => {
    const editor = await openSubjectEditor();

    expect(fireEvent.keyDown(editor, menuShortcut)).toBe(true);

    expect(opened).not.toHaveBeenCalled();
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  it('still opens the menu for saved rows', () => {
    fireEvent.contextMenu(harness.row('1'));

    expect(opened).toHaveBeenCalledTimes(1);
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1']);

    fireEvent.keyDown(harness.row('2'), menuShortcut);

    expect(opened).toHaveBeenCalledTimes(2);
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });
});
