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
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageTableContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-table-context-menu.directive';
import { registerContextMenu } from 'core-app/shared/components/op-context-menu/testing/register-context-menu';
import { buildTable, TableHarness, type TableHarnessOptions } from '../../testing/table-harness';
import { wpOccurrenceKey } from '../../rendered-occurrence-ledger';
import { headerRowKey, totalsRowKey } from '../state/keyboard/navigable-rows';
import { navigableCells } from '../state/keyboard/roving-tabindex';
import { uiStateLinkClass } from '../../builders/ui-state-link-builder';

describe('Context menu entry', () => {
  let harness:TableHarness;
  let menuTargets:string[][];
  let opened:ReturnType<typeof vi.spyOn>;

  const mount = async (options:Partial<TableHarnessOptions> = {}, expanded:[string, string][] = []) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      configuration: { contextMenuEnabled: true },
      ...options,
    });
    expanded.forEach(([workPackageId, columnId]) => harness.expand(workPackageId, columnId));
    await harness.render();

    menuTargets = [];
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((workPackages:WorkPackageResource[]) => {
        menuTargets.push(workPackages.map((wp) => wp.id!));
        return [];
      });
    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  };

  beforeEach(() => mount());

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

  it('targets only the menu row when it is outside the selection', () => {
    harness.click('2');

    new WorkPackageTableContextMenu(harness.injector, '1', harness.row('1'), {}, harness.table);

    expect(menuTargets).toEqual([['1']]);
    expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
  });

  describe('with a relation row', () => {
    beforeEach(async () => {
      await harness.destroy();
      await mount({
        relations: [{ from: '3', to: '1', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
      }, [['3', 'relationsOfTypeFollows']]);
    });

    it('anchors a following range at the occurrence the keyboard menu was opened on', () => {
      harness.click('2');

      fireEvent.keyDown(harness.relationRow('3', '1'), { key: 'F10', shiftKey: true, altKey: true });
      harness.click('3', { shiftKey: true });

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '3']);
    });
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

describe('Context menu keyboard chords', () => {
  let harness:TableHarness;
  let menuTargets:string[][];
  let opened:ReturnType<typeof vi.spyOn>;
  let clock:number;

  const newStatus = { href: '/api/v3/statuses/1' };
  const inProgressStatus = { href: '/api/v3/statuses/2' };

  const chords:Record<string, KeyboardEventInit> = {
    'Shift+F10': { key: 'F10', shiftKey: true },
    Menu: { key: 'ContextMenu' },
    'Shift+Alt+F10': { key: 'F10', shiftKey: true, altKey: true },
  };

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      productionMarkup: true,
      ...options,
      configuration: { contextMenuEnabled: true, keyboardNavigationEnabled: true, ...options.configuration },
    });
    await harness.render();

    menuTargets = [];
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockImplementation((workPackages:WorkPackageResource[]) => {
        menuTargets.push(workPackages.map((wp) => wp.id!));
        return [];
      });
    opened = vi.spyOn(harness.injector.get(OPContextMenuService), 'show');
  };

  const focusKey = (key:string) => harness.table.keyboardNavigation!
    .focusPosition({ key, cell: null, desiredColumn: null });

  const press = (chord:string, element:HTMLElement) => fireEvent.keyDown(element, chords[chord]);

  beforeEach(() => {
    clock = 1000;
    vi.spyOn(performance, 'now').mockImplementation(() => clock);
  });

  afterEach(async () => {
    vi.restoreAllMocks();
    await harness.destroy();
  });

  describe.each(Object.keys(chords))('%s', (chord) => {
    beforeEach(() => mount());

    it('opens once for the focused row', () => {
      focusKey(wpOccurrenceKey('2'));

      expect(press(chord, harness.row('2'))).toBe(false);

      expect(opened).toHaveBeenCalledTimes(1);
      expect(menuTargets).toEqual([['2']]);
    });

    it('opens for the row of the focused cell', () => {
      focusKey(wpOccurrenceKey('2'));
      const cell = harness.row('2').querySelector<HTMLElement>('td.subject')!;
      cell.focus();

      press(chord, cell);

      expect(opened).toHaveBeenCalledTimes(1);
      expect(menuTargets).toEqual([['2']]);
    });

    it('swallows a held-key repeat without opening again', () => {
      focusKey(wpOccurrenceKey('2'));
      press(chord, harness.row('2'));

      expect(fireEvent.keyDown(harness.row('2'), { ...chords[chord], repeat: true })).toBe(false);

      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('targets the selection when the row is selected', () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });

      press(chord, harness.row('2'));

      expect(menuTargets).toEqual([['1', '2']]);
    });

    it('replaces the selection when the row is not selected', () => {
      harness.click('1');

      press(chord, harness.row('3'));

      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['3']);
      expect(menuTargets).toEqual([['3']]);
    });
  });

  describe('companion contextmenu', () => {
    beforeEach(() => mount());

    it('is swallowed after a keyboard open', () => {
      press('Shift+F10', harness.row('1'));

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);

      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('does not suppress a right-click on another row within the window', () => {
      press('Shift+F10', harness.row('1'));

      fireEvent.contextMenu(harness.row('3'));

      expect(opened).toHaveBeenCalledTimes(2);
      expect(menuTargets).toEqual([['1'], ['3']]);
    });

    it('does not suppress a right-click on the same row after pointer input', () => {
      press('Shift+F10', harness.row('1'));
      fireEvent.pointerDown(harness.row('1'));

      fireEvent.contextMenu(harness.row('1'));

      expect(opened).toHaveBeenCalledTimes(2);
    });

    it('leaves the chords and the following contextmenu native on a focused id link', () => {
      const link = document.createElement('a');
      link.className = uiStateLinkClass;
      link.href = '#';
      harness.row('1').querySelector('td.subject')!.append(link);
      link.focus();

      Object.keys(chords).forEach((chord) => expect(press(chord, link)).toBe(true));

      expect(fireEvent.contextMenu(link)).toBe(true);
      expect(opened).not.toHaveBeenCalled();
    });

    it('is still swallowed at 499 ms', () => {
      press('Shift+F10', harness.row('1'));
      clock += 499;

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);

      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('does not suppress a genuine right-click at 501 ms', () => {
      press('Shift+F10', harness.row('1'));
      clock += 501;

      fireEvent.contextMenu(harness.row('1'));

      expect(opened).toHaveBeenCalledTimes(2);
    });

    it('is still swallowed after a chord held past the window', () => {
      press('Shift+F10', harness.row('1'));
      clock += 400;
      fireEvent.keyDown(harness.row('1'), { ...chords['Shift+F10'], repeat: true });
      clock += 400;
      fireEvent.keyDown(harness.row('1'), { ...chords['Shift+F10'], repeat: true });
      clock += 300;

      expect(fireEvent.contextMenu(harness.row('1'))).toBe(false);

      expect(opened).toHaveBeenCalledTimes(1);
    });

    it('is consumed only once', () => {
      press('Menu', harness.row('1'));
      fireEvent.contextMenu(harness.row('1'));

      fireEvent.contextMenu(harness.row('1'));

      expect(opened).toHaveBeenCalledTimes(2);
    });

    it('opens a bare contextmenu on a focused row and on a focused cell once each', () => {
      focusKey(wpOccurrenceKey('1'));
      fireEvent.contextMenu(harness.row('1'));
      expect(opened).toHaveBeenCalledTimes(1);

      const cell = harness.row('2').querySelector<HTMLElement>('td.subject')!;
      cell.focus();
      fireEvent.contextMenu(cell);
      expect(opened).toHaveBeenCalledTimes(2);
    });
  });

  describe('structural rows', () => {
    beforeEach(() => mount({
      workPackages: [
        { id: '1', attributes: { status: newStatus } },
        { id: '2', attributes: { status: inProgressStatus } },
      ],
      groups: [
        { value: 'New', href: newStatus.href, count: 1, sums: { storyPoints: 13 } },
        { value: 'In progress', href: inProgressStatus.href, count: 1, sums: { storyPoints: 21 } },
      ],
    }));

    it('do nothing on a group sums row', () => {
      const sumsRow = harness.table.tableAndTimelineContainer.querySelector<HTMLElement>('.wp-table--sums-row')!;

      Object.keys(chords).forEach((chord) => expect(press(chord, sumsRow)).toBe(true));

      expect(opened).not.toHaveBeenCalled();
    });

    it('do nothing on a group header, the column header and totals', () => {
      const targets = [
        () => harness.groupHeader(0),
        () => { focusKey(headerRowKey); return harness.headerCells()[0]; },
        () => { focusKey(totalsRowKey); return harness.totalsRow(); },
      ];

      targets.forEach((target) => {
        const element = target();
        Object.keys(chords).forEach((chord) => press(chord, element));
      });

      expect(opened).not.toHaveBeenCalled();
    });
  });

  describe('inside an inline editor on a saved row', () => {
    beforeEach(() => mount({ editing: {} }));

    const openSubjectEditor = () => {
      fireEvent.click(harness.row('1').querySelector<HTMLElement>('td.subject .inline-edit--display-field')!);
      return within(harness.row('1')).findByRole('textbox');
    };

    it('leaves the chords to the editor', async () => {
      const input = await openSubjectEditor();

      Object.keys(chords).forEach((chord) => expect(press(chord, input)).toBe(true));

      expect(opened).not.toHaveBeenCalled();
    });

    it('leaves the native menu alone for the contextmenu that follows', async () => {
      const input = await openSubjectEditor();

      expect(fireEvent.contextMenu(input)).toBe(true);

      expect(opened).not.toHaveBeenCalled();
    });

    it('still opens on right-click of a display cell', async () => {
      await openSubjectEditor();

      fireEvent.contextMenu(harness.row('2').querySelector('td.subject')!);

      expect(opened).toHaveBeenCalledTimes(1);
      expect(menuTargets).toEqual([['2']]);
    });
  });

  describe('on a contenteditable="false" element', () => {
    beforeEach(() => mount());

    it('opens the row menu', () => {
      const element = document.createElement('span');
      element.contentEditable = 'false';
      element.tabIndex = -1;
      harness.row('1').querySelector('td.subject')!.append(element);
      element.focus();

      expect(press('Shift+F10', element)).toBe(false);
      expect(fireEvent.contextMenu(harness.row('2').querySelector('td.subject')!.appendChild(element))).toBe(false);

      expect(menuTargets).toEqual([['1'], ['2']]);
    });
  });

  describe('on a capability-off table', () => {
    beforeEach(() => mount({ editing: {}, configuration: { keyboardNavigationEnabled: false } }));

    const openSubjectEditor = () => {
      fireEvent.click(harness.row('1').querySelector<HTMLElement>('td.subject .inline-edit--display-field')!);
      return within(harness.row('1')).findByRole('textbox');
    };

    it('leaves Shift+F10 and Menu unhandled', () => {
      harness.row('2').focus();

      expect(press('Shift+F10', harness.row('2'))).toBe(true);
      expect(press('Menu', harness.row('2'))).toBe(true);

      expect(opened).not.toHaveBeenCalled();
    });

    it('opens on Shift+Alt+F10', () => {
      harness.row('2').focus();

      expect(press('Shift+Alt+F10', harness.row('2'))).toBe(false);

      expect(menuTargets).toEqual([['2']]);
    });

    it('opens the row menu on Shift+Alt+F10 on the id link', () => {
      const link = document.createElement('a');
      link.className = uiStateLinkClass;
      link.href = '#';
      harness.row('1').querySelector('td.subject')!.append(link);
      link.focus();

      expect(press('Shift+Alt+F10', link)).toBe(false);

      expect(menuTargets).toEqual([['1']]);
    });

    it('opens the row menu on Shift+Alt+F10 inside an open editor', async () => {
      const input = await openSubjectEditor();

      expect(press('Shift+Alt+F10', input)).toBe(false);

      expect(menuTargets).toEqual([['1']]);
    });

    it('opens the row menu on right-click inside an open editor', async () => {
      const input = await openSubjectEditor();

      expect(fireEvent.contextMenu(input)).toBe(false);

      expect(menuTargets).toEqual([['1']]);
    });
  });

  describe('with the context menu disabled', () => {
    beforeEach(() => mount({ configuration: { contextMenuEnabled: false } }));

    it('leaves all three chords inert', () => {
      Object.keys(chords).forEach((chord) => press(chord, harness.row('1')));

      expect(opened).not.toHaveBeenCalled();
    });
  });

  describe('on the inline-create row', () => {
    beforeEach(async () => {
      await mount({ configuration: { inlineCreateEnabled: true } });
    });

    it('is refused', () => {
      const inlineCreateRow = harness.addInlineCreateRow();

      Object.keys(chords).forEach((chord) => press(chord, inlineCreateRow));

      expect(opened).not.toHaveBeenCalled();
    });
  });
});

describe('Context menu focus return', () => {
  let harness:TableHarness;
  let menu:OPContextMenuService;
  let unregister:() => void;
  let action:() => void;
  let page:HTMLElement;

  const nextFrame = () => new Promise<void>((resolve) => { requestAnimationFrame(() => resolve()); });

  const mount = async (options:Partial<TableHarnessOptions> = {}) => {
    harness = buildTable({
      workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
      columns: ['id', 'subject', 'status'],
      productionMarkup: true,
      providers: [OPContextMenuService],
      ...options,
      configuration: { contextMenuEnabled: true, keyboardNavigationEnabled: true, ...options.configuration },
    });
    await harness.render();

    page = document.createElement('div');
    page.id = 'wrapper';
    page.textContent = 'Blank page';
    document.body.append(page);
    menu = harness.injector.get(OPContextMenuService);
    unregister = registerContextMenu(menu);
    action = () => undefined;
    vi.spyOn(harness.injector.get(WorkPackageContextMenuHelperService), 'getPermittedActions')
      .mockReturnValue([{ key: 'test-action', text: 'Test action', link: '#' }]);
    vi.spyOn(WorkPackageTableContextMenu.prototype, 'triggerContextMenuAction').mockImplementation(() => action());
  };

  const cellOf = (workPackageId:string, index:number) => navigableCells(harness.row(workPackageId))[index];

  const resource = (id:string) => harness.injector.get(States).workPackages.get(id).value!;

  const openFromKeyboard = async (target:HTMLElement) => {
    target.focus();
    fireEvent.keyDown(target, { key: 'F10', shiftKey: true });
    return waitFor(() => {
      const item = document.querySelector<HTMLElement>('.op-context-menu--overlay .menu-item')!;
      expect(item).toHaveFocus();
      return item;
    });
  };

  const openOnCell = (workPackageId:string, index:number) => {
    harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey(workPackageId), cell: index, desiredColumn: index });
    return openFromKeyboard(cellOf(workPackageId, index));
  };

  const clickAction = async () => {
    const item = await waitFor(() => within(document.querySelector<HTMLElement>('.op-context-menu--overlay')!)
      .getByRole('menuitem', { name: 'Test action' }));
    fireEvent.click(item);
  };

  afterEach(async () => {
    await nextFrame();
    await nextFrame();
    await nextFrame();
    menu.close();
    unregister();
    page.remove();
    vi.restoreAllMocks();
    await harness.destroy();
  });

  describe('on a capability-on table', () => {
    beforeEach(() => mount());

    it('row menu: an action that re-renders the row returns focus to the origin cell, not the body', async () => {
      action = () => harness.table.refreshRows(resource('2'));
      await openOnCell('2', 2);

      await clickAction();

      expect(menu.active).toBeNull();
      expect(cellOf('2', 2)).toHaveFocus();
    });

    it('Escape close returns to a row origin', async () => {
      harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
      await openFromKeyboard(harness.row('2'));

      fireEvent.keyDown(document.activeElement!, { key: 'Escape' });

      expect(menu.active).toBeNull();
      expect(harness.row('2')).toHaveFocus();
    });

    it('Escape close returns to a cell origin', async () => {
      await openOnCell('2', 1);

      fireEvent.keyDown(document.activeElement!, { key: 'Escape' });

      expect(cellOf('2', 1)).toHaveFocus();
    });

    it('Escape immediately after opening closes the menu, returns focus and keeps the selection', async () => {
      harness.click('2');
      harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
      fireEvent.keyDown(cellOf('2', 1), { key: 'F10', shiftKey: true });

      fireEvent.keyDown(cellOf('2', 1), { key: 'Escape' });

      expect(menu.active).toBeNull();
      await nextFrame();
      await nextFrame();
      await nextFrame();
      expect(document.querySelector('.op-context-menu--overlay .menu-item')).toBeNull();
      expect(cellOf('2', 1)).toHaveFocus();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['2']);
    });

    it('a click outside closes a right-click menu without pulling focus into the table', async () => {
      fireEvent.contextMenu(cellOf('2', 1));
      await waitFor(() => expect(document.querySelector('.op-context-menu--overlay .menu-item')).toHaveFocus());

      fireEvent.click(page);

      expect(menu.active).toBeNull();
      expect(document.body).toHaveFocus();
    });

    it('a scroll closes a keyboard-opened menu without moving focus or scrolling', async () => {
      await openOnCell('2', 1);
      const scrolled = vi.spyOn(Element.prototype, 'scrollIntoView');

      fireEvent.scroll(page);

      expect(menu.active).toBeNull();
      expect(document.body).toHaveFocus();
      expect(scrolled).not.toHaveBeenCalled();
    });

    it('origin row removed by the action: focus lands on the reconciled neighbor', async () => {
      action = () => { void harness.render([{ id: '1' }, { id: '3' }]); };
      await openOnCell('2', 1);

      const rendered = harness.nextRender();
      await clickAction();
      await rendered;

      await waitFor(() => expect(harness.row('3')).toHaveFocus());
    });

    it('a newer external owner keeps focus', async () => {
      const input = document.createElement('input');
      document.body.append(input);
      try {
        action = () => input.focus();
        await openOnCell('2', 1);

        await clickAction();

        expect(input).toHaveFocus();
      } finally {
        input.remove();
      }
    });

    it('pointer moved to another row while the menu was open: no return, not even when a pending render commits', async () => {
      await openOnCell('2', 1);

      fireEvent.mouseDown(cellOf('3', 1), { button: 0 });
      const rendered = harness.render();
      fireEvent.keyDown(document.activeElement!, { key: 'Escape' });
      await rendered;

      expect(cellOf('3', 1)).not.toHaveFocus();
      expect(cellOf('2', 1)).not.toHaveFocus();
      expect(document.body).toHaveFocus();
    });

    it('teardown with a menu open: close after destroy does not throw', async () => {
      await openOnCell('2', 1);

      await harness.destroy();

      expect(() => menu.close(true)).not.toThrow();
      expect(menu.active).toBeNull();
      expect(document.body).toHaveFocus();
    });

    describe.each([
      ['Shift+F10', { key: 'F10', shiftKey: true }],
      ['Menu', { key: 'ContextMenu' }],
      ['Shift+Alt+F10', { key: 'F10', shiftKey: true, altKey: true }],
    ] as [string, KeyboardEventInit][])('holding %s', (_name, chord) => {
      it('opens one menu without errors and moves focus into it', async () => {
        const errors:unknown[] = [];
        const collect = (event:ErrorEvent) => errors.push(event.error);
        window.addEventListener('error', collect);
        const shown = vi.spyOn(menu, 'show');
        try {
          harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('2'), cell: 1, desiredColumn: 1 });
          cellOf('2', 1).focus();

          fireEvent.keyDown(cellOf('2', 1), chord);
          fireEvent.keyDown(cellOf('2', 1), { ...chord, repeat: true });

          await waitFor(() => expect(document.querySelector('.op-context-menu--overlay .menu-item')).toHaveFocus());
          expect(shown).toHaveBeenCalledTimes(1);
          expect(document.querySelectorAll('.op-context-menu--overlay .dropdown')).toHaveLength(1);
          expect(errors).toEqual([]);
        } finally {
          window.removeEventListener('error', collect);
        }
      });
    });

    describe('companion contextmenu after a keyboard-opened menu closed', () => {
      let clock:number;
      let shown:ReturnType<typeof vi.spyOn>;

      beforeEach(() => {
        clock = 1000;
        vi.spyOn(performance, 'now').mockImplementation(() => clock);
        shown = vi.spyOn(menu, 'show');
      });

      const rightClickWithinWindow = () => {
        clock += 100;
        return fireEvent.contextMenu(harness.row('2'));
      };

      it('opens a bare same-row contextmenu after an Escape close', async () => {
        harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
        await openFromKeyboard(harness.row('2'));
        fireEvent.keyDown(document.activeElement!, { key: 'Escape' });

        expect(rightClickWithinWindow()).toBe(false);

        expect(shown).toHaveBeenCalledTimes(2);
        expect(menu.active).not.toBeNull();
      });

      it('opens a bare same-row contextmenu after an action close', async () => {
        harness.table.keyboardNavigation!.focusPosition({ key: wpOccurrenceKey('2'), cell: null, desiredColumn: null });
        await openFromKeyboard(harness.row('2'));
        await clickAction();

        rightClickWithinWindow();

        expect(shown).toHaveBeenCalledTimes(2);
        expect(menu.active).not.toBeNull();
      });

      it('still swallows the companion of a keyboard open that replaces an open menu', async () => {
        fireEvent.contextMenu(cellOf('1', 1));
        await waitFor(() => expect(document.querySelector('.op-context-menu--overlay .menu-item')).toHaveFocus());

        fireEvent.keyDown(harness.row('2'), { key: 'F10', shiftKey: true });

        expect(rightClickWithinWindow()).toBe(false);
        expect(shown).toHaveBeenCalledTimes(2);
      });
    });

    it('Escape with a menu open closes only the menu; the selection survives', async () => {
      harness.click('1');
      harness.click('2', { shiftKey: true });
      await openOnCell('2', 1);

      fireEvent.keyDown(document.activeElement!, { key: 'Escape' });

      expect(menu.active).toBeNull();
      expect(harness.selection.getSelectedWorkPackageIds()).toEqual(['1', '2']);
      expect(cellOf('2', 1)).toHaveFocus();
    });
  });

  describe('with a hierarchy', () => {
    beforeEach(() => mount({
      workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
      showHierarchies: true,
    }));

    it('origin hidden by a collapse: focus lands on the row hiding it', async () => {
      action = () => harness.injector.get(WorkPackageViewHierarchiesService).collapse('1');
      await openOnCell('2', 1);

      await clickAction();

      await waitFor(() => expect(harness.row('1')).toHaveFocus());
    });
  });

  describe('on a capability-off table', () => {
    beforeEach(() => mount({ productionMarkup: false, configuration: { keyboardNavigationEnabled: false } }));

    it('menu close behaves as before: an action leaves focus alone, Escape focuses the trigger', async () => {
      const openByRightClick = () => {
        fireEvent.contextMenu(harness.row('2'));
        return waitFor(() => expect(document.querySelector('.op-context-menu--overlay .menu-item')).toHaveFocus());
      };
      await openByRightClick();
      await clickAction();

      expect(document.body).toHaveFocus();

      await openByRightClick();
      fireEvent.keyDown(document.activeElement!, { key: 'Escape' });

      expect(harness.table.keyboardNavigation).toBeNull();
      expect(menu.active).toBeNull();
      expect(harness.row('2')).toHaveFocus();
    });
  });
});
