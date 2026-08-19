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

import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';

// The plural form that names one card's own menu. A batch of one is that same
// menu, so it never counts a selection down to "1 selected work package".
const SINGULAR_COUNT = 1;

// The menu's own elements, re-read by the caller on every projection so a
// morph that replaces the subtree is picked up without rebuilding anything.
export interface ActionMenuElements {
  destinationItems:HTMLElement[];
  moveItems:HTMLElement[];
  moveSubmenu:HTMLElement|null;
  invokerGroup:HTMLElement|null;
  batchGroup:HTMLElement|null;
  groupDivider:HTMLElement|null;
}

export interface ActionMenuScope {
  batch:boolean;
  count:number;
}

// Answers, for one menu item, whether the action it invokes can run in the
// current scope. A null `moveItem` leaves the move actions untouched.
export interface ActionAvailability {
  destinationItem:(item:HTMLElement) => boolean;
  moveItem:((item:HTMLElement) => boolean)|null;
}

/**
 * Projects a sortable item's action scope onto its Primer ActionMenu.
 *
 * It owns only presentation: which actions the menu presents, which of its two
 * groups shows, and what the menu is called. It never resolves a scope, never
 * decides whether an action is permitted, and holds no selection state — the
 * caller answers those through {@link ActionAvailability}.
 */
export class SortableActionMenu {
  private open = false;

  constructor(
    private readonly menu:ActionMenuElement,
    private readonly hideUnavailable:boolean,
    private readonly labelKey:string|null,
  ) {}

  get isOpen():boolean {
    return this.open;
  }

  ownsPopoverEvent(event:Event):boolean {
    return event.target === this.menu.popoverElement;
  }

  isItemActionable(item:HTMLElement):boolean {
    return !this.menu.isItemDisabled(item) && !this.menu.isItemHidden(item);
  }

  opening():void {
    this.open = true;
  }

  opened():void {
    this.rescueOpenFocus();
  }

  closed():void {
    this.open = false;
    this.rename(SINGULAR_COUNT);
  }

  // A Turbo restore resurrects the tooltip as snapshotted, batch name and
  // all; a closed menu always presents the singular one.
  settleName():void {
    this.rename(SINGULAR_COUNT);
  }

  project(elements:ActionMenuElements, scope:ActionMenuScope, availability:ActionAvailability):void {
    const presented = this.projectDestinations(elements, availability.destinationItem)
      + this.projectMoves(elements, availability.moveItem);

    this.projectGroups(elements, scope, presented);
  }

  // Both projections return how many actions the menu is presenting, not how
  // many are executable: with hideUnavailable off, unavailable items stay on
  // screen disabled, and the group toggle must count them as presented.
  private projectDestinations(
    { destinationItems }:ActionMenuElements,
    allowed:(item:HTMLElement) => boolean,
  ):number {
    let available = 0;

    for (const item of destinationItems) {
      const enabled = allowed(item);
      this.setAvailability(item, enabled);
      if (enabled) {
        available += 1;
      }
    }

    return this.hideUnavailable ? available : destinationItems.length;
  }

  private projectMoves(
    { moveItems, moveSubmenu }:ActionMenuElements,
    allowed:((item:HTMLElement) => boolean)|null,
  ):number {
    // A null policy means the item is not in a list yet; leave the menu alone
    // until the outlet wiring settles.
    if (!allowed) {
      return this.presentedMoveActionCount(moveItems, moveSubmenu);
    }

    let available = 0;
    for (const item of moveItems) {
      const enabled = allowed(item);
      this.setAvailability(item, enabled);
      if (enabled) {
        available += 1;
      }
    }

    if (moveSubmenu) {
      this.setAvailability(moveSubmenu, available > 0);
      return this.hideUnavailable && available === 0 ? 0 : 1;
    }

    return this.hideUnavailable ? available : moveItems.length;
  }

  // A nested submenu presents as one action; flat move items count each.
  private presentedMoveActionCount(moveItems:HTMLElement[], moveSubmenu:HTMLElement|null):number {
    if (moveSubmenu) {
      return moveSubmenu.hasAttribute('hidden') ? 0 : 1;
    }

    return moveItems.filter((item) => !item.hasAttribute('hidden')).length;
  }

  private projectGroups(
    { invokerGroup, batchGroup, groupDivider }:ActionMenuElements,
    scope:ActionMenuScope,
    presentedBatchActionCount:number,
  ):void {
    const batchActionsPresented = presentedBatchActionCount > 0;
    const batch = scope.batch && batchActionsPresented;

    if (invokerGroup) {
      if (batch) {
        this.rescueFocusFrom(invokerGroup);
      }
      this.hideGroup(invokerGroup, batch);
    }

    if (batchGroup) {
      if (!batchActionsPresented) {
        this.rescueFocusFrom(batchGroup);
      }
      this.hideGroup(batchGroup, !batchActionsPresented);
    }

    // The divider only separates anything while both groups show. It never
    // goes through setAvailability: `disableItem` writes to the item's
    // `.ActionListContent`, which a divider does not have.
    groupDivider?.toggleAttribute('hidden', batch || !batchActionsPresented);

    this.rename(batch ? scope.count : SINGULAR_COUNT);
  }

  // Primer's focus zone stops managing exactly the element `hidden` lands on,
  // so hiding a group alone leaves its items in the zone for the arrows to
  // step onto. A group that comes back is repopulated by the availability
  // pass, which sets each item's own hidden state before this runs.
  private hideGroup(group:HTMLElement, hidden:boolean):void {
    group.toggleAttribute('hidden', hidden);

    if (!hidden) {
      return;
    }

    for (const item of group.querySelectorAll<HTMLElement>('[role="menuitem"]')) {
      item.toggleAttribute('hidden', true);
    }
  }

  // Hiding the group that holds focus would fling focus to the body, and
  // Primer closes the whole menu when focus leaves it. Park focus on the
  // first menu item that stays presented before the group disappears.
  private rescueFocusFrom(group:HTMLElement):void {
    const active = this.menu.ownerDocument.activeElement;
    if (!(active instanceof HTMLElement) || !group.contains(active)) {
      return;
    }

    this.presentedItems().find((item) => !group.contains(item))?.focus();
  }

  // Primer's open-time focus matches `:not([hidden]) > [role=menuitem]`, one
  // level deep: a singular item whose group alone is hidden still matches,
  // and focusing it no-ops. Primer schedules that focus a frame after the
  // toggle, so the correction runs a frame later still.
  private rescueOpenFocus():void {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (!this.open) {
          return;
        }

        const active = this.menu.ownerDocument.activeElement;
        if (
          active instanceof HTMLElement
          && this.menu.contains(active)
          && active.getAttribute('role') === 'menuitem'
          && !active.closest('[hidden]')
        ) {
          return;
        }

        this.presentedItems()[0]?.focus();
      });
    });
  }

  private presentedItems():HTMLElement[] {
    return Array.from(this.menu.querySelectorAll<HTMLElement>('[role="menuitem"]'))
      .filter((item) => !item.closest('[hidden]'));
  }

  // The invoker is a Primer IconButton whose label-type tooltip owns the
  // accessible name — icon_button.rb drops the button's aria-label and points
  // aria-labelledby at the <tool-tip> — so writing aria-label would be inert.
  // The batch name shows only while the menu is open; any projection with the
  // popover closed settles back on the singular form.
  private rename(count:number):void {
    const tooltip = this.nameSource();
    if (!tooltip || !this.labelKey) {
      return;
    }

    tooltip.textContent = I18n.t(this.labelKey, { count: this.open ? count : SINGULAR_COUNT });
  }

  // Primer labels the list by the invoker button, and accessible-name
  // references do not chain: the button's own name comes from a further
  // aria-labelledby at the tooltip, which leaves the menu itself unnamed.
  // Point the list at the tooltip directly so both carry one name and the
  // rename above moves them together.
  private nameSource():HTMLElement|null {
    const labelId = this.menu.invokerElement?.getAttribute('aria-labelledby');
    const tooltip = labelId ? this.menu.ownerDocument.getElementById(labelId) : null;
    if (!labelId || !tooltip) {
      return null;
    }

    const list = this.menu.querySelector('[role="menu"]');
    if (list && list.getAttribute('aria-labelledby') !== labelId) {
      list.setAttribute('aria-labelledby', labelId);
    }

    return tooltip;
  }

  // Availability goes through the action-menu element's API: disableItem sets
  // the ActionListItem--disabled class plus aria-disabled on the item's
  // content, and hideItem toggles hidden. It operates on any descendant li,
  // including the ones in the nested move submenu. Default is hide;
  // hideUnavailable=false switches to disable.
  private setAvailability(item:HTMLElement, available:boolean):void {
    if (this.hideUnavailable) {
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
