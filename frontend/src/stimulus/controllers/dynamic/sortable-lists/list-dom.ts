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

import { debugLog } from 'core-app/shared/helpers/debug_output';

// Sortable lists use a DOM contract shared by the root and item controllers:
// the root has data-controller~="sortable-lists"; lists are sortable-lists--list
// controllers wired to the root via outlets; items expose sortable-lists--item
// values and a mobility, which says what ordering the item takes part in; an
// item that takes none still participates in list order and accepts drops;
// sparse non-item rows may expose data-sortable-lists-prev-item-id.
//
// This module holds the drag-and-drop-agnostic half of that contract: reading
// rows out of a list's rows container (rows are its direct children, whatever
// their tag) and moving them around. The Pragmatic DnD payloads built on top of
// it live in drag-and-drop.ts.
export const sortableListsBusyAttribute = 'data-sortable-lists-busy';
export const sortableListsRootSelector = '[data-controller~="sortable-lists"]';
export const sortableItemSelector = '[data-sortable-lists--item-id-value]';
export const sortableListSelector = '[data-controller~="sortable-lists--list"]';
export const sortablePreviousItemIdAttribute = 'data-sortable-lists-prev-item-id';
export const sortableOmittedCountAttribute = 'data-sortable-lists-omitted-count';
export const sortableItemMobilityAttribute = 'data-sortable-lists--item-mobility-value';

/**
 * What ordering an item takes part in.
 *
 * `fixed` takes no part at all: no drag, no positional move, no selection.
 * `confined` reorders within its own list but is refused by every other
 * container. `free` may move to any list that accepts its type.
 */
export type ItemMobility = 'fixed'|'confined'|'free';

const recognisedMobilities = new Set<string>(['fixed', 'confined', 'free']);

// Rows are the direct children of the list's resolved rows container. The
// rows container itself (a nested <ul>, the list element, ...) is decided by the list
// controller; this module treats any direct child as a row.
function listRows(rowsContainer:Element):Element[] {
  return Array.from(rowsContainer.children);
}

function firstListRow(rowsContainer:Element):Element|null {
  return rowsContainer.firstElementChild;
}

// The row (direct child of the rows container) that holds the given element, or null
// when the element is not inside a row of this rows container.
export function rowOf(rowsContainer:Element, element:Element):HTMLElement|null {
  let current:Element|null = element;

  while (current && current.parentElement !== rowsContainer) {
    current = current.parentElement;
  }

  return current instanceof HTMLElement ? current : null;
}

export function resolveItemId(element:Element):string|null {
  return element.getAttribute('data-sortable-lists--item-id-value');
}

export const sortableItemTypeAttribute = 'data-sortable-lists--item-type-value';

/**
 * The item's mobility.
 *
 * An absent attribute means `free`, so a consumer that renders no mobility
 * keeps working. A present but unrecognised value fails closed to `fixed`: a
 * typo must not hand the user a draggable card, live move actions and a
 * selectable row that only fail once the request comes back.
 */
export function itemMobility(itemElement:Element):ItemMobility {
  const value = itemElement.getAttribute(sortableItemMobilityAttribute);

  if (value === null) {
    return 'free';
  }

  if (!recognisedMobilities.has(value)) {
    debugLog(`sortable-lists: unrecognised mobility "${value}", treating the item as fixed`);
    return 'fixed';
  }

  return value as ItemMobility;
}

export function isOrderableItem(itemElement:Element):boolean {
  return itemMobility(itemElement) !== 'fixed';
}

// A destination an item may be moved to: a list, identified by type and id
// (null for the type's unlisted bucket).
export interface DestinationIdentity {
  type:string;
  id:string|null;
}

export function sameDestination(left:DestinationIdentity|null, right:DestinationIdentity):boolean {
  return left?.type === right.type && left.id === right.id;
}

// Whether the item may enter the destination: the one policy behind every
// surface offering a move.
export function itemAcceptsDestination(
  item:HTMLElement,
  target:DestinationIdentity,
  ownerDestinationOf:(item:HTMLElement) => DestinationIdentity|null,
):boolean {
  switch (itemMobility(item)) {
    case 'fixed':
      return false;
    case 'confined':
      return sameDestination(ownerDestinationOf(item), target);
    default:
      return true;
  }
}

export function permittedDestinations({
  items,
  candidates,
  ownerDestinationOf,
}:{
  items:HTMLElement[];
  candidates:DestinationIdentity[];
  ownerDestinationOf:(item:HTMLElement) => DestinationIdentity|null;
}):DestinationIdentity[] {
  if (items.length === 0 || items.some((item) => itemMobility(item) === 'fixed')) {
    return [];
  }

  return candidates.filter((target) => (
    items.every((item) => itemMobility(item) === 'free' || sameDestination(ownerDestinationOf(item), target))
  ));
}

export function resolveItemType(element:Element):string|null {
  const type = element.getAttribute(sortableItemTypeAttribute);

  return type === '' ? null : type;
}

// Ancestor-or-self, but never past `boundary` (the rows container `element`
// belongs to): `element` is typically a row, or something inside one, and in
// a nested topology (a section item hosting a field list) every ancestor
// above the rows container belongs to an outer list. An unbounded
// `closest()` would match the outer item that happens to contain this row —
// wrong list entirely — which is exactly what a non-item marker row (e.g. an
// empty list's placeholder) would otherwise resolve to instead of "no item
// here". `boundary.contains(match)` accepts a self-or-ancestor match found
// inside the rows container and rejects one outside it.
export function resolveClosestItemElement(element:Element, boundary:Element):HTMLElement|null {
  if (!(element instanceof HTMLElement)) {
    return null;
  }

  const match = element.closest<HTMLElement>(sortableItemSelector);
  return match && boundary.contains(match) ? match : null;
}

// The upward climb is bounded by `boundary`; the downward fallback only
// looks at the row's own direct children, so a wrapper row cannot resolve
// to an item of a list nested inside it.
export function resolveItemElement(element:Element, boundary:Element):HTMLElement|null {
  return resolveClosestItemElement(element, boundary)
    ?? Array.from(element.children).find((child):child is HTMLElement => (
      child instanceof HTMLElement && child.matches(sortableItemSelector)
    )) ?? null;
}

export function resolvePreviousItemId(element:Element, boundary:Element):string|null {
  const item = resolveItemElement(element, boundary);

  // Non-item rows, such as truncated "show more" rows, can mark the last
  // omitted item so position resolution remains correct in sparse lists.
  return item ? resolveItemId(item) : element.getAttribute(sortablePreviousItemIdAttribute);
}

// resolvePreviousItemId plus the type of the item the id belongs to. A
// truncation marker row resolves no item element, so its id carries no type.
export function resolvePreviousItem(element:Element, boundary:Element):{ id:string; type:string|null }|null {
  const item = resolveItemElement(element, boundary);
  if (item) {
    const id = resolveItemId(item);
    return id ? { id, type: resolveItemType(item) } : null;
  }

  const markerId = element.getAttribute(sortablePreviousItemIdAttribute);
  return markerId ? { id: markerId, type: null } : null;
}

// The dragged batch a predecessor walk must skip. One item type per batch,
// so a type plus an id set represents it completely.
export interface ExcludedItems {
  type:string;
  ids:ReadonlySet<string>;
}

// Excluded only when id and type both match: ids collide across source
// tables, so a same-id row of another type is a legitimate anchor. A
// truncation marker resolves no type and stays excluded on its id alone.
export function isExcludedItem(excluded:ExcludedItems, { id, type }:{ id:string; type:string|null }):boolean {
  return excluded.ids.has(id) && (type === null || type === excluded.type);
}

// The inverse of resolvePreviousItemId: the previous item id can point at a
// hidden item collapsed behind a truncation marker row, which carries the id
// on data-sortable-lists-prev-item-id rather than exposing an item element.
// Anchor on that marker so the row lands next to the collapsed block instead
// of jumping to the top.
function resolveAnchorRow(rowsContainer:HTMLElement, previousItemId:string):HTMLElement|null {
  // Match against the list's own rows rather than querying descendants:
  // ids of different item types come from different tables, so a nested
  // inner list may contain an unrelated item with a colliding id.
  const anchor = listRows(rowsContainer)
    .find((row) => resolvePreviousItemId(row, rowsContainer) === previousItemId);

  return (anchor as HTMLElement|undefined) ?? null;
}

export function resolveListAppendPreviousItemId({
  excludedItems,
  rowsContainer,
}:{
  excludedItems:ExcludedItems;
  rowsContainer:Element;
}):string|null {
  const rows = listRows(rowsContainer).reverse();

  for (const row of rows) {
    const item = resolvePreviousItem(row, rowsContainer);
    if (item && !isExcludedItem(excludedItems, item)) {
      return item.id;
    }
  }

  return null;
}

export interface RowPlacement {
  row:HTMLElement;
  parent:HTMLElement|null;
  nextElementSibling:Element|null;
}

// Snapshot each row's current location so an optimistic move can be undone if
// the server rejects it. Captured before the move; restored in reverse so the
// stored nextElementSibling references are still valid when reinserting.
export function captureRowPositions(rows:HTMLElement[]):RowPlacement[] {
  return rows.map((row) => ({
    row,
    parent: row.parentElement,
    nextElementSibling: row.nextElementSibling,
  }));
}

export function restoreRowPositions(positions:RowPlacement[]):void {
  for (let i = positions.length - 1; i >= 0; i -= 1) {
    const { row, parent, nextElementSibling } = positions[i];
    // A list-refresh morph can replace the captured parent mid-request; restoring
    // into a detached node would drop the row out of the live DOM until the next
    // reload. Skip it and let the pending refresh reconcile the position.
    if (!parent?.isConnected) {
      continue;
    }

    const insertionPoint = nextElementSibling?.parentNode === parent ? nextElementSibling : null;
    parent.insertBefore(row, insertionPoint);
  }
}

// A rollback may only reinsert rows it still owns: if a concurrent morph
// removed or repositioned a row after the optimistic move, the morph reflects
// fresher server state and the rollback must yield. The comparison is
// element-level placement only — a changed parent or element sibling counts
// as foreign ownership; text and comment nodes are deliberately ignored.
export function rowsRemainAt(positions:RowPlacement[]):boolean {
  return positions.every(({ row, parent, nextElementSibling }) => (
    row.parentElement === parent && row.nextElementSibling === nextElementSibling
  ));
}

// Optimistically move rows on the client without waiting for the server.
// `rows` are the moved rows in order (one today, the selected set once
// multi-item DnD lands); `previousItemId` of null means top of list.
export function reorderRows({
  rows,
  rowsContainer,
  previousItemId,
}:{
  rows:HTMLElement[];
  rowsContainer:HTMLElement;
  previousItemId:string|null;
}):void {
  let anchor:Element|null = previousItemId ? resolveAnchorRow(rowsContainer, previousItemId) : null;

  for (const row of rows) {
    if (anchor) {
      anchor.after(row);
    } else {
      insertAtListTop(rowsContainer, row);
    }

    anchor = row;
  }
}

// Insert before the first existing row, keeping the moved row among its
// siblings. An empty rows container simply receives the row.
function insertAtListTop(rowsContainer:HTMLElement, row:HTMLElement):void {
  const firstRow = firstListRow(rowsContainer);

  if (firstRow && firstRow !== row) {
    firstRow.before(row);
  } else if (!firstRow) {
    rowsContainer.prepend(row);
  }
}

const moveDirections = ['top', 'up', 'down', 'bottom'] as const;

export type MoveDirection = typeof moveDirections[number];

// Values crossing the DOM boundary (action params, data attributes) arrive
// untyped; narrow them instead of casting.
export function isMoveDirection(value:unknown):value is MoveDirection {
  return typeof value === 'string' && (moveDirections as readonly string[]).includes(value);
}

function isItemRow(row:Element|undefined, rowsContainer:Element):boolean {
  return !!row && resolveItemElement(row, rowsContainer) !== null;
}

// Hidden items a non-item row stands in for (a truncation marker annotated
// with the size of its collapsed block). Rows without the attribute, or with
// a non-numeric or non-positive value, count nothing.
function rowOmittedCount(row:Element):number {
  const raw = row.getAttribute(sortableOmittedCountAttribute);
  const count = raw === null ? NaN : parseInt(raw, 10);

  return Number.isFinite(count) && count > 0 ? count : 0;
}

// The row's absolute 1-based position among the list's items and the item
// total. Counting walks the live rows, so it is correct immediately after an
// optimistic reorder; truncation markers contribute their hidden block to
// both numbers, keeping positions absolute in sparse lists. Null when `row`
// is not an item row of this container.
export function resolveItemPosition({
  row,
  rowsContainer,
}:{
  row:HTMLElement;
  rowsContainer:HTMLElement;
}):{ position:number; total:number }|null {
  let position = 0;
  let total = 0;
  let found = false;

  for (const current of listRows(rowsContainer)) {
    if (isItemRow(current, rowsContainer)) {
      total += 1;
      if (current === row) {
        found = true;
        position = total;
      }
    } else {
      total += rowOmittedCount(current);
    }
  }

  return found ? { position, total } : null;
}

// Self only: unlike resolvePreviousItemId, the row passed here is always the
// dragged item's own row (never a marker or an arbitrary drop target), so no
// ancestor climb is needed. That matters mid cross-list move: the label is
// read before the row is reparented into the target list's rows container,
// so bounding this by that container (which does not yet contain the row)
// would wrongly reject a legitimate self-match.
export function resolveItemLabel(row:Element):string|null {
  return row instanceof HTMLElement && row.matches(sortableItemSelector)
    ? row.getAttribute('data-sortable-lists--item-label-value')
    : null;
}

export function resolveItemExternalUrl(itemElement:Element):string|null {
  const url = itemElement.getAttribute('data-sortable-lists--item-external-url-value');
  return url === '' ? null : url;
}

// A row a predecessor id can be read from: an item row, or a non-item row
// annotated with the id of the last hidden item it stands in for (a
// truncation marker). Unannotated non-item rows (a divider, a heading) give
// no anchor, so a move over them cannot be expressed.
function isAddressableRow(row:Element, rowsContainer:Element):boolean {
  return isItemRow(row, rowsContainer) || row.hasAttribute(sortablePreviousItemIdAttribute);
}

// The previous item id to insert `itemElement` after for a directional move:
//   null      -> top of the list
//   string    -> after that item id
//   undefined -> the move is unavailable in this direction (caller no-ops)
//
// Reasoning happens over rows, not just item elements, so a truncation marker
// participates. The hidden block a marker represents cannot be addressed one
// item at a time, so a single-step up/down that would cross it is unavailable;
// the addressable extremes (top/bottom) and moves that land next to the block
// via the marker's id stay available. Unannotated non-item rows are hard gaps
// for one-step moves, while top/bottom anchor on item rows and stay available.
export function resolveDirectionalPreviousItemId({
  itemElement,
  direction,
  rowsContainer,
}:{
  itemElement:HTMLElement;
  direction:MoveDirection;
  rowsContainer:Element;
}):string|null|undefined {
  const context = resolveRowContext(itemElement, rowsContainer);

  return context ? directionalPreviousItemIdIn(context, direction, rowsContainer) : undefined;
}

export type MoveAvailability = Record<MoveDirection, boolean>;

export interface BlockMoveResolution {
  available:true;
  rows:HTMLElement[];
  previousItemId:string|null;
}

export type BlockMoveUnavailableReason =
  | 'not-orderable'
  | 'cross-list'
  | 'non-contiguous'
  | 'truncation-boundary'
  | 'unaddressable-gap'
  | 'no-op';

export interface BlockMoveUnavailable {
  available:false;
  reason:BlockMoveUnavailableReason;
}

export type BlockMoveResult = BlockMoveResolution|BlockMoveUnavailable;

export function resolveBlockMove({
  itemElements,
  direction,
  rowsContainer,
}:{
  itemElements:HTMLElement[];
  direction:MoveDirection;
  rowsContainer:HTMLElement;
}):BlockMoveResult {
  const unavailable = (reason:BlockMoveUnavailableReason):BlockMoveUnavailable => ({ available: false, reason });
  if (itemElements.length === 0 || itemElements.some((item) => !isOrderableItem(item))) {
    return unavailable('not-orderable');
  }

  const rows = listRows(rowsContainer);
  const selectedRows = itemElements.map((item) => rowOf(rowsContainer, item));
  if (selectedRows.some((row, index) => (
    row === null || resolveItemElement(row, rowsContainer) !== itemElements[index]
  ))) {
    return unavailable('cross-list');
  }

  const block = selectedRows as HTMLElement[];
  const indexes = block.map((row) => rows.indexOf(row));
  if (
    new Set(block).size !== block.length ||
    indexes.some((index, offset) => offset > 0 && index !== indexes[offset - 1] + 1)
  ) {
    return unavailable('non-contiguous');
  }

  const itemRows = rows.filter((row) => isItemRow(row, rowsContainer));
  const itemIndexes = block.map((row) => itemRows.indexOf(row));
  if (itemIndexes.some((index, offset) => index < 0 || (offset > 0 && index !== itemIndexes[offset - 1] + 1))) {
    return unavailable('non-contiguous');
  }

  const firstRowIndex = indexes[0];
  const lastRowIndex = indexes[indexes.length - 1];
  const firstItemIndex = itemIndexes[0];
  const lastItemIndex = itemIndexes[itemIndexes.length - 1];

  let previousItemId:string|null|undefined;
  switch (direction) {
    case 'top':
      previousItemId = firstItemIndex === 0 ? undefined : null;
      break;
    case 'bottom': {
      if (lastItemIndex === itemRows.length - 1) return unavailable('no-op');
      const selected = new Set(block);
      const anchor = [...itemRows].reverse().find((row) => !selected.has(row as HTMLElement));
      const anchorId = anchor ? resolvePreviousItemId(anchor, rowsContainer) : null;
      previousItemId = anchorId ?? undefined;
      break;
    }
    case 'up': {
      if (firstItemIndex === 0) return unavailable('no-op');
      const adjacent = rows[firstRowIndex - 1];
      if (!isItemRow(adjacent, rowsContainer)) {
        return unavailable(adjacent && rowOmittedCount(adjacent) > 0 ? 'truncation-boundary' : 'unaddressable-gap');
      }
      const anchor = rows[firstRowIndex - 2];
      if (anchor && !isAddressableRow(anchor, rowsContainer)) return unavailable('unaddressable-gap');
      previousItemId = anchor ? resolvePreviousItemId(anchor, rowsContainer) : null;
      break;
    }
    case 'down': {
      if (lastItemIndex === itemRows.length - 1) return unavailable('no-op');
      const adjacent = rows[lastRowIndex + 1];
      if (!isItemRow(adjacent, rowsContainer)) {
        return unavailable(adjacent && rowOmittedCount(adjacent) > 0 ? 'truncation-boundary' : 'unaddressable-gap');
      }
      const adjacentId = resolvePreviousItemId(adjacent, rowsContainer);
      previousItemId = adjacentId ?? undefined;
      break;
    }
  }

  return previousItemId === undefined
    ? unavailable(firstItemIndex === 0 || lastItemIndex === itemRows.length - 1 ? 'no-op' : 'unaddressable-gap')
    : { available: true, rows: block, previousItemId };
}

export function resolveBlockMoveAvailability({
  itemElements,
  rowsContainer,
}:{
  itemElements:HTMLElement[];
  rowsContainer:HTMLElement;
}):MoveAvailability {
  return {
    top: resolveBlockMove({ itemElements, rowsContainer, direction: 'top' }).available,
    up: resolveBlockMove({ itemElements, rowsContainer, direction: 'up' }).available,
    down: resolveBlockMove({ itemElements, rowsContainer, direction: 'down' }).available,
    bottom: resolveBlockMove({ itemElements, rowsContainer, direction: 'bottom' }).available,
  };
}

// Availability of all four directional moves for the item, or null when it is
// not (yet) a row of the container. The row scan happens once; the four
// per-direction resolutions only index into it.
export function resolveMoveAvailability({
  itemElement,
  rowsContainer,
}:{
  itemElement:HTMLElement;
  rowsContainer:Element;
}):MoveAvailability|null {
  const context = resolveRowContext(itemElement, rowsContainer);
  if (!context) {
    return null;
  }

  return {
    top: directionalPreviousItemIdIn(context, 'top', rowsContainer) !== undefined,
    up: directionalPreviousItemIdIn(context, 'up', rowsContainer) !== undefined,
    down: directionalPreviousItemIdIn(context, 'down', rowsContainer) !== undefined,
    bottom: directionalPreviousItemIdIn(context, 'bottom', rowsContainer) !== undefined,
  };
}

// The item's row neighbourhood, scanned once and shared by the per-direction
// resolutions above.
interface RowContext {
  rows:Element[];
  rowIndex:number;
  itemRows:Element[];
  itemIndex:number;
}

function resolveRowContext(itemElement:HTMLElement, rowsContainer:Element):RowContext|null {
  const rows = listRows(rowsContainer);
  const sourceRow = rowOf(rowsContainer, itemElement);
  const rowIndex = sourceRow ? rows.indexOf(sourceRow) : -1;

  if (rowIndex === -1) {
    return null;
  }

  const itemRows = rows.filter((row) => resolveItemElement(row, rowsContainer) !== null);

  return { rows, rowIndex, itemRows, itemIndex: itemRows.indexOf(sourceRow!) };
}

function directionalPreviousItemIdIn(
  { rows, rowIndex, itemRows, itemIndex }:RowContext,
  direction:MoveDirection,
  rowsContainer:Element,
):string|null|undefined {
  const isFirstItem = itemIndex === 0;
  const isLastItem = itemIndex === itemRows.length - 1;

  switch (direction) {
    case 'top':
      return isFirstItem ? undefined : null;
    case 'bottom':
      // After the last visible item; the server appends past the hidden block.
      return isLastItem ? undefined : resolvePreviousItemId(itemRows[itemRows.length - 1], rowsContainer);
    case 'up': {
      if (isFirstItem) return undefined;
      // One slot up crosses a hidden block (marker row above) or an
      // uncrossable gap (unannotated row above) -- unavailable either way.
      if (!isItemRow(rows[rowIndex - 1], rowsContainer)) return undefined;
      const anchor = rows[rowIndex - 2];
      // The row two above becomes the predecessor (its own id, or a marker's
      // hidden id); an unannotated row there means "before the item above but
      // after the gap", which cannot be expressed. No row means the top.
      if (anchor && !isAddressableRow(anchor, rowsContainer)) return undefined;
      return anchor ? resolvePreviousItemId(anchor, rowsContainer) : null;
    }
    case 'down': {
      if (isLastItem) return undefined;
      const below = rows[rowIndex + 1];
      // One slot down needs the row below as predecessor: a marker row would
      // mean crossing its hidden block, an unannotated row gives no anchor.
      if (!isItemRow(below, rowsContainer)) return undefined;
      return resolvePreviousItemId(below, rowsContainer);
    }
    default:
      return undefined;
  }
}
