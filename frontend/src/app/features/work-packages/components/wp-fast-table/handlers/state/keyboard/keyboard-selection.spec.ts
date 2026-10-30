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

import { createEvent, fireEvent, waitFor } from '@testing-library/dom';
import { LiveRegionElement } from '@primer/live-region-element';
import { type MockInstance } from 'vitest';
import { usePlatform } from 'core-common/testing/platform';
import { WorkPackageViewHierarchiesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy.service';
import { buildTable, TableHarness, TableHarnessOptions } from '../../../testing/table-harness';
import { wpOccurrenceKey } from '../../../rendered-occurrence-ledger';
import { headerRowKey, totalsRowKey } from './navigable-rows';
import { selectionChord } from './keyboard-selection';

const newStatus = { href: '/api/v3/statuses/1' };
const inProgressStatus = { href: '/api/v3/statuses/2' };

const flat:Partial<TableHarnessOptions> = {
  workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }, { id: '4' }, { id: '5' }],
};

const groupedWorkPackages = [
  { id: '1', attributes: { status: newStatus } },
  { id: '2', attributes: { status: newStatus } },
  { id: '3', attributes: { status: inProgressStatus } },
  { id: '4', attributes: { status: inProgressStatus } },
];

const grouped:Partial<TableHarnessOptions> = {
  workPackages: groupedWorkPackages,
  groups: [
    { value: 'New', href: newStatus.href, count: 2 },
    { value: 'In progress', href: inProgressStatus.href, count: 2 },
  ],
};

const groupedWithSums:Partial<TableHarnessOptions> = {
  workPackages: groupedWorkPackages,
  groups: [
    { value: 'New', href: newStatus.href, count: 2, sums: { storyPoints: 13 } },
    { value: 'In progress', href: inProgressStatus.href, count: 2, sums: { storyPoints: 21 } },
  ],
};

describe('KeyboardSelection', () => {
  const harnesses:TableHarness[] = [];
  const pretendPlatform = usePlatform();
  let announceSpy:MockInstance<typeof LiveRegionElement.prototype.announce>;

  const mount = async (options:Partial<TableHarnessOptions> = flat) => {
    const table = buildTable({
      productionMarkup: true,
      ...options,
      configuration: { keyboardNavigationEnabled: true, ...options.configuration },
    } as TableHarnessOptions);
    harnesses.push(table);
    await table.render();
    return table;
  };

  const navigation = (table:TableHarness) => table.table.keyboardNavigation!;

  const focusKey = (table:TableHarness, key:string) => navigation(table)
    .focusPosition({ key, cell: null, desiredColumn: null });

  const focusRow = (table:TableHarness, id:string) => focusKey(table, wpOccurrenceKey(id));

  const focusElement = (table:TableHarness, element:HTMLElement) => navigation(table)
    .focusPosition(navigation(table).positionOfCell(element)!);

  const press = (key:string, init:KeyboardEventInit = {}) => fireEvent.keyDown(document.activeElement!, { key, ...init });

  const shiftSpace = (init:KeyboardEventInit = {}) => press(' ', { code: 'Space', shiftKey: true, ...init });
  const shiftDown = (init:KeyboardEventInit = {}) => press('ArrowDown', { shiftKey: true, ...init });
  const shiftUp = (init:KeyboardEventInit = {}) => press('ArrowUp', { shiftKey: true, ...init });
  const ctrlA = (init:KeyboardEventInit = {}) => press('a', { code: 'KeyA', ctrlKey: true, ...init });

  // Stubbed rather than passed as `modifierAltGraph`: not every engine maps
  // the init member onto getModifierState.
  const withAltGraph = <T extends Event>(event:T):T => {
    vi.spyOn(event as unknown as KeyboardEvent, 'getModifierState').mockImplementation((key) => key === 'AltGraph');
    return event;
  };

  const selected = (table:TableHarness) => table.selection.getSelectedWorkPackageIds().sort();
  const spoken = () => announceSpy.mock.calls.map(([message]) => message);

  beforeEach(() => {
    document.body.append(document.createElement('live-region'));
    announceSpy = vi.spyOn(LiveRegionElement.prototype, 'announce');
    window.I18n.store({
      en: {
        js: {
          work_packages: {
            selection: {
              all_selected: {
                one: 'All %{count} work package on this page selected.',
                other: 'All %{count} work packages on this page selected.',
              },
              cleared: 'Selection cleared.',
              selected: { one: '%{count} work package selected.', other: '%{count} work packages selected.' },
            },
          },
        },
      },
    });
  });

  afterEach(async () => {
    await Promise.all(harnesses.splice(0).map((table) => table.destroy()));
    document.querySelector('live-region')?.remove();
    announceSpy.mockRestore();
  });

  describe('selectionChord', () => {
    const chord = (init:KeyboardEventInit & { key:string }, apple = false) => selectionChord(new KeyboardEvent('keydown', init), apple);

    it('recognizes the three chords and nothing else', () => {
      expect(chord({ key: ' ', shiftKey: true })).toBe('toggle');
      expect(chord({ key: 'ArrowUp', shiftKey: true })).toBe('extend');
      expect(chord({ key: 'ArrowDown', shiftKey: true })).toBe('extend');
      expect(chord({ key: 'a', ctrlKey: true })).toBe('selectAll');
      expect(chord({ key: 'a', metaKey: true }, true)).toBe('selectAll');
      expect(chord({ key: 'a', ctrlKey: true }, true)).toBeNull();
      expect(chord({ key: 'a', ctrlKey: true, shiftKey: true })).toBeNull();
      expect(chord({ key: ' ' })).toBeNull();
      expect(chord({ key: 'ArrowDown' })).toBeNull();
      expect(chord({ key: 'ArrowLeft', shiftKey: true })).toBeNull();
      expect(chord({ key: 'ArrowDown', shiftKey: true, ctrlKey: true })).toBeNull();
      expect(chord({ key: ' ', shiftKey: true, metaKey: true })).toBeNull();
      expect(chord({ key: ' ', shiftKey: true, altKey: true })).toBeNull();
      expect(chord({ key: ' ', shiftKey: true, isComposing: true })).toBeNull();
      expect(selectionChord(withAltGraph(new KeyboardEvent('keydown', { key: 'ArrowDown', shiftKey: true })), false)).toBeNull();
    });
  });

  describe('Shift+Space', () => {
    it('on a row toggles it and anchors it', async () => {
      const table = await mount();
      focusRow(table, '2');

      expect(shiftSpace()).toBe(false);
      expect(selected(table)).toEqual(['2']);

      shiftDown();
      shiftDown();
      expect(selected(table)).toEqual(['2', '3', '4']);
    });

    it('on a cell toggles its row', async () => {
      const table = await mount();
      focusElement(table, table.row('2').querySelector<HTMLElement>('td.subject')!);

      expect(shiftSpace()).toBe(false);

      expect(selected(table)).toEqual(['2']);
    });

    it('deselect keeps the anchor', async () => {
      const table = await mount();
      focusRow(table, '2');
      shiftSpace();
      shiftSpace();
      expect(selected(table)).toEqual([]);

      shiftDown();

      expect(selected(table)).toEqual(['2', '3']);
    });

    it('on a group header is not consumed', async () => {
      const table = await mount(grouped);
      focusElement(table, table.groupHeader(0));

      expect(shiftSpace()).toBe(true);

      expect(selected(table)).toEqual([]);
    });

    it('held toggles once', async () => {
      const table = await mount();
      focusRow(table, '1');

      expect(shiftSpace()).toBe(false);
      expect(shiftSpace({ repeat: true })).toBe(false);

      expect(selected(table)).toEqual(['1']);
    });

    it('announces the count', async () => {
      const table = await mount();
      focusRow(table, '1');

      shiftSpace();

      expect(spoken()).toEqual(['1 work package selected.']);
    });
  });

  describe('Shift+Arrow', () => {
    it('Down twice from an anchored row selects three', async () => {
      const table = await mount();
      table.click('1');
      focusRow(table, '1');

      expect(shiftDown()).toBe(false);
      shiftDown();

      expect(selected(table)).toEqual(['1', '2', '3']);
      expect(table.row('3')).toHaveFocus();
    });

    it('Up after extending down shrinks', async () => {
      const table = await mount();
      table.click('1');
      focusRow(table, '1');
      shiftDown();
      shiftDown();

      shiftUp();

      expect(selected(table)).toEqual(['1', '2']);
    });

    it('reverses past the anchor', async () => {
      const table = await mount();
      table.click('3');
      focusRow(table, '3');
      shiftDown();
      shiftUp();
      shiftUp();
      shiftUp();

      expect(selected(table)).toEqual(['1', '2', '3']);
    });

    it('range includes the hidden children of a collapsed parent', async () => {
      const table = await mount({
        workPackages: [{ id: '1', children: [{ id: '2' }] }, { id: '2', ancestors: [{ id: '1' }] }, { id: '3' }],
        showHierarchies: true,
      });
      table.injector.get(WorkPackageViewHierarchiesService).collapse('1');
      await waitFor(() => expect(table.row('2')).not.toBeVisible());
      table.click('1');
      focusRow(table, '1');

      shiftDown();

      expect(table.row('3')).toHaveFocus();
      expect(selected(table)).toEqual(['1', '2', '3']);
    });

    it('range includes both occurrences of a work package once', async () => {
      const table = buildTable({
        productionMarkup: true,
        workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        configuration: { keyboardNavigationEnabled: true },
      });
      harnesses.push(table);
      table.expand('1', 'relationsOfTypeFollows');
      await table.render();
      table.click('1');
      focusRow(table, '1');

      shiftDown();
      shiftDown();

      expect(table.row('2')).toHaveFocus();
      expect(selected(table)).toEqual(['1', '2']);
    });

    describe('onto structural rows', () => {
      it('Down onto a group header moves focus but leaves the range unchanged', async () => {
        const table = await mount(grouped);
        table.click('2');
        focusRow(table, '2');

        expect(shiftDown()).toBe(false);

        expect(table.groupHeader(1)).toHaveFocus();
        expect(selected(table)).toEqual(['2']);
      });

      it('continuing onto the next eligible row extends to it', async () => {
        const table = await mount(grouped);
        table.click('2');
        focusRow(table, '2');
        shiftDown();

        shiftDown();

        expect(table.row('3')).toHaveFocus();
        expect(selected(table)).toEqual(['2', '3']);
      });

      it('consecutive structural stops leave the range unchanged', async () => {
        const table = await mount(groupedWithSums);
        table.click('2');
        focusRow(table, '2');

        shiftDown();
        expect(table.row('2').nextElementSibling).toHaveFocus();
        expect(selected(table)).toEqual(['2']);

        shiftDown();
        expect(table.groupHeader(1)).toHaveFocus();
        expect(selected(table)).toEqual(['2']);
      });
    });

    describe('without an anchor', () => {
      it('first Down replaces the selection with the row reached and anchors it', async () => {
        const table = await mount();
        table.click('1');
        table.click('4', { ctrlKey: true });
        fireEvent.keyDown(document.body, { key: 'Escape' });
        focusRow(table, '2');

        shiftDown();
        expect(selected(table)).toEqual(['3']);

        shiftDown();
        expect(selected(table)).toEqual(['3', '4']);
      });

      it('first Up replaces the selection with the row reached and anchors it', async () => {
        const table = await mount();
        focusRow(table, '3');

        shiftUp();
        expect(selected(table)).toEqual(['2']);

        shiftUp();
        expect(selected(table)).toEqual(['1', '2']);
      });

      it('Select All from the column header then Down collapses to the first eligible row', async () => {
        const table = await mount();
        focusKey(table, headerRowKey);
        ctrlA();
        expect(selected(table)).toEqual(['1', '2', '3', '4', '5']);

        shiftDown();

        expect(table.row('1')).toHaveFocus();
        expect(selected(table)).toEqual(['1']);
      });
    });

    describe('at the edges', () => {
      it('Up on the first body row with the header absent changes nothing but is consumed', async () => {
        const table = await mount({ ...flat, productionMarkup: false });
        table.click('1');
        focusRow(table, '1');

        announceSpy.mockClear();

        expect(shiftUp()).toBe(false);

        expect(table.row('1')).toHaveFocus();
        expect(selected(table)).toEqual(['1']);
        expect(announceSpy).not.toHaveBeenCalled();
      });

      it('held Down keeps extending', async () => {
        const table = await mount();
        table.click('1');
        focusRow(table, '1');

        shiftDown();
        shiftDown({ repeat: true });
        shiftDown({ repeat: true });

        expect(selected(table)).toEqual(['1', '2', '3', '4']);
      });
    });

    it('same-count replacement announces', async () => {
      const table = await mount();
      table.click('2');
      table.click('1', { shiftKey: true });
      focusRow(table, '2');
      announceSpy.mockClear();

      shiftDown();

      expect(selected(table)).toEqual(['2', '3']);
      expect(spoken()).toEqual(['2 work packages selected.']);
    });
  });

  describe('Select All', () => {
    it('Ctrl+A on a row selects the page and anchors that occurrence', async () => {
      const table = await mount();
      focusRow(table, '3');

      expect(ctrlA()).toBe(false);
      expect(selected(table)).toEqual(['1', '2', '3', '4', '5']);

      table.click('5', { shiftKey: true });
      expect(selected(table)).toEqual(['3', '4', '5']);
    });

    it('Ctrl+A on the header, a group header, sums and totals selects the page with no anchor', async () => {
      const table = await mount(groupedWithSums);
      const structural = [
        () => focusKey(table, headerRowKey),
        () => focusElement(table, table.groupHeader(0)),
        () => focusElement(table, table.row('2').nextElementSibling as HTMLElement),
        () => focusKey(table, totalsRowKey),
      ];

      structural.forEach((focus) => {
        table.selection.reset();
        focus();

        expect(ctrlA()).toBe(false);

        expect(selected(table)).toEqual(['1', '2', '3', '4']);
        table.click('4', { shiftKey: true });
        expect(selected(table)).toEqual(['4']);
      });
    });

    it('Ctrl+A from a structural row clears an existing anchor', async () => {
      const table = await mount();
      table.click('3');
      focusKey(table, headerRowKey);

      ctrlA();
      table.click('5', { shiftKey: true });

      expect(selected(table)).toEqual(['5']);
    });

    it('Ctrl+A dedups a work package rendered twice', async () => {
      const table = buildTable({
        productionMarkup: true,
        workPackages: [{ id: '1' }, { id: '2' }, { id: '3' }],
        relations: [{ from: '1', to: '2', type: 'follows', reverseType: 'precedes' }],
        columns: ['id', 'subject', { id: 'relationsOfTypeFollows', relationType: 'follows' }],
        configuration: { keyboardNavigationEnabled: true },
      });
      harnesses.push(table);
      table.expand('1', 'relationsOfTypeFollows');
      await table.render();
      focusRow(table, '1');

      ctrlA();

      expect(selected(table)).toEqual(['1', '2', '3']);
    });

    it('Ctrl+A on a page with only group headers is not consumed', async () => {
      const table = await mount(grouped);
      focusElement(table, table.groupHeader(0));
      vi.spyOn(table.table, 'renderedRows', 'get')
        .mockReturnValue(table.querySpace.tableRendered.value!.filter((row) => row.workPackageId === null));

      expect(ctrlA()).toBe(true);

      expect(selected(table)).toEqual([]);
    });

    it('Ctrl+Shift+A is not consumed', async () => {
      const table = await mount();
      focusRow(table, '1');

      expect(ctrlA({ shiftKey: true })).toBe(true);

      expect(selected(table)).toEqual([]);
    });

    it('Ctrl+A with AltGraph or during composition is not consumed', async () => {
      const table = await mount();
      focusRow(table, '1');

      const target = document.activeElement!;
      expect(fireEvent(target, withAltGraph(createEvent.keyDown(target, { key: 'a', code: 'KeyA', ctrlKey: true })))).toBe(true);
      expect(ctrlA({ isComposing: true })).toBe(true);

      expect(selected(table)).toEqual([]);
    });

    it('Ctrl+A on a non-Latin layout selects all', async () => {
      const table = await mount();
      focusRow(table, '1');

      expect(press('ф', { code: 'KeyA', ctrlKey: true })).toBe(false);

      expect(selected(table)).toEqual(['1', '2', '3', '4', '5']);
    });

    it('Meta+A on Apple selects all and Ctrl+A on Apple does not', async () => {
      pretendPlatform('macOS');
      const table = await mount();
      focusRow(table, '1');

      expect(ctrlA()).toBe(true);
      expect(selected(table)).toEqual([]);

      expect(press('a', { code: 'KeyA', metaKey: true })).toBe(false);
      expect(selected(table)).toEqual(['1', '2', '3', '4', '5']);
    });

    it('announces the page count', async () => {
      const table = await mount();
      focusRow(table, '1');

      ctrlA();

      expect(spoken()).toEqual(['All 5 work packages on this page selected.']);
    });

    it('held announces once', async () => {
      const table = await mount();
      focusRow(table, '1');

      ctrlA();
      ctrlA({ repeat: true });
      ctrlA({ repeat: true });

      expect(spoken()).toEqual(['All 5 work packages on this page selected.']);
    });

    it('announces again when everything is already selected', async () => {
      const table = await mount();
      focusRow(table, '1');
      ctrlA();
      announceSpy.mockClear();

      ctrlA();

      expect(spoken()).toEqual(['All 5 work packages on this page selected.']);
    });

    it('does not select the draft of an open create row', async () => {
      const table = await mount();
      table.addInlineCreateRow();
      focusRow(table, '1');

      ctrlA();

      expect(selected(table)).toEqual(['1', '2', '3', '4', '5']);
    });
  });

  describe('inside the create row', () => {
    it('Shift+Space in an input is untouched', async () => {
      const table = await mount();
      const row = table.addInlineCreateRow();
      const input = document.createElement('input');
      row.append(input);
      input.focus();

      expect(shiftSpace()).toBe(true);

      expect(selected(table)).toEqual([]);
    });
  });

  describe('pointer and keyboard parity', () => {
    it('pointer then keyboard then pointer matches pointer only', async () => {
      const keyboard = await mount();
      keyboard.click('1');
      focusRow(keyboard, '1');
      shiftDown();
      shiftDown();
      keyboard.click('5', { shiftKey: true });

      const pointer = await mount();
      pointer.click('1');
      pointer.click('3', { shiftKey: true });
      pointer.click('5', { shiftKey: true });

      expect(selected(keyboard)).toEqual(selected(pointer));
      keyboard.click('2', { shiftKey: true });
      pointer.click('2', { shiftKey: true });
      expect(selected(keyboard)).toEqual(selected(pointer));
    });

    it('an Escape-cleared anchor behaves like a Shift-click on the same row', async () => {
      const escape = () => fireEvent.keyDown(document.body, { key: 'Escape' });

      const keyboard = await mount();
      keyboard.click('1');
      keyboard.click('4', { ctrlKey: true });
      escape();
      focusRow(keyboard, '2');
      shiftDown();
      const afterKeyboard = selected(keyboard);
      keyboard.click('5', { shiftKey: true });
      const nextAfterKeyboard = selected(keyboard);
      await keyboard.destroy();

      const pointer = await mount();
      pointer.click('1');
      pointer.click('4', { ctrlKey: true });
      escape();
      pointer.click('3', { shiftKey: true });
      const afterPointer = selected(pointer);
      pointer.click('5', { shiftKey: true });

      expect(afterKeyboard).toEqual(afterPointer);
      expect(nextAfterKeyboard).toEqual(selected(pointer));
    });
  });
});
