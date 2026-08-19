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

import {
  type Edge,
  extractClosestEdge,
} from '@atlaskit/pragmatic-drag-and-drop-hitbox/closest-edge';
// Pragmatic drives native drag/drop through an invisible, pointer-tracking
// overlay (a "honey pot") that works around a real cross-browser bug:
// browsers incorrectly keep native "hover" active at the drag's start
// position for its whole duration. A raw document.elementsFromPoint can
// resolve to that overlay instead of the element actually under the
// pointer; this helper reads past it the same way Pragmatic's own target
// resolution (lifecycle-manager) does.
import { getElementFromPointWithoutHoneypot } from '@atlaskit/pragmatic-drag-and-drop/private/get-element-from-point-without-honey-pot';
import { type DragLocationHistory } from '@atlaskit/pragmatic-drag-and-drop/types';
import {
  resolveClosestItemElement,
  resolveItemElement,
  resolveItemId,
  resolveListAppendPreviousItemId,
  resolvePreviousItemId,
  rowOf,
  type MoveAvailability,
  type MoveDirection,
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
  // The list element the drag started in, resolved by the root at drag start
  // (items hold no list reference themselves). Null when the item is not in a
  // registered list. Mirrors the rootElement pattern: identity is carried on
  // the payload so drop targets can decide without walking the DOM.
  sourceListElement:HTMLElement|null;
  // A confined item may only land in sourceListElement or one of its rows;
  // every other container refuses it. See confinementAllowsDrop.
  confined:boolean;
}

export type SortableListDropPosition = 'start'|'end';

export interface SortableListData extends Record<string|symbol, unknown> {
  [sortableListDataKey]:true;
  type:string;
  listId:string|null;
  // Human-readable list name for announcements; null when the list is unnamed.
  name:string|null;
  // Where a list-only drop (header or empty space, not over an item) lands.
  dropPosition:SortableListDropPosition;
  // The element whose direct children are the list's rows, resolved by the list
  // controller and carried here so the drop handlers reorder rows without
  // re-deriving it. Null means "fall back to the list element".
  rowsContainer:HTMLElement|null;
}

// Implemented by the sortable-lists root controller and handed to list/item
// controllers via outlet callbacks, so children read shared state through a
// typed reference instead of walking the DOM.
export interface SortableListsRoot {
  readonly element:HTMLElement;
  readonly busy:boolean;
  moveInDirection(itemElement:HTMLElement, direction:MoveDirection):void;
  // A snapshot for menu gating; the click path re-resolves against the live DOM.
  moveAvailability(itemElement:HTMLElement):MoveAvailability|null;
  // The element of the list an item currently belongs to; null outside any
  // registered list. Items carry no list reference, so the root resolves it.
  ownerListElementOf(itemElement:HTMLElement):HTMLElement|null;
  // The rows container of the item's innermost owning list, or null when the
  // item is not (yet) inside a list the root knows about.
  ownerRowsContainer(itemElement:HTMLElement):HTMLElement|null;
}

// Implemented by the list, item and scrollable controllers so the root can
// hand them its reference (and revoke it) through outlet-connected callbacks,
// and re-establish their Pragmatic DnD registrations after a morph.
export interface RootAwareChild {
  readonly element:Element;
  connectRoot(root:SortableListsRoot):void;
  disconnectRoot():void;
  reregister():void;
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
  sourceListElement = null,
  confined = false,
}:{
  type:string;
  itemId:string;
  rootElement?:HTMLElement|null;
  sourceListElement?:HTMLElement|null;
  confined?:boolean;
}):SortableItemData {
  return {
    [sortableItemDataKey]: true,
    type,
    itemId,
    rootElement,
    sourceListElement,
    confined,
  };
}

export function sortableListData({
  type,
  listId,
  dropPosition = 'end',
  rowsContainer = null,
  name = null,
}:{
  type:string;
  listId:string|null;
  dropPosition?:SortableListDropPosition;
  rowsContainer?:HTMLElement|null;
  name?:string|null;
}):SortableListData {
  return {
    [sortableListDataKey]: true,
    type,
    listId,
    dropPosition,
    rowsContainer,
    name,
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

// The shared root-scoping rule: the payload must be a sortable item created by
// an item controller wired to this exact root element. Identity (===), not
// containment — nested roots must not accept each other's items.
export function isItemFromRoot(
  rootElement:HTMLElement|null,
  data:Record<string|symbol, unknown>,
):data is SortableItemData {
  return rootElement != null
    && isSortableItemData(data)
    && data.rootElement === rootElement;
}

// Whether a drop on the given target may amount to a move under the source's
// confinement. contains() includes the element itself, so one predicate passes
// both the source list element and every row inside it while failing every
// foreign container. The source list passing is load-bearing: a drop resolves
// through the list target (resolveDropIntent returns null without one), so
// failing it would kill within-list reorder, not just cross-list moves.
//
// Item drop targets consult this in canDrop and refuse outright; list drop
// targets stay accepted regardless (an accepted target is what keeps the
// standard 'move' cursor on the dragover — refused, Chrome falls back to a
// copy cursor) and the refusal is enforced here in resolveDropIntent: a
// release over a container this fails for resolves to no move at all, and
// the drop-indicator layers consult it too — rows never show a drop position
// for it, and the list marks its container refused instead of active.
export function confinementAllowsDrop(
  data:SortableItemData,
  targetElement:Element,
):boolean {
  return !data.confined || (data.sourceListElement?.contains(targetElement) ?? false);
}

export function resolvePreviousSortableItemId({
  sourceItemId,
  targetItem,
  closestEdge,
  rowsContainer,
}:{
  sourceItemId:string;
  targetItem:HTMLElement;
  closestEdge:Edge|null;
  rowsContainer:Element;
}):string|null {
  const targetItemElement = resolveItemElement(targetItem, rowsContainer);
  const targetItemId = targetItemElement ? resolveItemId(targetItemElement) : null;

  if (closestEdge === 'bottom' && targetItemId !== sourceItemId) {
    return targetItemId;
  }

  const targetRow = rowOf(rowsContainer, targetItemElement ?? targetItem);
  let row = targetRow?.previousElementSibling ?? null;

  while (row) {
    const itemId = resolvePreviousItemId(row, rowsContainer);
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
  rowsContainer,
  dropPosition,
}:{
  sourceItemId:string;
  rowsContainer:HTMLElement;
  dropPosition:SortableListDropPosition;
}):string|null {
  if (dropPosition === 'start') {
    return null;
  }

  return resolveListAppendPreviousItemId({ sourceItemId, rowsContainer });
}

export interface DropIntent {
  listElement:HTMLElement;
  listData:SortableListData;
  previousItemId:string|null;
  rowsContainer:HTMLElement;
}

// Resolve where a dropped item should land: the list it was dropped into and
// the item the dropped one should be inserted after.
// Returns null when the drop does not amount to a move (outside the root or
// no list metadata). A drop back onto the source list resolves to the list's
// configured drop position like any other list-only drop; suppressing drops
// that land at the source's current position is the drop handler's concern.
export function resolveDropIntent({
  location,
  root,
  sourceData,
}:{
  location:DragLocationHistory;
  root:HTMLElement;
  sourceData:SortableItemData;
}):DropIntent|null {
  const targetItem = location.current.dropTargets.find(
    (target):target is typeof target & { data:SortableItemData; element:HTMLElement } => (
      isSortableItemData(target.data) && target.element instanceof HTMLElement && root.contains(target.element)
        && confinementAllowsDrop(sourceData, target.element)
    ),
  );
  const targetList = location.current.dropTargets.find(
    (target):target is typeof target & { data:SortableListData; element:HTMLElement } => (
      isSortableListData(target.data) && target.element instanceof HTMLElement && root.contains(target.element)
        && confinementAllowsDrop(sourceData, target.element)
    ),
  );
  if (!targetList) {
    return null;
  }

  const listElement = targetList.element;
  const listData = targetList.data;
  const rowsContainer = listData.rowsContainer ?? listElement;

  // An item never accepts itself as a drop target (see ItemController's
  // canDrop: source.data.itemId !== this.idValue), so a drag that is
  // released without ever leaving its own row resolves no item target here,
  // exactly like a genuine drop on the list's background. Tell the two
  // apart by asking what is actually under the pointer: if it is still the
  // source's own row, nothing has moved and there is no signal to act on.
  // Unlike the null for a drop outside the root above, this null rejects a
  // drop the root does own; it must stay behind the target resolution so a
  // background drop keeps resolving. Only an ancestor of the hit-tested
  // element can be "the row under the pointer" -- descending into a
  // container would resolve its first item and swallow that item's genuine
  // list-only drops (a send-to-bottom of the first row).
  if (!targetItem) {
    const { input } = location.current;
    const elementAtPoint = getElementFromPointWithoutHoneypot({ x: input.clientX, y: input.clientY });
    const itemAtPoint = elementAtPoint ? resolveClosestItemElement(elementAtPoint, rowsContainer) : null;

    if (itemAtPoint && root.contains(itemAtPoint) && resolveItemId(itemAtPoint) === sourceData.itemId) {
      return null;
    }
  }

  const previousItemId = targetItem
    ? resolvePreviousSortableItemId({
      sourceItemId: sourceData.itemId,
      targetItem: targetItem.element,
      closestEdge: extractClosestEdge(targetItem.data),
      rowsContainer,
    })
    : resolveListOnlyPreviousItemId({
      sourceItemId: sourceData.itemId,
      rowsContainer,
      dropPosition: listData.dropPosition,
    });

  return { listElement, listData, previousItemId, rowsContainer };
}
