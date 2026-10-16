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

import { captureRowPositions, reorderRows, restoreRowPositions, rowsRemainAt } from './row-mutations';
import { rowOf } from './list-dom';

describe('sortable lists row mutations', () => {
  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.appendChild(item);

    return row;
  }

  function divItemRow(id:string):HTMLDivElement {
    const row = document.createElement('div');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    return row;
  }

  function showMoreRow(previousItemId = 'hidden-item'):HTMLLIElement {
    const row = document.createElement('li');

    row.setAttribute('data-sortable-lists-prev-item-id', previousItemId);

    return row;
  }

  function listElement():HTMLUListElement {
    const list = document.createElement('ul');

    list.setAttribute('data-sortable-lists-target', 'list');

    return list;
  }

  function itemIdOrder(list:HTMLElement):string[] {
    return Array.from(list.querySelectorAll('[data-sortable-lists--item-id-value]'))
      .map((element) => element.getAttribute('data-sortable-lists--item-id-value')!);
  }

  describe('reorderRows', () => {
    it('moves a row to sit immediately after the previous item anchor', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [one], rowsContainer: list, previousItemId: '2' });

      expect(itemIdOrder(list)).toEqual(['2', '1', '3']);
    });

    it('moves a row to the top of the list before the first existing row', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });

      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);
    });

    it('reorders rows that are neither <ul> nor <li> under any container element', () => {
      const rowsContainer = document.createElement('div');
      const [one, two, three] = ['1', '2', '3'].map(divItemRow);

      rowsContainer.append(one, two, three);
      reorderRows({ rows: [three], rowsContainer, previousItemId: '1' });

      expect(itemIdOrder(rowsContainer)).toEqual(['1', '3', '2']);
    });

    it('resolves the row that holds a nested element via rowOf', () => {
      const rowsContainer = document.createElement('ul');
      const row = itemRow('9');
      const inner = row.querySelector<HTMLElement>('article')!;

      rowsContainer.append(row);

      expect(rowOf(rowsContainer, inner)).toBe(row);
      expect(rowOf(rowsContainer, row)).toBe(row);
      expect(rowOf(rowsContainer, document.createElement('div'))).toBeNull();
    });

    it('inserts a moved group after the anchor preserving their order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      reorderRows({ rows: [three, four], rowsContainer: list, previousItemId: '1' });

      expect(itemIdOrder(list)).toEqual(['1', '3', '4', '2']);
    });

    it('anchors on the outer list row, not a nested item with a colliding id', () => {
      // Section and custom-field ids come from different tables, so a field
      // nested inside section "1" may carry the same id as section "2".
      // Resolving section "2" as the anchor must match the outer row, never
      // descend into the nested field list.
      const list = listElement();
      const [sectionOne, sectionTwo, sectionThree] = ['1', '2', '3'].map(divItemRow);
      const nestedList = listElement();
      const collidingField = itemRow('2');

      nestedList.append(collidingField);
      sectionOne.append(nestedList);
      list.append(sectionOne, sectionTwo, sectionThree);

      reorderRows({ rows: [sectionThree], rowsContainer: list, previousItemId: '2' });

      expect(Array.from(list.children)).toEqual([sectionOne, sectionTwo, sectionThree]);
    });

    it('anchors on a truncation marker row when the previous item is hidden', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);
      const marker = showMoreRow('hidden');

      list.append(three, one, marker, two);
      reorderRows({ rows: [three], rowsContainer: list, previousItemId: 'hidden' });

      expect(three.previousElementSibling).toBe(marker);
      expect(itemIdOrder(list)).toEqual(['1', '3', '2']);
    });
  });

  describe('captureRowPositions / restoreRowPositions', () => {
    // restoreRowPositions guards on the captured parent being connected, so these
    // lists are mounted in the document to reflect the live frame they run against.
    afterEach(() => {
      document.body.replaceChildren();
    });

    it('restores a row to its original position after an optimistic move', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const snapshot = captureRowPositions([three]);

      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });
      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3']);
    });

    it('restores a multi-row group to its original order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      document.body.append(list);
      const snapshot = captureRowPositions([two, three]);

      reorderRows({ rows: [two, three], rowsContainer: list, previousItemId: '4' });
      expect(itemIdOrder(list)).toEqual(['1', '4', '2', '3']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3', '4']);
    });

    it('falls back to appending when the captured next sibling is stale', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const snapshot = captureRowPositions([one]);
      two.remove();

      expect(() => restoreRowPositions(snapshot)).not.toThrow();
      expect(itemIdOrder(list)).toEqual(['1']);
    });

    it('does not restore a row into a captured parent that has detached', () => {
      const list = listElement();
      const destination = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list, destination);
      const snapshot = captureRowPositions([one]);

      // Optimistic move relocates the row into a live destination list.
      destination.append(one);
      // A mid-flight list-refresh morph detaches the original list.
      list.remove();

      restoreRowPositions(snapshot);

      // The row is not pulled back into the detached list; it stays live.
      expect(one.isConnected).toBe(true);
      expect(itemIdOrder(destination)).toEqual(['1']);
    });
  });

  describe('aria-rowindex upkeep', () => {
    afterEach(() => {
      document.body.replaceChildren();
    });

    function indexedRow(id:string, rowindex:number):HTMLDivElement {
      const row = divItemRow(id);
      row.setAttribute('role', 'row');
      row.setAttribute('aria-rowindex', String(rowindex));
      return row;
    }

    function rowIndices(rowsContainer:HTMLElement):(string|null)[] {
      return Array.from(rowsContainer.children).map((row) => row.getAttribute('aria-rowindex'));
    }

    it('renumbers aria-rowindex in DOM order after a reorder, keeping the page offset', () => {
      const rowsContainer = document.createElement('div');
      const [a, b, c] = [indexedRow('a', 5), indexedRow('b', 6), indexedRow('c', 7)];

      rowsContainer.append(a, b, c);
      reorderRows({ rows: [c], rowsContainer, previousItemId: null });

      expect(itemIdOrder(rowsContainer)).toEqual(['c', 'a', 'b']);
      expect(rowIndices(rowsContainer)).toEqual(['5', '6', '7']);
    });

    it('leaves rows without aria-rowindex untouched', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });

      expect(rowIndices(list)).toEqual([null, null, null]);
    });

    it('skips rows that carry no index, such as truncation markers', () => {
      const rowsContainer = document.createElement('div');
      const [a, b] = [indexedRow('a', 2), indexedRow('b', 3)];
      const marker = showMoreRow();

      rowsContainer.append(a, b, marker);
      reorderRows({ rows: [b], rowsContainer, previousItemId: null });

      expect(rowIndices(rowsContainer)).toEqual(['2', '3', null]);
    });

    it('renumbers after a rollback restores the original order, keeping the page offset', () => {
      const rowsContainer = document.createElement('div');
      const [a, b, c] = [indexedRow('a', 5), indexedRow('b', 6), indexedRow('c', 7)];

      rowsContainer.append(a, b, c);
      document.body.append(rowsContainer);
      const rollback = captureRowPositions([c]);
      reorderRows({ rows: [c], rowsContainer, previousItemId: null });
      restoreRowPositions(rollback);

      expect(itemIdOrder(rowsContainer)).toEqual(['a', 'b', 'c']);
      expect(rowIndices(rowsContainer)).toEqual(['5', '6', '7']);
    });
  });

  describe('rowsRemainAt', () => {
    afterEach(() => {
      document.body.replaceChildren();
    });

    it('is true while rows still sit at their captured placement', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);

      reorderRows({ rows: [three], rowsContainer: list, previousItemId: null });
      const optimistic = captureRowPositions([three]);

      expect(rowsRemainAt(optimistic)).toBe(true);
    });

    it('is true when every row of a multi-row group remains at its captured placement', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      document.body.append(list);

      reorderRows({ rows: [two, three], rowsContainer: list, previousItemId: '4' });
      const optimistic = captureRowPositions([two, three]);

      expect(rowsRemainAt(optimistic)).toBe(true);
    });

    it('is false once a captured row has been removed', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const optimistic = captureRowPositions([two]);

      // A morph removing the row (e.g. it moved lists server-side) must not be
      // undone by a later rollback re-inserting the detached node.
      two.remove();

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('is false once a captured row has been repositioned', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const optimistic = captureRowPositions([one]);

      list.append(one);

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('is false when a sibling was inserted at the captured next-sibling slot', () => {
      const list = listElement();
      const [one, two] = ['1', '2'].map(itemRow);

      list.append(one, two);
      document.body.append(list);
      const optimistic = captureRowPositions([one]);

      // Deliberately conservative: any churn around the row counts as a morph
      // owning the region, so the rollback yields to the fresher server state.
      one.after(itemRow('99'));

      expect(rowsRemainAt(optimistic)).toBe(false);
    });

    it('checks every row of a multi-row group', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      document.body.append(list);
      const optimistic = captureRowPositions([one, two]);

      list.append(one);

      expect(rowsRemainAt(optimistic)).toBe(false);
    });
  });
});
