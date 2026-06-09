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
  attachClosestEdge,
  type Edge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { type DragLocationHistory, type Input } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  resolveClosestItemElement,
  resolveItemElement,
  resolveItemId,
  resolveItemType,
  resolveListAppendPreviousItemId,
  resolvePreviousItemId,
  sortableListSelector,
} from './list-dom';

// The Pragmatic DnD payloads exchanged between the sortable-lists root and
// item controllers, built on top of the DOM contract in list-dom.ts.
const sortableItemDataKey = Symbol('sortable-list-item');
const sortableListDataKey = Symbol('sortable-list');

export interface SortableItemData extends Record<string|symbol, unknown> {
  [sortableItemDataKey]:true;
  type:string;
  itemId:string;
  moveUrl?:string;
}

export interface SortableListData extends Record<string|symbol, unknown> {
  [sortableListDataKey]:true;
  type:string;
  listId:string|null;
}

export interface FallbackDropTarget {
  element:HTMLElement;
  data:Record<string|symbol, unknown>;
  isItem:boolean;
}

export function isSortableItemData(data:Record<string|symbol, unknown>):data is SortableItemData {
  return data[sortableItemDataKey] === true
    && typeof data.type === 'string'
    && data.type.length > 0
    && typeof data.itemId === 'string'
    && data.itemId.length > 0;
}

export function isSortableListData(data:Record<string|symbol, unknown>):data is SortableListData {
  return data[sortableListDataKey] === true
    && typeof data.type === 'string'
    && data.type.length > 0
    && (typeof data.listId === 'string' || data.listId === null);
}

export function sortableItemData({
  type,
  itemId,
  moveUrl,
}:{
  type:string;
  itemId:string;
  moveUrl?:string;
}):SortableItemData {
  return {
    [sortableItemDataKey]: true,
    type,
    itemId,
    ...(moveUrl ? { moveUrl } : {}),
  };
}

export function sortableListData({
  type,
  listId,
}:{
  type:string;
  listId:string|null;
}):SortableListData {
  return {
    [sortableListDataKey]: true,
    type,
    listId,
  };
}

export function buildMoveFormData({
  listId,
  previousItemId,
  type,
}:{
  listId:string|null;
  previousItemId:string|null;
  type:string;
}):FormData {
  const data = new FormData();

  data.append('list_type', type);
  data.append('list_id', listId ?? '');
  data.append('prev_id', previousItemId ?? '');

  return data;
}

export function resolveListData(element:Element):SortableListData|null {
  const list = element.closest<HTMLElement>(sortableListSelector);

  if (!list) {
    return null;
  }

  const type = list.getAttribute('data-sortable-lists-list-type');

  if (!type) {
    return null;
  }

  return sortableListData({
    type,
    listId: list.getAttribute('data-sortable-lists-list-id'),
  });
}

export function acceptsSortableItemType({
  acceptedType,
  type,
}:{
  acceptedType:string|null;
  type:string;
}):boolean {
  return acceptedType === null || acceptedType === type;
}

export function isSourceListTarget({
  sourceElement,
  targetElement,
}:{
  sourceElement:Element;
  targetElement:Element;
}):boolean {
  return sourceElement.closest(sortableListSelector) === targetElement;
}

function elementsFromPoint(document:Document, clientX:number, clientY:number):Element[] {
  const elements = document.elementsFromPoint?.(clientX, clientY) ?? [];
  const element = document.elementFromPoint(clientX, clientY);

  if (element && !elements.includes(element)) {
    return [...elements, element];
  }

  return elements;
}

export function resolveFallbackDropTarget({
  input,
  root,
  sourceElement,
}:{
  input:Input;
  root:HTMLElement;
  sourceElement?:HTMLElement;
}):FallbackDropTarget|null {
  const elementsAtPoint = elementsFromPoint(root.ownerDocument, input.clientX, input.clientY);

  for (const elementAtPoint of elementsAtPoint) {
    if (!(elementAtPoint instanceof HTMLElement) || !root.contains(elementAtPoint)) {
      continue;
    }

    const item = resolveClosestItemElement(elementAtPoint);
    if (item && item !== sourceElement && root.contains(item)) {
      const itemId = resolveItemId(item);

      if (itemId) {
        return {
          element: item,
          data: attachClosestEdge(sortableItemData({ itemId, type: resolveItemType(item) }), {
            element: item,
            input,
            allowedEdges: ['top', 'bottom'],
          }),
          isItem: true,
        };
      }
    }

    const list = elementAtPoint.closest<HTMLElement>(sortableListSelector);
    if (list && root.contains(list)) {
      const listData = resolveListData(list);

      if (!listData) {
        continue;
      }

      return {
        element: list,
        data: listData,
        isItem: false,
      };
    }
  }

  return null;
}

export function resolvePreviousSortableItemId({
  sourceItemId,
  targetItem,
  closestEdge,
}:{
  sourceItemId:string;
  targetItem:HTMLElement;
  closestEdge:Edge|null;
}):string|null {
  const targetItemElement = resolveItemElement(targetItem);
  const targetItemId = targetItemElement ? resolveItemId(targetItemElement) : null;

  if (closestEdge === 'bottom' && targetItemId !== sourceItemId) {
    return targetItemId;
  }

  const targetRow = (targetItemElement ?? targetItem).closest('li');
  let row = targetRow?.previousElementSibling ?? null;

  while (row) {
    const itemId = resolvePreviousItemId(row);
    if (itemId && itemId !== sourceItemId) {
      return itemId;
    }

    row = row.previousElementSibling;
  }

  return null;
}

export interface DropIntent {
  targetElement:HTMLElement;
  listData:SortableListData;
  previousItemId:string|null;
}

// Resolve where a dropped item should land: the element under the drop, the
// list it belongs to and the item the dropped one should be inserted after.
// Returns null when the drop does not amount to a move (outside the root, no
// list metadata, or dropped back onto its own list without a target item).
export function resolveDropIntent({
  location,
  root,
  sourceElement,
  sourceData,
}:{
  location:DragLocationHistory;
  root:HTMLElement;
  sourceElement:HTMLElement;
  sourceData:SortableItemData;
}):DropIntent|null {
  const targetItem = location.current.dropTargets.find(({ data, element }) => (
    isSortableItemData(data) && element instanceof HTMLElement && root.contains(element)
  ));
  const targetList = location.current.dropTargets.find(({ data, element }) => (
    isSortableListData(data) && element instanceof HTMLElement && root.contains(element)
  ));
  const targetElement = targetItem?.element ?? targetList?.element;

  if (!(targetElement instanceof HTMLElement)) {
    return null;
  }

  const listData = resolveListData(targetElement);
  if (!listData) {
    return null;
  }

  if (!targetItem && isSourceListTarget({ sourceElement, targetElement })) {
    return null;
  }

  const previousItemId = targetItem?.element instanceof HTMLElement
    ? resolvePreviousSortableItemId({
      sourceItemId: sourceData.itemId,
      targetItem: targetItem.element,
      closestEdge: extractClosestEdge(targetItem.data),
    })
    : resolveListAppendPreviousItemId({
      sourceItemId: sourceData.itemId,
      list: targetElement,
    });

  return { targetElement, listData, previousItemId };
}
