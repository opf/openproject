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
// the root has data-controller~="sortable-lists"; lists are root targets with
// data-sortable-lists-list-* metadata; items expose sortable-lists--item values;
// sparse non-item rows may expose data-sortable-lists-prev-item-id.
//
// This module holds the drag-and-drop-agnostic half of that contract: reading
// items and rows out of the DOM and moving rows around. The Pragmatic DnD
// payloads built on top of it live in drag-and-drop.ts.
export const sortableListsMovingAttribute = 'data-sortable-lists-moving';
export const sortableListsRootSelector = '[data-controller~="sortable-lists"]';
export const sortableItemSelector = '[data-sortable-lists--item-id-value]';
export const sortableListSelector = '[data-sortable-lists-target~="list"]';
export const sortablePreviousItemIdAttribute = 'data-sortable-lists-prev-item-id';

// Rows can sit directly under the list element or inside a nested <ul>.
const listRowSelector = ':scope > li, :scope > ul > li';

function listRows(list:Element):Element[] {
  return Array.from(list.querySelectorAll(listRowSelector));
}

function firstListRow(list:Element):Element|null {
  return list.querySelector(listRowSelector);
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
function resolveAnchorRow(list:HTMLElement, previousItemId:string):HTMLElement|null {
  const escaped = CSS.escape(previousItemId);
  const anchor = list.querySelector(`[data-sortable-lists--item-id-value="${escaped}"]`)
    ?? list.querySelector(`[${sortablePreviousItemIdAttribute}="${escaped}"]`);

  return anchor?.closest('li') ?? null;
}

export function resolveListAppendPreviousItemId({
  sourceItemId,
  list,
}:{
  sourceItemId:string;
  list:Element;
}):string|null {
  const rows = listRows(list).reverse();

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
    if (!parent) {
      continue;
    }

    const insertionPoint = nextSibling?.parentNode === parent ? nextSibling : null;
    parent.insertBefore(row, insertionPoint);
  }
}

// Optimistically move rows on the client without waiting for the server.
// `rows` are the moved <li>s in order (one today, the selected set once
// multi-item DnD lands); `previousItemId` of null means top of list.
export function reorderRows({
  rows,
  list,
  previousItemId,
}:{
  rows:HTMLElement[];
  list:HTMLElement;
  previousItemId:string|null;
}):void {
  let anchor:Element|null = previousItemId ? resolveAnchorRow(list, previousItemId) : null;

  for (const row of rows) {
    if (anchor) {
      anchor.after(row);
    } else {
      insertAtListTop(list, row);
    }

    anchor = row;
  }
}

// A plain list.prepend() would drop the row before a nested <ul>. Insert
// before the first existing row instead, keeping it in the same container as
// its siblings.
function insertAtListTop(list:HTMLElement, row:HTMLElement):void {
  const firstRow = firstListRow(list);

  if (firstRow && firstRow !== row) {
    firstRow.before(row);
  } else if (!firstRow) {
    (list.querySelector(':scope > ul') ?? list).prepend(row);
  }
}
