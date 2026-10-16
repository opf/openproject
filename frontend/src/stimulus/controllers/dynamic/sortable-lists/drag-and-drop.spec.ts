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

import { vi } from 'vitest';

import { attachClosestEdge } from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  buildMoveFormData,
  destinationOfList,
  isItemFromRoot,
  isSortableItemIdentity,
  isSortableListData,
  resolveDropIntent,
  sortableDragSourceData,
  sortableItemIdentity,
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

  describe('isSortableItemIdentity', () => {
    it('accepts an identity-only target', () => {
      expect(isSortableItemIdentity(sortableItemIdentity({ type: 'work_package', itemId: '42' }))).toBe(true);
    });

    it('accepts backlogs item data', () => {
      expect(isSortableItemIdentity(sortableDragSourceData({ type: 'work_package', itemId: '42' }))).toBe(true);
    });

    it('rejects lookalike data from another drag source', () => {
      expect(isSortableItemIdentity({ type: 'work_package', itemId: '42' })).toBe(false);
    });

    it('rejects data without an item id', () => {
      expect(isSortableItemIdentity({ type: 'work_package' })).toBe(false);
    });

    it('rejects data with a blank item id', () => {
      expect(isSortableItemIdentity(sortableDragSourceData({ type: 'work_package', itemId: '' }))).toBe(false);
    });

    it('rejects data with a blank type', () => {
      expect(isSortableItemIdentity(sortableDragSourceData({ type: '', itemId: '1' }))).toBe(false);
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

  describe('sortableDragSourceData', () => {
    it('uses the item type as the public source type', () => {
      const data = sortableDragSourceData({ type: 'work_package', itemId: '42' });

      expect(data.type).toEqual('work_package');
      expect(data.itemId).toEqual('42');
      expect(isSortableItemIdentity(data)).toBe(true);
    });

    it('carries the root element on the item payload when provided', () => {
      const root = document.createElement('div');
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package', rootElement: root });

      expect(data.rootElement).toBe(root);
      expect(isSortableItemIdentity(data)).toBe(true);
    });

    it('defaults the item payload root element to null', () => {
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package' });

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

  describe('destinationOfList', () => {
    it.each(['7', null, ''])('preserves destination identity %s', (listId) => {
      expect(destinationOfList(sortableListData({ type: 'sprint', listId })))
        .toEqual({ type: 'sprint', id: listId });
    });
  });

  describe('isItemFromRoot', () => {
    const root = document.createElement('div');

    it('accepts a sortable item whose rootElement is this root', () => {
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package', rootElement: root });
      expect(isItemFromRoot(root, data)).toBe(true);
    });

    it.each([undefined, {}, 'invalid'])('rejects invalid destination restrictions: %s', (permittedDestinations) => {
      const data = { ...sortableItemIdentity({ itemId: '1', type: 'work_package' }), rootElement: root, permittedDestinations };
      expect(isItemFromRoot(root, data)).toBe(false);
    });

    it.each([null, [], [{ type: 'sprint', id: '7' }]])('accepts valid destination restrictions: %s', (permittedDestinations) => {
      const data = { ...sortableItemIdentity({ itemId: '1', type: 'work_package' }), rootElement: root, permittedDestinations };
      expect(isItemFromRoot(root, data)).toBe(true);
    });

    it('rejects a sortable item from another root', () => {
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package', rootElement: document.createElement('div') });
      expect(isItemFromRoot(root, data)).toBe(false);
    });

    it('rejects a sortable item with no root reference', () => {
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package', rootElement: null });
      expect(isItemFromRoot(root, data)).toBe(false);
    });

    it('rejects a null root element', () => {
      const data = sortableDragSourceData({ itemId: '1', type: 'work_package', rootElement: root });
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

      const data = attachClosestEdge(sortableDragSourceData({ type: 'work_package', itemId: '2' }), {
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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

      const data = attachClosestEdge(sortableDragSourceData({ type: 'work_package', itemId: '2' }), {
        element: target,
        input: input({ clientY: 90 }),
        allowedEdges: ['top', 'bottom'],
      });

      const intent = resolveDropIntent({
        location: dropLocation({ dropTargets: [{ data, element: target }] }),
        root,
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({
          type: 'work_package',
          itemId: '1',
          permittedDestinations: [{ type: 'sprint', id: '9' }],
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
        sourceData: sortableDragSourceData({
          type: 'work_package',
          itemId: '1',
          permittedDestinations: [{ type: 'sprint', id: '7' }],
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '2' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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

      const data = attachClosestEdge(sortableDragSourceData({ type: 'work_package', itemId: '2' }), {
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
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
        sourceData: sortableDragSourceData({ type: 'work_package', itemId: '1' }),
      });

      expect(intent?.rowsContainer).toBe(rowsContainer);
      expect(intent?.previousItemId).toEqual('5');
    });
  });
});
