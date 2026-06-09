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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  captureRowPositions,
  reorderRows,
  resolveItemType,
  resolveListAppendPreviousItemId,
  restoreRowPositions,
} from './list-dom';

describe('sortable lists DOM helpers', () => {
  function itemRow(id:string):HTMLLIElement {
    const row = document.createElement('li');
    const item = document.createElement('article');

    row.setAttribute('data-sortable-lists--item-id-value', id);
    row.appendChild(item);

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

  describe('resolveItemType', () => {
    it('reads the item type Stimulus value', () => {
      const item = itemRow('1');

      item.setAttribute('data-sortable-lists--item-type-value', 'work_package');

      expect(resolveItemType(item)).toEqual('work_package');
    });

    it('uses a generic item type when no item type value is present', () => {
      expect(resolveItemType(itemRow('1'))).toEqual('item');
    });
  });

  describe('resolveListAppendPreviousItemId', () => {
    it('returns the last item in a list while skipping the source and truncation marker rows', () => {
      const list = listElement();

      list.append(itemRow('1'), showMoreRow(), itemRow('2'), itemRow('3'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '3', list })).toEqual('2');
    });

    it('returns null when the list has no other items', () => {
      const list = listElement();

      list.append(itemRow('1'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '1', list })).toBeNull();
    });
  });

  describe('reorderRows', () => {
    it('moves a row to sit immediately after the previous item anchor', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [one], list, previousItemId: '2' });

      expect(itemIdOrder(list)).toEqual(['2', '1', '3']);
    });

    it('moves a row to the top of the list before the first existing row', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      reorderRows({ rows: [three], list, previousItemId: null });

      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);
    });

    it('keeps a top-of-list move inside a nested list element instead of escaping it', () => {
      const list = document.createElement('div');
      const inner = document.createElement('ul');
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.setAttribute('data-sortable-lists-target', 'list');
      inner.append(one, two, three);
      list.append(inner);

      reorderRows({ rows: [three], list, previousItemId: null });

      expect(three.parentElement).toBe(inner);
      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);
    });

    it('inserts a moved group after the anchor preserving their order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      reorderRows({ rows: [three, four], list, previousItemId: '1' });

      expect(itemIdOrder(list)).toEqual(['1', '3', '4', '2']);
    });

    it('anchors on a truncation marker row when the previous item is hidden', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);
      const marker = showMoreRow('hidden');

      list.append(three, one, marker, two);
      reorderRows({ rows: [three], list, previousItemId: 'hidden' });

      expect(three.previousElementSibling).toBe(marker);
      expect(itemIdOrder(list)).toEqual(['1', '3', '2']);
    });
  });

  describe('captureRowPositions / restoreRowPositions', () => {
    it('restores a row to its original position after an optimistic move', () => {
      const list = listElement();
      const [one, two, three] = ['1', '2', '3'].map(itemRow);

      list.append(one, two, three);
      const snapshot = captureRowPositions([three]);

      reorderRows({ rows: [three], list, previousItemId: null });
      expect(itemIdOrder(list)).toEqual(['3', '1', '2']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3']);
    });

    it('restores a multi-row group to its original order', () => {
      const list = listElement();
      const [one, two, three, four] = ['1', '2', '3', '4'].map(itemRow);

      list.append(one, two, three, four);
      const snapshot = captureRowPositions([two, three]);

      reorderRows({ rows: [two, three], list, previousItemId: '4' });
      expect(itemIdOrder(list)).toEqual(['1', '4', '2', '3']);

      restoreRowPositions(snapshot);
      expect(itemIdOrder(list)).toEqual(['1', '2', '3', '4']);
    });
  });
});
