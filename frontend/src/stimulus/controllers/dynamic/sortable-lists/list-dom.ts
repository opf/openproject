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

// A child belongs to the nearest root, not to any root containing it: an
// independently nested root is an ownership boundary.
export function ownedBy(root:HTMLElement, element:Element):boolean {
  return element.closest(sortableListsRootSelector) === root;
}

/**
 * What ordering an item takes part in.
 *
 * `fixed` takes no part at all: no drag, no positional move, no selection.
 * `confined` reorders within its own list but is refused by every other
 * container. `free` may move to any list that accepts its type.
 */
export type ItemMobility = 'fixed'|'confined'|'free';

const recognisedMobilities = new Set<string>(['fixed', 'confined', 'free']);

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

export function isMovableItem(itemElement:Element):boolean {
  return itemMobility(itemElement) !== 'fixed';
}

// A destination an item may be moved to: a list, identified by type and id
// (null for the type's unlisted bucket).
export interface DestinationIdentity {
  type:string;
  id:string|null;
}

export function sameDestination(left:DestinationIdentity|null, right:DestinationIdentity):boolean {
  return left !== null && left.type === right.type && left.id === right.id;
}

// The same separator batch-selection.ts uses for item keys: it cannot appear
// in an attribute value, so no type or id can forge a collision.
export function listKey({ type, id }:DestinationIdentity):string {
  return `${type}\u001F${id ?? ''}`;
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

const moveDirections = ['top', 'up', 'down', 'bottom'] as const;

export type MoveDirection = typeof moveDirections[number];

// Values crossing the DOM boundary (action params, data attributes) arrive
// untyped; narrow them instead of casting.
export function isMoveDirection(value:unknown):value is MoveDirection {
  return typeof value === 'string' && (moveDirections as readonly string[]).includes(value);
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

export type MoveAvailability = Record<MoveDirection, boolean>;
