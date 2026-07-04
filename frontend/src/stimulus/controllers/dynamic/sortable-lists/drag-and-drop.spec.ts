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
  buildMoveFormData,
  type DropIntent,
  isItemFromRoot,
  isSortableItemData,
  isSortableListData,
  listAcceptsType,
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

  describe('isItemFromRoot', () => {
    const root = document.createElement('div');

    it('accepts a sortable item tagged with the identical root element', () => {
      expect(isItemFromRoot(root, sortableItemData({ type: 'work_package', itemId: '1', rootElement: root }))).toBe(true);
    });

    it('rejects an item tagged with a different root element', () => {
      expect(isItemFromRoot(root, sortableItemData({ type: 'work_package', itemId: '1', rootElement: document.createElement('div') }))).toBe(false);
    });

    it('rejects an item without a root element', () => {
      expect(isItemFromRoot(root, sortableItemData({ type: 'work_package', itemId: '1' }))).toBe(false);
    });

    it('rejects a null root', () => {
      expect(isItemFromRoot(null, sortableItemData({ type: 'work_package', itemId: '1', rootElement: root }))).toBe(false);
    });

    it('rejects non-item payloads', () => {
      expect(isItemFromRoot(root, { anything: true })).toBe(false);
    });
  });

  describe('listAcceptsType', () => {
    it('accepts a type contained in acceptedTypes', () => {
      expect(listAcceptsType({ acceptedTypes: ['work_package', 'sprint'], type: 'sprint' })).toBe(true);
    });

    it('rejects a type not contained in acceptedTypes', () => {
      expect(listAcceptsType({ acceptedTypes: ['work_package'], type: 'sprint' })).toBe(false);
    });

    it('rejects everything for an empty acceptedTypes', () => {
      expect(listAcceptsType({ acceptedTypes: [], type: 'work_package' })).toBe(false);
    });
  });

  function intentFixture({ listId = '42', previousItemId = 'a' }:{ listId?:string|null; previousItemId?:string|null } = {}):DropIntent {
    const listElement = document.createElement('div');
    const container = document.createElement('ul');
    container.innerHTML = `
      <li data-sortable-lists--item-id-value="a"></li>
      <li data-sortable-lists--item-id-value="b"></li>`;
    listElement.append(container);

    return {
      listElement,
      rowsContainer: container,
      previousItemId,
      listData: sortableListData({ type: 'sprint', listId, dropPosition: 'end' }),
    };
  }

  describe('buildMoveFormData', () => {
    it('builds a relative payload from the intent', () => {
      const data = buildMoveFormData({ intent: intentFixture(), positionMode: 'relative', optimistic: true });
      expect(data.get('list_type')).toBe('sprint');
      expect(data.get('list_id')).toBe('42');
      expect(data.get('prev_id')).toBe('a');
      expect(data.get('optimistic')).toBe('true');
      expect(data.get('position')).toBeNull();
    });

    it('serializes a null list id and previous item as empty strings', () => {
      const data = buildMoveFormData({
        intent: intentFixture({ listId: null, previousItemId: null }),
        positionMode: 'relative',
        optimistic: true,
      });
      expect(data.get('list_id')).toBe('');
      expect(data.get('prev_id')).toBe('');
    });

    it('builds an absolute payload with a computed position', () => {
      const data = buildMoveFormData({
        intent: intentFixture({ previousItemId: 'a' }),
        positionMode: 'absolute',
        optimistic: true,
      });
      expect(data.get('target_id')).toBe('42');
      expect(data.get('position')).toBe('2');
      expect(data.get('optimistic')).toBe('true');
      expect(data.get('prev_id')).toBeNull();
    });

    it('omits the optimistic param when the move is not optimistic', () => {
      const data = buildMoveFormData({ intent: intentFixture(), positionMode: 'relative', optimistic: false });
      expect(data.get('optimistic')).toBeNull();
    });
  });

  // The drop target Pragmatic DnD reports is always the item controller's own
  // registered element, which itself carries data-sortable-lists--item-id-value
  // (resolveItemElement resolves self-or-descendant only, never an ancestor) —
  // so fixtures below pass the item row itself rather than a nested descendant.
  describe('resolvePreviousSortableItemId', () => {
    it('uses the target item as previous item when dropping on the bottom edge', () => {
      const target = itemRow('3');

      expect(resolvePreviousSortableItemId({ sourceItemId: '1', targetItem: target, closestEdge: 'bottom' })).toEqual('3');
    });

    it('uses the previous row item when dropping on the top edge', () => {
      const list = document.createElement('ul');
      list.setAttribute('data-controller', 'sortable-lists--list');
      const first = itemRow('1');
      const targetRow = itemRow('3');

      list.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: targetRow, closestEdge: 'top' })).toEqual('1');
    });

    it('treats a missing closest edge as dropping before the target item', () => {
      const list = document.createElement('ul');
      list.setAttribute('data-controller', 'sortable-lists--list');
      const first = itemRow('1');
      const targetRow = itemRow('3');

      list.append(first, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: targetRow, closestEdge: null })).toEqual('1');
    });

    it('uses a truncation marker when dropping before a tail item', () => {
      const list = document.createElement('ul');
      list.setAttribute('data-controller', 'sortable-lists--list');
      const first = itemRow('1');
      const targetRow = itemRow('6');

      list.append(first, showMoreRow('5'), targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: targetRow, closestEdge: 'top' })).toEqual('5');
    });

    it('skips the source item and uses a preceding truncation marker when resolving the previous item', () => {
      const list = document.createElement('ul');
      list.setAttribute('data-controller', 'sortable-lists--list');
      const first = itemRow('1');
      const source = itemRow('2');
      const targetRow = itemRow('3');

      list.append(first, showMoreRow(), source, targetRow);

      expect(resolvePreviousSortableItemId({ sourceItemId: '2', targetItem: targetRow, closestEdge: 'top' })).toEqual('hidden-item');
    });

    it('returns null when dropping before the first item', () => {
      const target = itemRow('1');

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
      expect(intent?.rowsContainer).toBe(list);
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
      expect(intent?.rowsContainer).toBe(list);
      expect(intent?.previousItemId).toEqual('5');
    });

    it('resolves an end drop against the rows container rather than the list element itself', () => {
      const { root, list } = buildList();
      const sourceList = document.createElement('ul');
      const source = itemRow('1');
      const header = document.createElement('header');
      const rowsContainer = document.createElement('ul');

      list.setAttribute('data-sortable-lists--list-rows-container-selector-value', ':scope > ul');
      sourceList.setAttribute('data-controller', 'sortable-lists--list');
      sourceList.append(source);
      rowsContainer.append(itemRow('4'), itemRow('5'));
      list.append(header, rowsContainer);
      root.append(sourceList);

      const intent = resolveDropIntent({
        location: dropLocation({
          dropTargets: [{ data: sortableListData({ type: 'backlog_bucket', listId: '7' }), element: list }],
        }),
        root,
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.rowsContainer).toBe(rowsContainer);
      expect(intent?.previousItemId).toEqual('5');
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
        sourceElement: source,
        sourceData: sortableItemData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.listElement).toBe(list);
      expect(intent?.rowsContainer).toBe(list);
      expect(intent?.previousItemId).toBeNull();
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
