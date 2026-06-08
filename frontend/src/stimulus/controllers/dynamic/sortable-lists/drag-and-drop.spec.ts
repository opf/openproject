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

import { extractClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import {
  acceptsSortableItemType,
  buildMoveFormData,
  isSortableItemData,
  isSortableListData,
  resolveFallbackDropTarget,
  resolveItemType,
  resolveListAppendPreviousItemId,
  resolveListData,
  resolvePreviousSortableItemId,
  sortableItemData,
  sortableListData,
} from './drag-and-drop';

describe('sortable lists drag and drop helpers', () => {
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

  describe('isSortableItemData', () => {
    it('accepts backlogs item data', () => {
      expect(isSortableItemData(sortableItemData({ type: 'work_package', itemId: '42' }))).toBe(true);
    });

    it('rejects lookalike data from another drag source', () => {
      expect(isSortableItemData({ type: 'work_package', itemId: '42' })).toBe(false);
    });

    it('rejects data without an item id', () => {
      expect(isSortableItemData({ type: 'work_package' })).toBe(false);
    });

    it('rejects data with a blank item id', () => {
      expect(isSortableItemData(sortableItemData({ type: 'work_package', itemId: '' }))).toBe(false);
    });
  });

  describe('isSortableListData', () => {
    it('accepts sortable list data', () => {
      expect(isSortableListData(sortableListData({ type: 'sprint', listId: '42' }))).toBe(true);
    });

    it('rejects lookalike data from another drop target', () => {
      expect(isSortableListData({ type: 'sprint', listId: '42' })).toBe(false);
    });
  });

  describe('sortableItemData', () => {
    it('uses the item type as the public source type', () => {
      const data = sortableItemData({ type: 'work_package', itemId: '42' });

      expect(data.type).toEqual('work_package');
      expect(data.itemId).toEqual('42');
      expect(isSortableItemData(data)).toBe(true);
    });

    it('includes a move URL when the sortable item has one', () => {
      expect(sortableItemData({ type: 'work_package', itemId: '42', moveUrl: '/move' })).toEqual(expect.objectContaining({
        itemId: '42',
        moveUrl: '/move',
        type: 'work_package',
      }));
    });
  });

  describe('acceptsSortableItemType', () => {
    it('allows drops when the controller has no accepted type filter', () => {
      expect(acceptsSortableItemType({ acceptedType: null, type: 'work_package' })).toBe(true);
    });

    it('allows drops when the source type matches the accepted type', () => {
      expect(acceptsSortableItemType({ acceptedType: 'work_package', type: 'work_package' })).toBe(true);
    });

    it('rejects drops when the source type does not match the accepted type', () => {
      expect(acceptsSortableItemType({ acceptedType: 'work_package', type: 'meeting_agenda_item' })).toBe(false);
    });
  });

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

  describe('buildMoveFormData', () => {
    it('serializes list data and previous item id for the move endpoint', () => {
      const data = buildMoveFormData({ type: 'backlog_bucket', listId: '7', previousItemId: '12' });

      expect(data.get('list_type')).toEqual('backlog_bucket');
      expect(data.get('list_id')).toEqual('7');
      expect(data.get('prev_id')).toEqual('12');
    });

    it('serializes a top-of-list move as an empty previous item id', () => {
      const data = buildMoveFormData({ type: 'inbox', listId: null, previousItemId: null });

      expect(data.get('list_type')).toEqual('inbox');
      expect(data.get('list_id')).toEqual('');
      expect(data.get('prev_id')).toEqual('');
    });
  });

  describe('resolvePreviousSortableItemId', () => {
    it('uses the target item as previous item when dropping on the bottom edge', () => {
      const target = itemRow('3').querySelector<HTMLElement>('article')!;

      expect(resolvePreviousSortableItemId({ sourceItemId: '1', targetItem: target, closestEdge: 'bottom' })).toEqual('3');
    });

    it('uses the row item as previous item when the drop target is the row', () => {
      const target = itemRow('3');

      expect(resolvePreviousSortableItemId({ sourceItemId: '1', targetItem: target, closestEdge: 'bottom' })).toEqual('3');
    });

    it('uses the previous row item when dropping on the top edge', () => {
      const list = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      list.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: target, closestEdge: 'top' })).toEqual('1');
    });

    it('uses the previous row item when dropping on the top edge of a row target', () => {
      const list = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');

      list.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: targetRow, closestEdge: 'top' })).toEqual('1');
    });

    it('treats a missing closest edge as dropping before the target item', () => {
      const list = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      list.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: target, closestEdge: null })).toEqual('1');
    });

    it('uses a truncation marker when dropping before a tail item', () => {
      const list = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('6');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      list.append(first, showMoreRow('5'), targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: target, closestEdge: 'top' })).toEqual('5');
    });

    it('skips the source item and uses a preceding truncation marker when resolving the previous item', () => {
      const list = document.createElement('ul');
      const first = itemRow('1');
      const source = itemRow('2');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      list.append(first, showMoreRow(), source, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: target, closestEdge: 'top' })).toEqual('hidden-item');
    });

    it('returns null when dropping before the first item', () => {
      const target = itemRow('1').querySelector<HTMLElement>('article')!;

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: target, closestEdge: 'top' })).toBeNull();
    });
  });

  describe('resolveListData', () => {
    it('reads the nearest list type and id', () => {
      const list = document.createElement('ul');
      const row = itemRow('1');
      const item = row.querySelector<HTMLElement>('article')!;

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'sprint');
      list.setAttribute('data-sortable-lists-list-id', '12');
      list.appendChild(row);

      expect(resolveListData(item)).toEqual(expect.objectContaining({ type: 'sprint', listId: '12' }));
    });

    it('uses null as the list id for lists without an id', () => {
      const list = document.createElement('ul');

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'inbox');

      expect(resolveListData(list)).toEqual(expect.objectContaining({ type: 'inbox', listId: null }));
    });
  });

  describe('resolveFallbackDropTarget', () => {
    function input({ clientX = 10, clientY = 10 } = {}) {
      return {
        altKey: false,
        button: 0,
        buttons: 0,
        ctrlKey: false,
        metaKey: false,
        shiftKey: false,
        clientX,
        clientY,
        pageX: clientX,
        pageY: clientY,
      };
    }

    function rect():DOMRect {
      return {
        top: 0,
        bottom: 100,
        left: 0,
        right: 100,
        width: 100,
        height: 100,
        x: 0,
        y: 0,
        toJSON: () => ({}),
      };
    }

    function stubElementFromPoint(element:Element) {
      Object.defineProperty(document, 'elementFromPoint', {
        configurable: true,
        value: vi.fn(() => element),
      });
    }

    function stubElementsFromPoint(elements:Element[]) {
      Object.defineProperty(document, 'elementsFromPoint', {
        configurable: true,
        value: vi.fn(() => elements),
      });
    }

    afterEach(() => {
      vi.restoreAllMocks();
      document.body.replaceChildren();
    });

    it('resolves an item at the drop coordinates', () => {
      const root = document.createElement('div');
      const list = document.createElement('div');
      const row = itemRow('42');
      const item = row.querySelector<HTMLElement>('article')!;

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'backlog_bucket');
      list.setAttribute('data-sortable-lists-list-id', '7');
      list.appendChild(row);
      root.appendChild(list);
      document.body.appendChild(root);
      stubElementFromPoint(item);
      vi.spyOn(row, 'getBoundingClientRect').mockReturnValue(rect());

      const target = resolveFallbackDropTarget({
        input: input({ clientY: 90 }),
        root,
      });

      expect(target?.element).toBe(row);
      expect(target?.isItem).toBe(true);
      expect(target?.data.itemId).toEqual('42');
      expect(extractClosestEdge(target!.data)).toEqual('bottom');
    });

    it('skips drag overlay elements and resolves the underlying item', () => {
      const root = document.createElement('div');
      const list = document.createElement('div');
      const row = itemRow('42');
      const item = row.querySelector<HTMLElement>('article')!;
      const dragOverlay = document.createElement('div');

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'backlog_bucket');
      list.setAttribute('data-sortable-lists-list-id', '7');
      list.appendChild(row);
      root.appendChild(list);
      document.body.append(root, dragOverlay);
      stubElementFromPoint(dragOverlay);
      stubElementsFromPoint([dragOverlay, item]);
      vi.spyOn(row, 'getBoundingClientRect').mockReturnValue(rect());

      const target = resolveFallbackDropTarget({
        input: input({ clientY: 90 }),
        root,
      });

      expect(target?.element).toBe(row);
      expect(target?.isItem).toBe(true);
      expect(target?.data.itemId).toEqual('42');
    });

    it('resolves a list at the drop coordinates when no item is under the pointer', () => {
      const root = document.createElement('div');
      const list = document.createElement('div');
      const header = document.createElement('div');

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'backlog_bucket');
      list.setAttribute('data-sortable-lists-list-id', '7');
      list.appendChild(header);
      root.appendChild(list);
      document.body.appendChild(root);
      stubElementFromPoint(header);

      const target = resolveFallbackDropTarget({
        input: input(),
        root,
      });

      expect(target?.element).toBe(list);
      expect(target?.isItem).toBe(false);
      expect(isSortableListData(target!.data)).toBe(true);
      expect(target?.data.type).toEqual('backlog_bucket');
      expect(target?.data.listId).toEqual('7');
    });

    it('resolves the containing list instead of the dragged source item', () => {
      const root = document.createElement('div');
      const list = document.createElement('div');
      const row = itemRow('42');
      const item = row.querySelector<HTMLElement>('article')!;

      list.setAttribute('data-sortable-lists-target', 'list');
      list.setAttribute('data-sortable-lists-list-type', 'backlog_bucket');
      list.setAttribute('data-sortable-lists-list-id', '7');
      list.appendChild(row);
      root.appendChild(list);
      document.body.appendChild(root);
      stubElementFromPoint(item);

      const target = resolveFallbackDropTarget({
        input: input(),
        root,
        sourceElement: row,
      });

      expect(target?.element).toBe(list);
      expect(target?.isItem).toBe(false);
      expect(isSortableListData(target!.data)).toBe(true);
      expect(target?.data.type).toEqual('backlog_bucket');
      expect(target?.data.listId).toEqual('7');
    });

    it('returns null when the drop coordinates are outside the backlogs root', () => {
      const root = document.createElement('div');
      const outside = document.createElement('div');

      document.body.append(root, outside);
      stubElementFromPoint(outside);

      expect(resolveFallbackDropTarget({
        input: input(),
        root,
      })).toBeNull();
    });
  });

  describe('resolveListAppendPreviousItemId', () => {
    it('returns the last item in a list while skipping the source and truncation marker rows', () => {
      const list = document.createElement('ul');

      list.append(itemRow('1'), showMoreRow(), itemRow('2'), itemRow('3'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '3', list })).toEqual('2');
    });

    it('returns null when the list has no other items', () => {
      const list = document.createElement('ul');

      list.append(itemRow('1'));

      expect(resolveListAppendPreviousItemId({ sourceItemId: '1', list })).toBeNull();
    });
  });
});
