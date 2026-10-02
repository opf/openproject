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
import { type SelectionItem } from 'core-common/batch-selection';
import { type DragSession } from './drag-session';
import {
  isExcludedItem,
  resolveClosestItemElement,
  resolveItemElement,
  resolveItemId,
  resolveItemType,
  resolveListAppendPreviousItemId,
  resolvePreviousItem,
  rowOf,
  sameDestination,
  type DestinationIdentity,
  type ExcludedItems,
  type MoveAvailability,
  type MoveDirection,
} from './list-dom';

// The Pragmatic DnD payloads exchanged between the sortable-lists root and
// item controllers, built on top of the DOM contract in list-dom.ts.
const sortableItemIdentityKey = Symbol('sortable-list-item');
const sortableListDataKey = Symbol('sortable-list');

// What a drop target exposes: the identity a drop resolves against, and
// nothing that would have to be recomputed on every dragover.
export interface SortableItemIdentity extends Record<string|symbol, unknown> {
  [sortableItemIdentityKey]:true;
  type:string;
  itemId:string;
}

// What the dragged source carries, resolved once at drag start. Distinct
// from the engine payload of the same shape family in
// core-common/drag-and-drop/payload.ts, which names a list id rather than
// a root.
export interface SortableDragSourceData extends SortableItemIdentity {
  rootElement:HTMLElement|null;
  // The destinations this drag may land in, resolved across the whole batch
  // at drag start; null when nothing restricts it, empty when nothing
  // accepts it. Identities rather than list elements: a morph can replace a
  // permitted list mid-drag, and elements frozen here would then name nodes
  // that have left the document.
  permittedDestinations:DestinationIdentity[]|null;
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

// A list the root owns: its element, the destination a drop into it reaches,
// its declared data and the container whose direct children are its rows.
export interface OwnedList {
  element:HTMLElement;
  identity:DestinationIdentity;
  listData:SortableListData;
  rowsContainer:HTMLElement;
}

// The one rule for which list holds an element. Ownership stops at the
// nearest root: an independently nested root is an ownership boundary.
export interface ListTopology {
  readonly rootElement:HTMLElement;
  owns(element:Element):boolean;
  ownerList(element:Element):OwnedList|null;
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
  // The rows container of the item's innermost owning list, or null when the
  // item is not (yet) inside a list the root knows about.
  ownerRowsContainer(itemElement:HTMLElement):HTMLElement|null;
  // Asked in canDrag. A refused session is announced here and not kept.
  beginDrag(itemElement:HTMLElement):DragSession;
  // The session begun last, which the item reads in every later drag
  // callback; held by the root so an item controller replaced mid-drag
  // finds it again.
  readonly dragSession:DragSession|null;
  // The destination of the element's innermost owning list, or null when no
  // list the root knows about claims it. Remembered for the drag in flight.
  ownerDestinationOf(element:HTMLElement):DestinationIdentity|null;
}

// Implemented by the list, item and scrollable controllers so the root can
// hand them its reference (and revoke it) through outlet-connected callbacks,
// and re-establish their Pragmatic DnD registrations after a morph.
export interface RootAwareChild {
  readonly element:Element;
  connectRoot(root:SortableListsRoot):void;
  // With `root`, clears the reference only when that root handed it out, so
  // a foreign root's outlet-disconnected callback cannot strip a child of
  // its own root; without, clears unconditionally (the child's own
  // disconnect).
  disconnectRoot(root?:SortableListsRoot):void;
  reregister():void;
}

export function sortableItemIdentity({ type, itemId }:{ type:string; itemId:string }):SortableItemIdentity {
  return { [sortableItemIdentityKey]: true, type, itemId };
}

export function singleItemBatch({ type, itemId }:{ type:string; itemId:string }):SelectionItem[] {
  return [{ type, id: itemId }];
}

// The source-only fields are what isItemFromRoot narrows on beyond this.
export function isSortableItemIdentity(data:Record<string|symbol, unknown>):data is SortableItemIdentity {
  return data[sortableItemIdentityKey] === true
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

export function sortableDragSourceData({
  type,
  itemId,
  rootElement = null,
  permittedDestinations = null,
}:{
  type:string;
  itemId:string;
  rootElement?:HTMLElement|null;
  permittedDestinations?:DestinationIdentity[]|null;
}):SortableDragSourceData {
  return {
    ...sortableItemIdentity({ type, itemId }),
    rootElement,
    permittedDestinations,
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
  itemIds = null,
}:{
  listId:string|null;
  previousItemId:string|null;
  type:string;
  itemIds?:string[]|null;
}):FormData {
  const data = new FormData();

  itemIds?.forEach((id) => data.append('ids[]', id));
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
):data is SortableDragSourceData {
  return rootElement != null
    && isSortableItemIdentity(data)
    && data.rootElement === rootElement
    && (data.permittedDestinations === null || Array.isArray(data.permittedDestinations));
}

// Whether a drop into the given destination may amount to a move for this
// batch. A destination the batch owns passing is load-bearing: a drop
// resolves through the list target (resolveDropIntent returns null without
// one), so failing it would kill within-list reorder, not just cross-list
// moves. A null destination is one no list claims, which nothing restricted
// accepts.
//
// Item drop targets consult this in canDrop and refuse outright; list drop
// targets stay accepted regardless (an accepted target is what keeps the
// standard 'move' cursor on the dragover — refused, Chrome falls back to a
// copy cursor) and the refusal is enforced here in resolveDropIntent: a
// release over a container this fails for resolves to no move at all, and
// the drop-indicator layers consult it too — rows never show a drop position
// for it, and the list marks its container refused instead of active.
export function permittedDestinationsAllowDrop(
  data:SortableDragSourceData,
  destination:DestinationIdentity|null,
):boolean {
  return data.permittedDestinations === null
    || data.permittedDestinations.some((permitted) => sameDestination(destination, permitted));
}

export function destinationOfList(listData:SortableListData):DestinationIdentity {
  return { type: listData.type, id: listData.listId == null ? null : String(listData.listId) };
}

export function resolvePreviousSortableItemId({
  excludedItems,
  targetItem,
  closestEdge,
  rowsContainer,
}:{
  excludedItems:ExcludedItems;
  targetItem:HTMLElement;
  closestEdge:Edge|null;
  rowsContainer:Element;
}):string|null {
  const targetItemElement = resolveItemElement(targetItem, rowsContainer);
  const targetItemId = targetItemElement ? resolveItemId(targetItemElement) : null;

  if (closestEdge === 'bottom' && targetItemElement && targetItemId !== null
    && !isExcludedItem(excludedItems, { id: targetItemId, type: resolveItemType(targetItemElement) })) {
    return targetItemId;
  }

  const targetRow = rowOf(rowsContainer, targetItemElement ?? targetItem);
  let row = targetRow?.previousElementSibling ?? null;

  while (row) {
    const item = resolvePreviousItem(row, rowsContainer);
    if (item && !isExcludedItem(excludedItems, item)) {
      return item.id;
    }

    row = row.previousElementSibling;
  }

  return null;
}

// A list-only drop (over the header or empty space, not over an item) lands at
// the position the target list declares: 'start' inserts before the first row
// (null previous item), 'end' appends after the last.
function resolveListOnlyPreviousItemId({
  excludedItems,
  rowsContainer,
  dropPosition,
}:{
  excludedItems:ExcludedItems;
  rowsContainer:HTMLElement;
  dropPosition:SortableListDropPosition;
}):string|null {
  if (dropPosition === 'start') {
    return null;
  }

  return resolveListAppendPreviousItemId({ excludedItems, rowsContainer });
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
  excludedItems = { type: sourceData.type, ids: new Set([sourceData.itemId]) },
}:{
  location:DragLocationHistory;
  root:HTMLElement;
  sourceData:SortableDragSourceData;
  excludedItems?:ExcludedItems;
}):DropIntent|null {
  const targetList = location.current.dropTargets.find(
    (target):target is typeof target & { data:SortableListData; element:HTMLElement } => (
      isSortableListData(target.data) && target.element instanceof HTMLElement && root.contains(target.element)
        && permittedDestinationsAllowDrop(sourceData, destinationOfList(target.data))
    ),
  );
  if (!targetList) {
    return null;
  }

  // Scoped to the accepted list rather than gated on its own account: an
  // item drop target carries only its identity, and the list it sits in is
  // the destination a drop into it would reach.
  const targetItem = location.current.dropTargets.find(
    (target):target is typeof target & { data:SortableItemIdentity; element:HTMLElement } => (
      isSortableItemIdentity(target.data) && target.element instanceof HTMLElement
        && targetList.element.contains(target.element)
    ),
  );

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
      excludedItems,
      targetItem: targetItem.element,
      closestEdge: extractClosestEdge(targetItem.data),
      rowsContainer,
    })
    : resolveListOnlyPreviousItemId({
      excludedItems,
      rowsContainer,
      dropPosition: listData.dropPosition,
    });

  return { listElement, listData, previousItemId, rowsContainer };
}
