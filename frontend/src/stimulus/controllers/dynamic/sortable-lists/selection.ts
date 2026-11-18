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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { selectionKey, type SelectionItem, type SelectionKey } from 'core-common/batch-selection';
import { attributeTokenList } from 'core-app/shared/helpers/dom-helpers';
import { type ListTopology } from './drag-and-drop';
import {
  isMovableItem,
  listKey,
  ownedBy,
  resolveItemType,
  resolveItemId,
  sortableItemSelector,
} from './list-dom';

// Distinct from `aria-current`: a card may be either, both, or neither.
export const batchSelectedAttribute = 'data-batch-selected';

export interface SelectionCandidate extends SelectionItem {
  itemElement:HTMLElement;
  // The element the consumer made focusable, and the boundary an
  // interactive-descendant check stops at.
  focusHost:HTMLElement;
  listKey:string;
  movable:boolean;
}

export const itemFocusTargetSelector = '[data-sortable-lists--item-target~="focus"]';

// Bounded to the item's own subtree: a nested list's items carry focus
// targets of their own, and a descendant's must never stand in for the
// outer item's.
function focusHostOf(itemElement:HTMLElement):HTMLElement {
  return Array.from(itemElement.querySelectorAll<HTMLElement>(itemFocusTargetSelector))
    .find((target) => target.closest(sortableItemSelector) === itemElement) ?? itemElement;
}

export function orderedItemElements(root:HTMLElement):HTMLElement[] {
  return Array.from(root.querySelectorAll<HTMLElement>(sortableItemSelector))
    .filter((item) => ownedBy(root, item));
}

/**
 * The item a gesture landed on, or null when the gesture did not land on one.
 *
 * A structural row such as a truncation marker is not an item, and so not a
 * candidate whose selection could be refused either.
 */
export function resolveCandidate(topology:ListTopology, target:EventTarget|null):SelectionCandidate|null {
  if (!(target instanceof Element) || !topology.rootElement.contains(target)) {
    return null;
  }

  const itemElement = target.closest<HTMLElement>(sortableItemSelector);
  const id = itemElement ? resolveItemId(itemElement) : null;
  if (!itemElement || !id || !topology.owns(itemElement)) {
    return null;
  }

  const list = topology.ownerList(itemElement);
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
    listKey: listKey(list.identity),
    movable: isMovableItem(itemElement),
  };
}

export function itemIdentity(itemElement:Element):SelectionItem|null {
  const id = resolveItemId(itemElement);
  const type = resolveItemType(itemElement);

  return id && type ? { type, id } : null;
}

export function orderedSelectedItemElements(root:HTMLElement, keys:ReadonlySet<SelectionKey>):HTMLElement[] {
  return orderedItemElements(root).filter((item) => {
    const identity = itemIdentity(item);
    return identity !== null && keys.has(selectionKey(identity));
  });
}

// One document query per call; never kept, so a morph cannot leave it
// stale. Keyed on type as well as id: ids collide across source tables.
export function itemElementsByKey(root:HTMLElement):Map<SelectionKey, HTMLElement> {
  const map = new Map<SelectionKey, HTMLElement>();
  orderedItemElements(root).forEach((element) => {
    const identity = itemIdentity(element);
    if (identity) {
      map.set(selectionKey(identity), element);
    }
  });
  return map;
}

export function liveMovableItems(root:HTMLElement):SelectionItem[] {
  return orderedItemElements(root)
    .filter(isMovableItem)
    .map((item) => itemIdentity(item))
    .filter((item):item is SelectionItem => item !== null);
}

export function liveMovableKeys(root:HTMLElement):Set<SelectionKey> {
  return new Set(liveMovableItems(root).map(selectionKey));
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
  changedKeys?:ReadonlySet<SelectionKey>,
):void {
  if (changedKeys?.size === 0) {
    return;
  }

  for (const item of orderedItemElements(root)) {
    const identity = itemIdentity(item);
    if (changedKeys && (!identity || !changedKeys.has(selectionKey(identity)))) {
      continue;
    }

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
