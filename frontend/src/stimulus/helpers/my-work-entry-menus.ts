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
import { ContextualActionMenu } from 'core-common/contextual-action-menu';

// WorkPackagesController::UPDATED_EVENT_NAME, dispatched once a menu action such as
// assigning the work package has changed it.
export const WORK_PACKAGE_UPDATED_EVENT = 'op-dispatched:work-packages:updated';

// Opens the action menu My::Work::EntryMenusComponent rendered for a calendar event at the
// point the event was clicked.
export class EntryMenus {
  private readonly presenters = new Map<ActionMenuElement, ContextualActionMenu>();

  constructor(private readonly root:Element) {}

  open(eventId:string, event:MouseEvent, invoker:HTMLElement):void {
    const menu = this.root.querySelector<ActionMenuElement>(
      `[data-my-work-menu-for="${CSS.escape(eventId)}"] action-menu`,
    );

    if (!menu) {
      return;
    }

    this.focusWithoutRing(invoker);
    this.presenterFor(menu).openAtPoint(event.clientX, event.clientY, invoker);
  }

  destroy():void {
    this.presenters.forEach((presenter) => presenter.destroy());
    this.presenters.clear();
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
