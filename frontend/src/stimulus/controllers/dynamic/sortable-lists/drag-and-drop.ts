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
  resolveListAppendPreviousItemId,
  resolvePreviousItemId,
  sortableListIdAttribute,
  sortableListSelector,
  sortableListTypeAttribute,
} from './list-dom';

// The Pragmatic DnD payloads exchanged between the sortable-lists root and
// item controllers, built on top of the DOM contract in list-dom.ts.
const sortableItemDataKey = Symbol('sortable-list-item');
const sortableListDataKey = Symbol('sortable-list');

export interface SortableItemData extends Record<string|symbol, unknown> {
  [sortableItemDataKey]:true;
  type:string;
  itemId:string;
}

export interface SortableListData extends Record<string|symbol, unknown> {
  [sortableListDataKey]:true;
  type:string;
  listId:string|null;
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
}:{
  type:string;
  itemId:string;
}):SortableItemData {
  return {
    [sortableItemDataKey]: true,
    type,
    itemId,
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

export function resolveListTargetData(element:Element):SortableListData|null {
  const type = element.getAttribute(sortableListTypeAttribute);

  if (!type) {
    return null;
  }

  return sortableListData({
    type,
    listId: element.getAttribute(sortableListIdAttribute),
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
  listElement:HTMLElement;
  listData:SortableListData;
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

  const previousItemId = targetItem?.element instanceof HTMLElement
    ? resolvePreviousSortableItemId({
      sourceItemId: sourceData.itemId,
      targetItem: targetItem.element,
      closestEdge: extractClosestEdge(targetItem.data),
    })
    : resolveListAppendPreviousItemId({
      sourceItemId: sourceData.itemId,
      list: listElement,
    });

  return { listElement, listData, previousItemId };
}
