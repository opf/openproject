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

import { vi } from 'vitest';

import { attachClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  acceptsSortableItemType,
  buildMoveFormData,
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
        sourceElement: source,
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
        sourceElement: source,
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
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.listData).toEqual(expect.objectContaining({ type: 'backlog_bucket', listId: '7' }));
      expect(intent?.previousItemId).toEqual('5');
    });

    it('returns null for a drop back onto the source list without a target item', () => {
      const { root, list } = buildList();
      const source = itemRow('1');

      list.append(source, itemRow('2'));

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list }],
        }),
        root,
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
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
        sourceElement: source,
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
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });

    it('returns null when the drop lands outside the root', () => {
      const { root } = buildList();
      const source = itemRow('1');
      const outside = document.createElement('div');

      document.body.append(root, outside);

      const intent = resolveDropIntent({
        location: dropLocation(),
        root,
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent).toBeNull();
    });
  });
});
