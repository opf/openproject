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

import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import { isMoveDirection, sortableLockedAttribute, type MoveAvailability } from './list-dom';

export interface MoveMenuParts {
  readonly items:readonly HTMLElement[];
  readonly submenu:HTMLElement|null;
  readonly divider:HTMLElement|null;
  /** Shown in place of the move actions a batch cannot use. */
  readonly explanations:readonly HTMLElement[];
}

export interface MoveMenuPolicy {
  readonly hideUnavailable:boolean;
  readonly directionAttribute:string;
}

// The server marks a move item locked when it renders it disabled for a
// reason direction gating cannot see, such as a scope above the batch cap.
const isLocked = (item:HTMLElement):boolean => item.hasAttribute(sortableLockedAttribute);

/**
 * The move actions of one card menu. It holds the parts as they stood when
 * it was built; a deferred menu load or a morph replaces them.
 */
export class MoveMenu {
  constructor(
    private readonly menu:ActionMenuElement,
    private readonly parts:MoveMenuParts,
    private readonly policy:MoveMenuPolicy,
  ) {}

  gate(availability:MoveAvailability, scopeSize:() => number):void {
    let available = 0;
    for (const item of this.parts.items) {
      const direction = item.getAttribute(this.policy.directionAttribute);
      const enabled = isMoveDirection(direction) && availability[direction];
      this.setAvailability(item, enabled);
      if (enabled) {
        available += 1;
      }
    }

    if (this.parts.submenu) {
      this.gateSubmenu(this.parts.submenu, available > 0, scopeSize);
    }

    this.refreshDivider();
  }

  /** The item behind an activation, unless it is disabled or hidden. */
  activatable(target:EventTarget|null):HTMLElement|null {
    if (!(target instanceof HTMLElement)) return null;
    if (this.menu.isItemDisabled(target) || this.menu.isItemHidden(target)) return null;

    return target;
  }

  private gateSubmenu(submenu:HTMLElement, available:boolean, scopeSize:() => number):void {
    if (isLocked(submenu)) {
      return;
    }

    const blocked = !available && scopeSize() > 1;
    if (blocked) {
      this.parts.explanations.forEach((item) => this.menu.showItem(item));
      this.hideItem(submenu);
      return;
    }

    if (!this.policy.hideUnavailable && this.menu.isItemHidden(submenu)) {
      this.menu.showItem(submenu);
    }

    this.setAvailability(submenu, available);
    this.parts.explanations.forEach((item) => this.hideItem(item));
  }

  // Focus left on a hidden item drops to the body and Primer light-dismisses
  // the menu, so it moves to a visible item of the same menu first. Primer
  // focuses the first item as the list loads, which can be the one to hide.
  private hideItem(item:HTMLElement):void {
    if (item.contains(document.activeElement)) {
      const list = item.closest('[role="menu"]');
      const visible = Array.from(list?.querySelectorAll<HTMLElement>('[role="menuitem"]') ?? [])
        .find((other) => !item.contains(other) && other.closest('[role="menu"]') === list && !other.closest('[hidden]'));
      visible?.focus();
    }

    this.menu.hideItem(item);
  }

  // The divider that opens the move group is rendered server-side from a
  // permission check alone, so hiding the last entry below it would otherwise
  // leave a separator with nothing to separate. It never goes through
  // setAvailability: `disableItem` writes to the item's `.ActionListContent`,
  // which a divider does not have.
  private refreshDivider():void {
    const { divider } = this.parts;
    if (!divider) {
      return;
    }

    let sibling = divider.nextElementSibling;

    while (sibling) {
      if (sibling.matches('li.ActionListItem:not([hidden])')) {
        divider.removeAttribute('hidden');
        return;
      }

      sibling = sibling.nextElementSibling;
    }

    divider.setAttribute('hidden', 'hidden');
  }

  // Availability goes through the action-menu element's API: disableItem sets the
  // ActionListItem--disabled class plus aria-disabled on the item's content, and
  // hideItem toggles hidden. It operates on any descendant li, including the ones
  // in the nested move submenu.
  private setAvailability(item:HTMLElement, available:boolean):void {
    if (isLocked(item)) {
      return;
    }

    if (this.policy.hideUnavailable) {
      if (available) {
        this.menu.showItem(item);
      } else {
        this.menu.hideItem(item);
      }
    } else if (available) {
      this.menu.enableItem(item);
    } else {
      this.menu.disableItem(item);
    }
  }
}
