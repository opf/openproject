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

import { selectionKey, type SelectionAnchor, type SelectionItem, type SelectionKey } from 'core-common/batch-selection';
import { attributeTokenList } from 'core-app/shared/helpers/dom-helpers';
import {
  isOrderableItem,
  resolveItemType,
  sortableListsRootSelector,
  resolveItemElement,
  resolveItemId,
  rowOf,
  sortableItemSelector,
  sortableListSelector,
} from './list-dom';

// Distinct from `aria-current`: a card may be either, both, or neither.
export const batchSelectedAttribute = 'data-batch-selected';

export interface SelectionCandidate extends SelectionItem {
  itemElement:HTMLElement;
  // The element the consumer made focusable, and the boundary an
  // interactive-descendant check stops at.
  focusHost:HTMLElement;
  listKey:string;
  orderable:boolean;
}

export const itemFocusTargetSelector = '[data-sortable-lists--item-target~="focus"]';

// Decides only whether a range stays inside the list it started in. Derived
// from the list's own values rather than its DOM id, so every consumer keys
// its lists the same way.
function listKeyOf(listElement:HTMLElement):string {
  const type = listElement.getAttribute('data-sortable-lists--list-type-value') ?? '';
  const id = listElement.getAttribute('data-sortable-lists--list-id-value') ?? '';

  return `${type}:${id}`;
}

// Bounded to the item's own subtree: a nested list's items carry focus
// targets of their own, and a descendant's must never stand in for the
// outer item's.
function focusHostOf(itemElement:HTMLElement):HTMLElement {
  return Array.from(itemElement.querySelectorAll<HTMLElement>(itemFocusTargetSelector))
    .find((target) => target.closest(sortableItemSelector) === itemElement) ?? itemElement;
}

// A child belongs to the nearest root, not to any root containing it: an
// independently nested root is an ownership boundary.
function ownsElement(root:HTMLElement, element:Element):boolean {
  return element.closest(sortableListsRootSelector) === root;
}

function ownerList(root:HTMLElement, itemElement:HTMLElement):HTMLElement|null {
  const list = itemElement.closest<HTMLElement>(sortableListSelector);

  return list && ownsElement(root, list) ? list : null;
}

function rowItem(row:Element, rowsContainer:Element, root:HTMLElement, list:HTMLElement):HTMLElement|null {
  const item = resolveItemElement(row, rowsContainer);

  return item && ownerList(root, item) === list ? item : null;
}

export function orderedItemElements(root:HTMLElement):HTMLElement[] {
  return Array.from(root.querySelectorAll<HTMLElement>(sortableItemSelector))
    .filter((item) => ownsElement(root, item));
}

/**
 * The item a gesture landed on, or null when the gesture did not land on one.
 *
 * A structural row such as a truncation marker is not an item, and so not a
 * candidate whose selection could be refused either.
 */
export function resolveCandidate(root:HTMLElement, target:EventTarget|null):SelectionCandidate|null {
  if (!(target instanceof Element) || !root.contains(target)) {
    return null;
  }

  const itemElement = target.closest<HTMLElement>(sortableItemSelector);
  const id = itemElement ? resolveItemId(itemElement) : null;
  if (!itemElement || !id || !root.contains(itemElement)) {
    return null;
  }

  const list = ownerList(root, itemElement);
  if (!list) {
    return null;
  }

  // Type is half of identity: an item declaring none cannot be identified,
  // and so cannot be selected.
  const type = resolveItemType(itemElement);
  if (type === null) {
    return null;
  }

  return {
    type,
    itemElement,
    focusHost: focusHostOf(itemElement),
    id,
    listKey: listKeyOf(list),
    orderable: isOrderableItem(itemElement),
  };
}

// Live document order: a morph can reorder rows underneath a selection formed
// minutes ago.
export function orderedSelectedItems(root:HTMLElement, keys:ReadonlySet<SelectionKey>):SelectionItem[] {
  return orderedItemElements(root)
    .map((item) => itemIdentity(item))
    .filter((item):item is SelectionItem => item !== null && keys.has(selectionKey(item)));
}

function itemIdentity(itemElement:Element):SelectionItem|null {
  const id = resolveItemId(itemElement);
  const type = resolveItemType(itemElement);

  return id && type ? { type, id } : null;
}

export function liveOrderableItems(root:HTMLElement):SelectionItem[] {
  return orderedItemElements(root)
    .filter(isOrderableItem)
    .map((item) => itemIdentity(item))
    .filter((item):item is SelectionItem => item !== null);
}

export function liveOrderableListItems(root:HTMLElement, from:HTMLElement):SelectionItem[] {
  return listItems(root, from)
    .filter(isOrderableItem)
    .map((item) => itemIdentity(item))
    .filter((item):item is SelectionItem => item !== null);
}

export function liveOrderableKeys(root:HTMLElement):Set<SelectionKey> {
  return new Set(liveOrderableItems(root).map(selectionKey));
}

// `unavailable` is remediable by expanding the list, most often a truncation
// marker in the span. `locked` is not: a card the user may not move sits in
// it, and expanding changes nothing.
export type RangeUnavailableReason = 'crossList'|'unavailable'|'locked';

export type RangeResolution =
  | { ok:true; items:SelectionItem[] }
  | { ok:false; reason:RangeUnavailableReason };

/**
 * The contiguous, orderable range between the anchor and the candidate, or a
 * reason the range cannot be expressed.
 *
 * A range that would cross a list boundary, a truncation marker or a card the
 * user may not move is refused whole rather than trimmed.
 */
export function resolveRangeItems(
  root:HTMLElement,
  anchor:SelectionAnchor,
  candidate:SelectionCandidate,
  // Must be the container moves use: a row is any direct child of it, not
  // necessarily an item element, so it cannot be derived from the item's own
  // parent.
  rowsContainer:HTMLElement|null,
):RangeResolution {
  if (anchor.listKey !== candidate.listKey) {
    return { ok: false, reason: 'crossList' };
  }

  const list = ownerList(root, candidate.itemElement);
  if (!list || !rowsContainer) {
    return { ok: false, reason: 'unavailable' };
  }

  const rows = Array.from(rowsContainer.children);
  const anchorKey = selectionKey(anchor);
  const anchorRow = rows.find((row) => {
    const item = rowItem(row, rowsContainer, root, list);
    const identity = item && itemIdentity(item);
    return identity !== null && selectionKey(identity) === anchorKey;
  });
  // A candidate whose item sits outside the rows container has no row here.
  const candidateRow = rowOf(rowsContainer, candidate.itemElement);
  if (!anchorRow || !candidateRow) {
    return { ok: false, reason: 'unavailable' };
  }

  const from = rows.indexOf(anchorRow);
  const to = rows.indexOf(candidateRow);
  const span = rows.slice(Math.min(from, to), Math.max(from, to) + 1);

  const items:SelectionItem[] = [];
  for (const row of span) {
    const item = rowItem(row, rowsContainer, root, list);
    const id = item ? resolveItemId(item) : null;
    // A truncation marker in the span and a card the user cannot move are
    // both hard boundaries, but only the first can be resolved by expanding.
    if (!item || !id) {
      return { ok: false, reason: 'unavailable' };
    }

    if (!isOrderableItem(item)) {
      return { ok: false, reason: 'locked' };
    }

    const type = resolveItemType(item);
    if (!type) {
      return { ok: false, reason: 'unavailable' };
    }

    items.push({ type, id });
  }

  return { ok: true, items };
}

/**
 * Marks the selected items and describes them to assistive technology.
 *
 * `describedById` points at an element the consumer renders once, holding the
 * word for "selected"; an empty string skips the description entirely.
 *
 * `data-batch-selected` goes on the item element, `aria-describedby` on the
 * focus host: an accessible description is computed from the focused
 * element's own attribute and never inherited from an ancestor.
 */
export function applySelectionPresentation(
  root:HTMLElement,
  keys:ReadonlySet<SelectionKey>,
  describedById:string,
):void {
  for (const item of orderedItemElements(root)) {
    const identity = itemIdentity(item);
    const focusHost = focusHostOf(item);

    if (identity && keys.has(selectionKey(identity))) {
      item.setAttribute(batchSelectedAttribute, '');
      addDescription(focusHost, describedById);
    } else {
      item.removeAttribute(batchSelectedAttribute);
      removeDescription(focusHost, describedById);
    }
  }
}

// The card may already be described by something of its own, so the shared
// reference is added to the token list rather than replacing it.
function addDescription(item:HTMLElement, describedById:string):void {
  if (describedById === '') {
    return;
  }

  attributeTokenList(item, 'aria-describedby').add(describedById);
}

function removeDescription(item:HTMLElement, describedById:string):void {
  if (describedById === '') {
    return;
  }

  const describedBy = attributeTokenList(item, 'aria-describedby');
  describedBy.remove(describedById);

  // `remove` leaves an empty attribute behind rather than dropping it, and a
  // card that describes nothing should carry no `aria-describedby` at all.
  if (describedBy.length === 0) {
    item.removeAttribute('aria-describedby');
  }
}

// Filtered back to the items this list owns: a nested topology puts another
// list's items inside this one's subtree.
function listItems(root:HTMLElement, from:HTMLElement):HTMLElement[] {
  const list = ownerList(root, from);

  return list
    ? Array.from(list.querySelectorAll<HTMLElement>(sortableItemSelector))
      .filter((item) => ownerList(root, item) === list)
    : [];
}

// Arrows step through the list as rendered, fixed cards included. Not
// symmetric with listBoundaryItem below, which does filter.
export function neighbourItem(root:HTMLElement, from:HTMLElement, offset:1|-1):HTMLElement|null {
  const items = listItems(root, from);
  const index = items.indexOf(from);

  if (index === -1) {
    return null;
  }

  return items[index + offset] ?? null;
}

// Home/End land on the first/last *orderable* card, so a leading or trailing
// fixed card is skipped rather than becoming the jump target.
export function listBoundaryItem(
  root:HTMLElement,
  from:HTMLElement,
  edge:'first'|'last',
):HTMLElement|null {
  const items = listItems(root, from).filter(isOrderableItem);

  if (items.length === 0) {
    return null;
  }

  return edge === 'first' ? items[0] : items[items.length - 1];
}
