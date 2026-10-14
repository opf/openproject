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
import { ContextualActionMenu } from 'core-common/contextual-action-menu';

// WorkPackagesController::UPDATED_EVENT_NAME, dispatched once a menu action such as
// assigning the work package has changed it.
export const WORK_PACKAGE_UPDATED_EVENT = 'op-dispatched:work-packages:updated';

// Opens the action menu My::Work::EntryMenusComponent rendered for a calendar event at the
// point the event was clicked.
export class EntryMenus {
  private readonly presenters = new Map<ActionMenuElement, ContextualActionMenu>();
  private pendingOpen?:AbortController;
  private pointMarker?:HTMLElement;

  constructor(private readonly root:Element) {}

  open(eventId:string, event:MouseEvent, invoker:HTMLElement):void {
    const menu = this.root.querySelector<ActionMenuElement>(
      `[data-my-work-menu-for="${CSS.escape(eventId)}"] action-menu`,
    );

    this.cancelPendingOpen();

    if (!menu) {
      return;
    }

    this.focusWithoutRing(invoker);

    const { clientX, clientY } = event;
    const anchor = this.markPoint(invoker, clientX, clientY);
    this.whenItemsLoaded(menu, () => this.presenterFor(menu).openAtPoint(clientX, clientY, anchor));
  }

  destroy():void {
    this.cancelPendingOpen();
    this.pointMarker?.remove();
    this.presenters.forEach((presenter) => presenter.destroy());
    this.presenters.clear();
  }

  // ContextualActionMenu anchors the menu on the element it is given, with the pointer as an
  // offset from that element's bottom edge. A menu flipped above a tall card for lack of room
  // then hangs off the card's top edge instead of the pointer. An empty element at the pointer
  // makes both sides open from the pointer, and inside the card it scrolls along with it.
  // Focus returned to it once the menu closes goes on to the card.
  private markPoint(invoker:HTMLElement, clientX:number, clientY:number):HTMLElement {
    this.pointMarker?.remove();

    const marker = document.createElement('span');
    marker.tabIndex = -1;
    Object.assign(marker.style, {
      position: 'absolute', left: '0', top: '0', width: '0', height: '0', pointerEvents: 'none',
    });
    marker.addEventListener('focus', () => this.focusWithoutRing(invoker));
    invoker.appendChild(marker);

    const origin = marker.getBoundingClientRect();
    marker.style.left = `${clientX - origin.left}px`;
    marker.style.top = `${clientY - origin.top}px`;

    this.pointMarker = marker;
    return marker;
  }

  // The menu is placed by its size when it opens, and placed again when deferred items
  // replace the loading indicator, which may flip it from below the pointer to above it.
  // Opening it only once complete keeps it from jumping.
  private whenItemsLoaded(menu:ActionMenuElement, open:() => void):void {
    const fragment = menu.querySelector<HTMLElement & { loading:string }>('include-fragment');

    if (!fragment) {
      open();
      return;
    }

    this.pendingOpen = new AbortController();
    fragment.addEventListener('include-fragment-replaced', open, { once: true, signal: this.pendingOpen.signal });
    fragment.loading = 'eager';
  }

  private cancelPendingOpen():void {
    this.pendingOpen?.abort();
    this.pendingOpen = undefined;
  }

  // The menu focuses its first item once it opens, and the browser shows that focus as if
  // the menu had been reached by keyboard unless it moves on from an element focused by
  // pointer. A FullCalendar event is not focusable on its own, so nothing would be.
  private focusWithoutRing(invoker:HTMLElement):void {
    if (invoker.tabIndex < 0 && !invoker.hasAttribute('tabindex')) {
      invoker.tabIndex = -1;
    }

    invoker.focus({ preventScroll: true, focusVisible: false });
  }

  private presenterFor(menu:ActionMenuElement):ContextualActionMenu {
    let presenter = this.presenters.get(menu);

    if (!presenter) {
      presenter = new ContextualActionMenu(menu);
      this.presenters.set(menu, presenter);
    }

    return presenter;
  }
}
