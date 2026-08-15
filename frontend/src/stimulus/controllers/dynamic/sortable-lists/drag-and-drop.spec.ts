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

import { vi } from 'vitest';

import { attachClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  buildMoveFormData,
  isItemFromRoot,
  isSortableItemData,
  isSortableListData,
  resolveDropIntent,
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

  function divRow(id:string):HTMLDivElement {
    const row = document.createElement('div');
    row.setAttribute('data-sortable-lists--item-id-value', id);
    return row;
  }

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

  afterEach(() => {
    vi.restoreAllMocks();
    document.body.replaceChildren();
  });

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

    it('carries the root element on the item payload when provided', () => {
      const root = document.createElement('div');
      const data = sortableItemData({ itemId: '1', type: 'work_package', rootElement: root });

      expect(data.rootElement).toBe(root);
      expect(isSortableItemData(data)).toBe(true);
    });

    it('defaults the item payload root element to null', () => {
      const data = sortableItemData({ itemId: '1', type: 'work_package' });

      expect(data.rootElement).toBeNull();
    });
  });

  describe('sortableListData', () => {
    it('carries the rows container on the list payload when provided', () => {
      const rowsContainer = document.createElement('ul');
      const data = sortableListData({ type: 'sprint', listId: '7', rowsContainer: rowsContainer });

      expect(data.rowsContainer).toBe(rowsContainer);
      expect(isSortableListData(data)).toBe(true);
    });

    it('defaults the list payload rows container to null', () => {
      const data = sortableListData({ type: 'sprint', listId: '7' });

      expect(data.rowsContainer).toBeNull();
    });
  });

  describe('isItemFromRoot', () => {
    const root = document.createElement('div');

    it('accepts a sortable item whose rootElement is this root', () => {
      const data = sortableItemData({ itemId: '1', type: 'work_package', rootElement: root });
      expect(isItemFromRoot(root, data)).toBe(true);
    });

    it('rejects a sortable item from another root', () => {
      const data = sortableItemData({ itemId: '1', type: 'work_package', rootElement: document.createElement('div') });
      expect(isItemFromRoot(root, data)).toBe(false);
    });

    it('rejects a sortable item with no root reference', () => {
      const data = sortableItemData({ itemId: '1', type: 'work_package', rootElement: null });
      expect(isItemFromRoot(root, data)).toBe(false);
    });

    it('rejects a null root element', () => {
      const data = sortableItemData({ itemId: '1', type: 'work_package', rootElement: root });
      expect(isItemFromRoot(null, data)).toBe(false);
    });

    it('rejects a non-item payload', () => {
      expect(isItemFromRoot(root, { foo: 'bar' })).toBe(false);
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

    it('appends ordered ids for a batch payload', () => {
      const data = buildMoveFormData({
        listId: '7', previousItemId: '3', type: 'sprint', itemIds: ['12', '9', '15'],
      });

      expect(data.getAll('ids[]')).toEqual(['12', '9', '15']);
      expect(data.get('list_type')).toBe('sprint');
      expect(data.get('list_id')).toBe('7');
      expect(data.get('prev_id')).toBe('3');
    });

    it('omits ids for a singular payload', () => {
      const data = buildMoveFormData({ listId: '7', previousItemId: null, type: 'sprint' });

      expect(data.getAll('ids[]')).toEqual([]);
    });
  });

  describe('resolvePreviousSortableItemId', () => {
    it('uses the target item as previous item when dropping on the bottom edge', () => {
      const rowsContainer = document.createElement('ul');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['1']) }, targetItem: target, closestEdge: 'bottom', rowsContainer })).toEqual('3');
    });

    it('uses the row item as previous item when the drop target is the row', () => {
      const rowsContainer = document.createElement('ul');
      const targetRow = itemRow('3');

      rowsContainer.append(targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['1']) }, targetItem: targetRow, closestEdge: 'bottom', rowsContainer })).toEqual('3');
    });

    it('uses the previous row item when dropping on the top edge', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: target, closestEdge: 'top', rowsContainer })).toEqual('1');
    });

    it('uses the previous row item when dropping on the top edge of a row target', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');

      rowsContainer.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: targetRow, closestEdge: 'top', rowsContainer })).toEqual('1');
    });

    it('treats a missing closest edge as dropping before the target item', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: target, closestEdge: null, rowsContainer })).toEqual('1');
    });

    it('uses a truncation marker when dropping before a tail item', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const targetRow = itemRow('6');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(first, showMoreRow('5'), targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: target, closestEdge: 'top', rowsContainer })).toEqual('5');
    });

    it('skips the source item and uses a preceding truncation marker when resolving the previous item', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const sourceRow = itemRow('2');
      const targetRow = itemRow('3');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(first, showMoreRow(), sourceRow, targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: target, closestEdge: 'top', rowsContainer })).toEqual('hidden-item');
    });

    it('returns null when dropping before the first item', () => {
      const rowsContainer = document.createElement('ul');
      const targetRow = itemRow('1');
      const target = targetRow.querySelector<HTMLElement>('article')!;

      rowsContainer.append(targetRow);

      expect(resolvePreviousSortableItemId({ excludedItems: { type: 'work_package', ids: new Set(['2']) }, targetItem: target, closestEdge: 'top', rowsContainer })).toBeNull();
    });

    it('skips every excluded id when resolving the previous item', () => {
      // rows: A, B, C, D — drop with top edge on D while A and C are excluded
      // (selected): the closest preceding unexcluded item is B.
      const rowsContainer = document.createElement('ul');
      const rowA = itemRow('A');
      const rowB = itemRow('B');
      const rowC = itemRow('C');
      const rowD = itemRow('D');

      rowsContainer.append(rowA, rowB, rowC, rowD);

      const result = resolvePreviousSortableItemId({
        excludedItems: { type: 'work_package', ids: new Set(['A', 'C']) },
        targetItem: rowD,
        closestEdge: 'top',
        rowsContainer,
      });

      expect(result).toBe('B');
    });

    it('refuses an excluded item as bottom-edge anchor', () => {
      // bottom edge on C, but C is excluded: fall through to the sibling walk.
      const rowsContainer = document.createElement('ul');
      const rowA = itemRow('A');
      const rowB = itemRow('B');
      const rowC = itemRow('C');
      const rowD = itemRow('D');

      rowsContainer.append(rowA, rowB, rowC, rowD);

      const result = resolvePreviousSortableItemId({
        excludedItems: { type: 'work_package', ids: new Set(['A', 'C']) },
        targetItem: rowC,
        closestEdge: 'bottom',
        rowsContainer,
      });

      expect(result).toBe('B');
    });

    // Ids are unique per source table, so a same-id row of another type is a
    // legitimate anchor, not a batch member to skip.
    it('does not exclude a same-id row of another type', () => {
      const rowsContainer = document.createElement('ul');
      const collidingRow = itemRow('A');
      collidingRow.setAttribute('data-sortable-lists--item-type-value', 'section');
      const targetRow = itemRow('B');
      targetRow.setAttribute('data-sortable-lists--item-type-value', 'work_package');

      rowsContainer.append(collidingRow, targetRow);

      const result = resolvePreviousSortableItemId({
        excludedItems: { type: 'work_package', ids: new Set(['A']) },
        targetItem: targetRow,
        closestEdge: 'top',
        rowsContainer,
      });

      expect(result).toBe('A');
    });

    // A truncation marker resolves no type, so a bare-id collision there
    // stays excluded.
    it('keeps excluding a truncation marker whose previous item id collides', () => {
      const rowsContainer = document.createElement('ul');
      const first = itemRow('1');
      const marker = showMoreRow('A');
      const targetRow = itemRow('B');

      rowsContainer.append(first, marker, targetRow);

      const result = resolvePreviousSortableItemId({
        excludedItems: { type: 'work_package', ids: new Set(['A']) },
        targetItem: targetRow,
        closestEdge: 'top',
        rowsContainer,
      });

      expect(result).toBe('1');
    });
  });

  describe('resolveDropIntent', () => {
    function dropLocation({
      dropTargets = [],
      clientX = 10,
      clientY = 10,
    }:{
      dropTargets?:{ data:Record<string|symbol, unknown>; element:Element }[];
      clientX?:number;
      clientY?:number;
    } = {}):DragLocationHistory {
      return {
        current: { dropTargets, input: input({ clientX, clientY }) },
      } as unknown as DragLocationHistory;
    }

    function buildList() {
      const root = document.createElement('div');
      const list = document.createElement('ul');

      list.setAttribute('data-controller', 'sortable-lists--list');
      root.appendChild(list);

      return { root, list };
    }

    it('resolves a drop on an item to the position implied by the edge', () => {
      const { root, list } = buildList();
      const source = itemRow('1');
      const target = itemRow('2');

      list.append(source, target);
      document.body.appendChild(root);
      vi.spyOn(target, 'getBoundingClientRect').mockReturnValue(rect());

      const data = attachClosestEdge(sortableItemData({ type: 'work_package', itemId: '2' }), {
        element: target,
        input: input({ clientY: 90 }),
        allowedEdges: ['top', 'bottom'],
      });

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [
            { data, element: target },
            { data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list },
          ],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.listData).toEqual(expect.objectContaining({ type: 'backlog_bucket', listId: '7' }));
      expect(intent?.previousItemId).toEqual('2');
    });

    it('returns null when an item drop has no list target data', () => {
      const { root, list } = buildList();
      const source = itemRow('1');
      const target = itemRow('2');

      list.append(source, target);
      document.body.appendChild(root);
      vi.spyOn(target, 'getBoundingClientRect').mockReturnValue(rect());

      const data = attachClosestEdge(sortableItemData({ type: 'work_package', itemId: '2' }), {
        element: target,
        input: input({ clientY: 90 }),
        allowedEdges: ['top', 'bottom'],
      });

      const intent = resolveDropIntent({
        location: dropLocation({ dropTargets: [{ data, element: target }] }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });

    it('appends to the list when the drop target is the list itself', () => {
      const { root, list } = buildList();
      const sourceList = document.createElement('ul');
      const source = itemRow('1');

      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      list.append(itemRow('4'), itemRow('5'));
      root.append(sourceList);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.listData).toEqual(expect.objectContaining({ type: 'backlog_bucket', listId: '7' }));
      expect(intent?.previousItemId).toEqual('5');
    });

    // A confined item's foreign-list targets stay registered (they express
    // refusal through a 'none' drop effect), so the browser should never fire
    // a drop over them — but if one slips through, the intent must resolve to
    // nothing rather than to a move the server will reject.
    it('resolves no intent for a confined item over a foreign list', () => {
      const { root, list } = buildList();
      const sourceList = document.createElement('ul');
      const source = itemRow('1');

      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      list.append(itemRow('4'), itemRow('5'));
      root.append(sourceList);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({
          type: 'work_package',
          itemId: '1',
          sourceListElement: sourceList,
          confined: true,
        }),
      });

      expect(intent).toBeNull();
    });

    it('resolves a confined item dropped on its own source list', () => {
      const { root, list } = buildList();
      const source = itemRow('1');

      list.append(source, itemRow('2'));

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'sprint', listId: '7' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({
          type: 'work_package',
          itemId: '1',
          sourceListElement: list,
          confined: true,
        }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.previousItemId).toEqual('2');
    });

    it('prepends to the list when its drop position is start', () => {
      const { root, list } = buildList();
      const sourceList = document.createElement('ul');
      const source = itemRow('1');

      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      list.append(itemRow('4'), itemRow('5'));
      root.append(sourceList);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7', dropPosition: 'start' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.previousItemId).toBeNull();
    });

    it('resolves a drop back onto the source list to its configured end position', () => {
      const { root, list } = buildList();
      const source = itemRow('1');

      list.append(source, itemRow('2'));

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.previousItemId).toEqual('2');
    });

    it('resolves a drop back onto a start-position source list to the top', () => {
      const { root, list } = buildList();
      const source = itemRow('2');

      list.append(itemRow('1'), source);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7', dropPosition: 'start' }), element: list }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '2' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.previousItemId).toBeNull();
    });

    it('treats an empty drop target list as no move', () => {
      const { root, list } = buildList();
      const source = itemRow('1');
      const target = itemRow('2');

      list.append(source, target);
      document.body.appendChild(root);

      const intent = resolveDropIntent({
        location: dropLocation({ clientY: 90 }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });

    it('ignores drop targets that are neither items nor lists', () => {
      const { root, list } = buildList();
      const sourceList = document.createElement('ul');
      const source = itemRow('1');
      const header = document.createElement('header');

      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      list.append(header, itemRow('4'));
      root.append(sourceList);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: {}, element: header }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });

    it('returns null when the drop lands outside the root', () => {
      const { root } = buildList();
      const outside = document.createElement('div');

      document.body.append(root, outside);

      const intent = resolveDropIntent({
        location: dropLocation(),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });

    it('carries the resolved rows container on the intent', () => {
      const { root, list } = buildList();
      const source = itemRow('1');
      const target = itemRow('2');

      list.append(source, target);
      document.body.appendChild(root);
      vi.spyOn(target, 'getBoundingClientRect').mockReturnValue(rect());

      const data = attachClosestEdge(sortableItemData({ type: 'work_package', itemId: '2' }), {
        element: target,
        input: input({ clientY: 90 }),
        allowedEdges: ['top', 'bottom'],
      });

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [
            { data, element: target },
            { data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list },
          ],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      // No rows container on the payload falls back to the list element.
      expect(intent?.rowsContainer).toBe(list);
    });

    it('resolves rows from the payload rows container when it differs from the list element', () => {
      const root = document.createElement('div');
      const listElement = document.createElement('div');
      const rowsContainer = document.createElement('section');
      const sourceList = document.createElement('ul');
      const source = itemRow('1');

      listElement.setAttribute('data-controller', 'sortable-lists--list');
      rowsContainer.append(divRow('4'), divRow('5'));
      listElement.append(rowsContainer);
      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      root.append(sourceList, listElement);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{
            data: sortableListData({ type: 'backlog_bucket', listId: '7', rowsContainer }),
            element: listElement,
          }],
        }),
        root,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.rowsContainer).toBe(rowsContainer);
      expect(intent?.previousItemId).toEqual('5');
    });
  });
});
