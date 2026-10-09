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

import { selectionKey, type SelectionItem } from 'core-common/batch-selection';
import {
  isExcludedItem,
  itemMobility,
  resolveItemElement,
  resolveItemId,
  resolveItemType,
  rowOf,
  sortableOmittedCountAttribute,
  sortablePreviousItemIdAttribute,
  type ExcludedItems,
  type ItemMobility,
  type MoveAvailability,
  type MoveDirection,
} from './list-dom';

export interface RenderedItem {
  element:HTMLElement;
  id:string;
  type:string|null;
  mobility:ItemMobility;
  movable:boolean;
}

// A direct child of the rows container. `predecessorId` is what a
// predecessor walk may read from the row: an item's own id, or the hidden id
// a truncation marker is annotated with; null for a gap (a divider, a
// heading), which no move can be expressed across.
export interface RenderedRow {
  element:HTMLElement;
  item:RenderedItem|null;
  predecessorId:string|null;
  predecessorType:string|null;
  omittedCount:number;
}

/**
 * One list's rows, read once for one calculation.
 *
 * Built at the start of a gesture and dropped after it: a Turbo morph can
 * replace rows at any time, and nothing holds a snapshot across one.
 */
export interface RenderedList {
  readonly container:HTMLElement;
  readonly rows:readonly RenderedRow[];
  rowOf(element:Element):RenderedRow|null;
  itemRows():RenderedRow[];
}

export interface Placement {
  // Null means the top of the list.
  previousItemId:string|null;
}

export type RangeUnavailableReason = 'unavailable'|'locked';

export type RangeResolution =
  | { ok:true; items:SelectionItem[] }
  | { ok:false; reason:RangeUnavailableReason };

export function renderList(container:HTMLElement):RenderedList {
  const rows = Array.from(container.children)
    .filter((element):element is HTMLElement => element instanceof HTMLElement)
    .map((element) => renderRow(element, container));

  return {
    container,
    rows,
    rowOf(element:Element):RenderedRow|null {
      const rowElement = rowOf(container, element);
      return rowElement ? rows.find((row) => row.element === rowElement) ?? null : null;
    },
    itemRows():RenderedRow[] {
      return rows.filter((row) => row.item !== null);
    },
  };
}

function renderRow(element:HTMLElement, container:HTMLElement):RenderedRow {
  const itemElement = resolveItemElement(element, container);
  const id = itemElement ? resolveItemId(itemElement) : null;

  if (itemElement && id) {
    const mobility = itemMobility(itemElement);
    const type = resolveItemType(itemElement);

    return {
      element,
      item: { element: itemElement, id, type, mobility, movable: mobility !== 'fixed' },
      predecessorId: id,
      predecessorType: type,
      omittedCount: 0,
    };
  }

  return {
    element,
    item: null,
    // An empty annotation names no hidden item; the row is a gap.
    predecessorId: hiddenPredecessorId(element),
    predecessorType: null,
    omittedCount: omittedCount(element),
  };
}

function hiddenPredecessorId(row:Element):string|null {
  const id = row.getAttribute(sortablePreviousItemIdAttribute);

  return id === null || id === '' ? null : id;
}

function omittedCount(row:Element):number {
  const raw = row.getAttribute(sortableOmittedCountAttribute);
  const count = raw === null ? NaN : parseInt(raw, 10);

  return Number.isFinite(count) && count > 0 ? count : 0;
}

// The one predecessor walk: backwards from `index` inclusive to the first row
// that offers an id outside the excluded batch.
function predecessorFrom(list:RenderedList, index:number, excluded:ExcludedItems):Placement {
  for (let i = index; i >= 0; i -= 1) {
    const row = list.rows[i];
    if (row.predecessorId !== null && !isExcludedItem(excluded, { id: row.predecessorId, type: row.predecessorType })) {
      return { previousItemId: row.predecessorId };
    }
  }

  return { previousItemId: null };
}

export function placementAtStart():Placement {
  return { previousItemId: null };
}

export function placementAtEnd(list:RenderedList, excluded:ExcludedItems):Placement {
  return predecessorFrom(list, list.rows.length - 1, excluded);
}

// A drop on an item: after it on its bottom edge, else after whatever
// precedes it; an excluded target (a batch member) never anchors.
export function placementAtEdge(list:RenderedList, row:RenderedRow, edge:'top'|'bottom'|null, excluded:ExcludedItems):Placement {
  const index = list.rows.indexOf(row);

  if (edge === 'bottom' && row.item && !isExcludedItem(excluded, { id: row.item.id, type: row.item.type })) {
    return { previousItemId: row.item.id };
  }

  return predecessorFrom(list, index - 1, excluded);
}

// Reasoning happens over rows, not just items, so a truncation marker takes
// part: a one-step move that would cross its hidden block is unavailable,
// while the extremes and moves landing next to the block via the marker's
// id stay available. A gap is a hard stop for one-step moves.
export function directionalPlacement(list:RenderedList, row:RenderedRow, direction:MoveDirection):Placement|null {
  const { rows } = list;
  const rowIndex = rows.indexOf(row);
  const itemRows = list.itemRows();
  const itemIndex = itemRows.indexOf(row);

  if (rowIndex === -1 || itemIndex === -1) {
    return null;
  }

  const isFirst = itemIndex === 0;
  const isLast = itemIndex === itemRows.length - 1;

  switch (direction) {
    case 'top':
      return isFirst ? null : placementAtStart();
    case 'bottom':
      // After the last visible item; the server appends past the hidden block.
      return isLast ? null : { previousItemId: itemRows[itemRows.length - 1].predecessorId };
    case 'up': {
      if (isFirst || !rows[rowIndex - 1].item) {
        return null;
      }
      const anchor:RenderedRow|undefined = rows[rowIndex - 2];
      if (anchor?.predecessorId === null) {
        return null;
      }
      return { previousItemId: anchor?.predecessorId ?? null };
    }
    case 'down': {
      if (isLast) {
        return null;
      }
      const below = rows[rowIndex + 1];
      return below.item ? { previousItemId: below.predecessorId } : null;
    }
    default:
      return null;
  }
}

export function moveAvailability(list:RenderedList, row:RenderedRow):MoveAvailability {
  return {
    top: directionalPlacement(list, row, 'top') !== null,
    up: directionalPlacement(list, row, 'up') !== null,
    down: directionalPlacement(list, row, 'down') !== null,
    bottom: directionalPlacement(list, row, 'bottom') !== null,
  };
}

// Absolute 1-based position among the list's items and the item total;
// markers contribute their hidden block to both, so positions stay absolute
// in sparse lists. Null when `row` is not an item row of this list.
export function positionOf(list:RenderedList, row:RenderedRow):{ position:number; total:number }|null {
  let position = 0;
  let total = 0;
  let found = false;

  for (const current of list.rows) {
    if (current.item) {
      total += 1;
      if (current === row) {
        found = true;
        position = total;
      }
    } else {
      total += current.omittedCount;
    }
  }

  return found ? { position, total } : null;
}

// The inverse of the predecessor walk: a previous item id can name an item
// hidden behind a marker, which carries the id instead of an item element.
export function anchorRow(list:RenderedList, previousItemId:string):RenderedRow|null {
  return list.rows.find((row) => row.predecessorId === previousItemId) ?? null;
}

/**
 * The contiguous, movable range between the anchor and the candidate, or
 * why it cannot be expressed. A span crossing a marker or an item without a
 * type is `unavailable` (expanding the list may fix it); one crossing a
 * fixed item is `locked` (expanding changes nothing).
 */
export function rangeBetween(list:RenderedList, anchor:SelectionItem, candidate:Element):RangeResolution {
  const anchorKey = selectionKey(anchor);
  const anchorRowIndex = list.rows.findIndex((row) => (
    row.item !== null && row.item.type !== null && selectionKey({ type: row.item.type, id: row.item.id }) === anchorKey
  ));
  const candidateRow = list.rowOf(candidate);
  const candidateRowIndex = candidateRow ? list.rows.indexOf(candidateRow) : -1;

  if (anchorRowIndex === -1 || candidateRowIndex === -1) {
    return { ok: false, reason: 'unavailable' };
  }

  const span = list.rows.slice(Math.min(anchorRowIndex, candidateRowIndex), Math.max(anchorRowIndex, candidateRowIndex) + 1);
  const items:SelectionItem[] = [];

  for (const row of span) {
    if (!row.item) {
      return { ok: false, reason: 'unavailable' };
    }
    if (!row.item.movable) {
      return { ok: false, reason: 'locked' };
    }
    if (row.item.type === null) {
      return { ok: false, reason: 'unavailable' };
    }
    items.push({ type: row.item.type, id: row.item.id });
  }

  return { ok: true, items };
}

// Arrows step through the list as rendered, fixed items included; not
// symmetric with boundaryItemRow, which filters.
export function neighbourItemRow(list:RenderedList, from:Element, offset:1|-1):RenderedRow|null {
  const itemRows = list.itemRows();
  const fromRow = list.rowOf(from);
  const index = fromRow ? itemRows.indexOf(fromRow) : -1;

  return index === -1 ? null : itemRows[index + offset] ?? null;
}

// Home/End land on the first/last movable item, so a leading or trailing
// fixed item is skipped rather than becoming the jump target.
export function boundaryItemRow(list:RenderedList, edge:'first'|'last'):RenderedRow|null {
  const movable = list.itemRows().filter((row) => row.item!.movable);

  if (movable.length === 0) {
    return null;
  }

  return edge === 'first' ? movable[0] : movable[movable.length - 1];
}

export function movableItems(list:RenderedList):SelectionItem[] {
  return list.itemRows()
    .filter((row) => row.item!.movable && row.item!.type !== null)
    .map((row) => ({ type: row.item!.type!, id: row.item!.id }));
}
