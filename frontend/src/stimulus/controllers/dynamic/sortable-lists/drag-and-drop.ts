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
  type Edge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  resolveItemElement,
  resolveItemId,
  resolveItemPosition,
  resolveListAppendPreviousItemId,
  resolvePreviousItemId,
  resolveRowsContainer,
  resolveSourceRow,
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
  rootElement:HTMLElement|null;
}

export type SortableListDropPosition = 'start'|'end';

export interface SortableListData extends Record<string|symbol, unknown> {
  [sortableListDataKey]:true;
  type:string;
  listId:string|null;
  // Where a list-only drop (header or empty space, not over an item) lands.
  dropPosition:SortableListDropPosition;
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
  rootElement = null,
}:{
  type:string;
  itemId:string;
  rootElement?:HTMLElement|null;
}):SortableItemData {
  return {
    [sortableItemDataKey]: true,
    type,
    itemId,
    rootElement,
  };
}

export function sortableListData({
  type,
  listId,
  dropPosition = 'end',
}:{
  type:string;
  listId:string|null;
  dropPosition?:SortableListDropPosition;
}):SortableListData {
  return {
    [sortableListDataKey]: true,
    type,
    listId,
    dropPosition,
  };
}

export type SortablePositionMode = 'relative'|'absolute';

// One builder for both payload shapes so call sites hand over the whole drop
// intent; every sortable-lists move is optimistic (the row has already been
// reordered in the DOM), which the `optimistic` param signals to the server.
export function buildMoveFormData({
  intent,
  positionMode,
}:{
  intent:DropIntent;
  positionMode:SortablePositionMode;
}):FormData {
  const data = new FormData();
  data.append('optimistic', 'true');

  if (positionMode === 'absolute') {
    data.append('target_id', intent.listData.listId ?? '');
    data.append('position', String(resolveItemPosition({
      container: intent.rowsContainer,
      previousItemId: intent.previousItemId,
    })));
  } else {
    data.append('list_type', intent.listData.type);
    data.append('list_id', intent.listData.listId ?? '');
    data.append('prev_id', intent.previousItemId ?? '');
  }

  return data;
}

// The shared root-scoping rule: the payload must be a sortable item created by
// an item controller wired to this exact root element. Identity (===), not
// containment — containment would wrongly accept an outer root's item over an
// inner root's surface when roots nest.
export function isItemFromRoot(
  rootElement:HTMLElement|null,
  data:Record<string|symbol, unknown>,
):data is SortableItemData {
  return rootElement != null
    && isSortableItemData(data)
    && data.rootElement === rootElement;
}

export function listAcceptsType({
  acceptedTypes,
  type,
}:{
  acceptedTypes:string[];
  type:string;
}):boolean {
  return acceptedTypes.includes(type);
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

  const targetRow = resolveSourceRow(targetItemElement ?? targetItem);
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

// A list-only drop (over the header or empty space, not over an item) lands at
// the position the target list declares: 'start' inserts before the first row
// (null previous item), 'end' appends after the last.
function resolveListOnlyPreviousItemId({
  sourceItemId,
  container,
  dropPosition,
}:{
  sourceItemId:string;
  container:HTMLElement;
  dropPosition:SortableListDropPosition;
}):string|null {
  if (dropPosition === 'start') {
    return null;
  }

  return resolveListAppendPreviousItemId({ sourceItemId, container });
}

export interface DropIntent {
  listElement:HTMLElement;
  listData:SortableListData;
  rowsContainer:HTMLElement;
  previousItemId:string|null;
}

// Resolve where a dropped item should land: the list it was dropped into and
// the item the dropped one should be inserted after.
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
  if (!(targetList?.element instanceof HTMLElement)) {
    return null;
  }

  const listElement = targetList.element;
  const listData = targetList.data;
  if (!isSortableListData(listData)) {
    return null;
  }

  if (!targetItem && isSourceListTarget({ sourceElement, targetElement: listElement })) {
    return null;
  }

  const rowsContainer = resolveRowsContainer(listElement);

  const previousItemId = targetItem?.element instanceof HTMLElement
    ? resolvePreviousSortableItemId({
      sourceItemId: sourceData.itemId,
      targetItem: targetItem.element,
      closestEdge: extractClosestEdge(targetItem.data),
    })
    : resolveListOnlyPreviousItemId({
      sourceItemId: sourceData.itemId,
      container: rowsContainer,
      dropPosition: listData.dropPosition,
    });

  return {
    listElement,
    listData,
    rowsContainer,
    previousItemId,
  };
}
