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

// Sortable lists use a DOM contract shared by the root and item controllers:
// the root has data-controller~="sortable-lists"; lists are sortable-lists--list
// controllers wired to the root via outlets; items expose sortable-lists--item values;
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

export function resolveClosestItemElement(element:Element):HTMLElement|null {
  if (element instanceof HTMLElement && element.matches(sortableItemSelector)) {
    return element;
  }

  return element.closest<HTMLElement>(sortableItemSelector);
}

export function resolveItemElement(element:Element):HTMLElement|null {
  return resolveClosestItemElement(element) ??
    element.querySelector<HTMLElement>(sortableItemSelector);
}

export function resolvePreviousItemId(element:Element):string|null {
  const item = resolveItemElement(element);

  // Non-item rows, such as truncated "show more" rows, can mark the last
  // omitted item so position resolution remains correct in sparse lists.
  return item ? resolveItemId(item) : element.getAttribute(sortablePreviousItemIdAttribute);
}

// The inverse of resolvePreviousItemId: the previous item id can point at a
// hidden item collapsed behind a truncation marker row, which carries the id
// on data-sortable-lists-prev-item-id rather than exposing an item element.
// Anchor on that marker so the row lands next to the collapsed block instead
// of jumping to the top.
function resolveAnchorRow(rowsContainer:HTMLElement, previousItemId:string):HTMLElement|null {
  const escaped = CSS.escape(previousItemId);
  const anchor = rowsContainer.querySelector(`[data-sortable-lists--item-id-value="${escaped}"]`)
    ?? rowsContainer.querySelector(`[${sortablePreviousItemIdAttribute}="${escaped}"]`);

  return anchor ? rowOf(rowsContainer, anchor) : null;
}

export function resolveListAppendPreviousItemId({
  sourceItemId,
  rowsContainer,
}:{
  sourceItemId:string;
  rowsContainer:Element;
}):string|null {
  const rows = listRows(rowsContainer).reverse();

  for (const row of rows) {
    const itemId = resolvePreviousItemId(row);
    if (itemId && itemId !== sourceItemId) {
      return itemId;
    }
  }

  return null;
}

export interface RowPlacement {
  row:HTMLElement;
  parent:Node|null;
  nextSibling:Node|null;
}

// Snapshot each row's current location so an optimistic move can be undone if
// the server rejects it. Captured before the move; restored in reverse so the
// stored nextSibling references are still valid when reinserting.
export function captureRowPositions(rows:HTMLElement[]):RowPlacement[] {
  return rows.map((row) => ({
    row,
    parent: row.parentNode,
    nextSibling: row.nextSibling,
  }));
}

export function restoreRowPositions(positions:RowPlacement[]):void {
  for (let i = positions.length - 1; i >= 0; i -= 1) {
    const { row, parent, nextSibling } = positions[i];
    // A list-refresh morph can replace the captured parent mid-request; restoring
    // into a detached node would drop the row out of the live DOM until the next
    // reload. Skip it and let the pending refresh reconcile the position.
    if (!parent?.isConnected) {
      continue;
    }

    const insertionPoint = nextSibling?.parentNode === parent ? nextSibling : null;
    parent.insertBefore(row, insertionPoint);
  }
}

// A rollback may only reinsert rows it still owns: if a concurrent morph
// removed or repositioned a row after the optimistic move, the morph reflects
// fresher server state and the rollback must yield. Deliberately strict —
// any deviation from the captured placement (even a replaced or inserted
// sibling) counts as foreign ownership.
export function rowsRemainAt(positions:RowPlacement[]):boolean {
  return positions.every(({ row, parent, nextSibling }) => (
    row.parentNode === parent && row.nextSibling === nextSibling
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

export type MoveDirection = 'top'|'up'|'down'|'bottom';

// One item element per row of the container, in document order. Mirrors the
// row model the drag path uses (a row resolves to at most one item element).
function containerItemElements(rowsContainer:Element):HTMLElement[] {
  return Array.from(rowsContainer.children)
    .map((row) => resolveItemElement(row))
    .filter((item):item is HTMLElement => item !== null);
}

export function resolveItemMovePosition({
  itemElement,
  rowsContainer,
}:{
  itemElement:HTMLElement;
  rowsContainer:Element;
}):{ isFirst:boolean; isLast:boolean }|null {
  const items = containerItemElements(rowsContainer);
  const index = items.indexOf(itemElement);

  if (index === -1) {
    return null;
  }

  return { isFirst: index === 0, isLast: index === items.length - 1 };
}

// The previous item id to insert `itemElement` after for a directional move:
//   null      -> top of the list
//   string    -> after that item id
//   undefined -> the move is unavailable in this direction (caller no-ops)
export function resolveDirectionalPreviousItemId({
  itemElement,
  direction,
  rowsContainer,
}:{
  itemElement:HTMLElement;
  direction:MoveDirection;
  rowsContainer:Element;
}):string|null|undefined {
  const items = containerItemElements(rowsContainer);
  const index = items.indexOf(itemElement);

  if (index === -1) {
    return undefined;
  }

  const lastIndex = items.length - 1;

  switch (direction) {
    case 'top':
      return index === 0 ? undefined : null;
    case 'bottom':
      return index === lastIndex ? undefined : resolveItemId(items[lastIndex]);
    case 'up':
      // Up one slot = after the item two above; from the second slot that is the top.
      if (index === 0) return undefined;
      return index === 1 ? null : resolveItemId(items[index - 2]);
    case 'down':
      // Down one slot = after the next item.
      return index === lastIndex ? undefined : resolveItemId(items[index + 1]);
    default:
      return undefined;
  }
}
