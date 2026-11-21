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

export interface MenuEventHandlers {
  /** Before the menu opens, while its content can still be changed. */
  opening?(menu:ActionMenuElement):void;
  opened?(menu:ActionMenuElement):void;
  closed?(menu:ActionMenuElement):void;
}

type MenuState = 'open'|'closed';

/** The open and close events of the action menus under one host element. */
export class MenuEvents {
  private listeners:AbortController|null = null;

  constructor(
    private readonly host:HTMLElement,
    private readonly handlers:MenuEventHandlers,
    private readonly accepts:(menu:ActionMenuElement) => boolean = () => true,
  ) {}

  start():void {
    if (this.listeners) {
      return;
    }

    this.listeners = new AbortController();
    const options = { capture: true, signal: this.listeners.signal };
    // beforetoggle and toggle do not bubble.
    this.host.addEventListener('beforetoggle', this.onBeforeToggle, options);
    this.host.addEventListener('toggle', this.onToggle, options);
  }

  stop():void {
    this.listeners?.abort();
    this.listeners = null;
  }

  private readonly onBeforeToggle = (event:Event):void => {
    const menu = this.menuOf(event, 'open');
    if (menu) {
      this.handlers.opening?.(menu);
    }
  };

  private readonly onToggle = (event:Event):void => {
    const opened = this.menuOf(event, 'open');
    if (opened) {
      this.handlers.opened?.(opened);
      return;
    }

    const closed = this.menuOf(event, 'closed');
    if (closed) {
      this.handlers.closed?.(closed);
    }
  };

  // newState is read by duck typing rather than `instanceof ToggleEvent`, so
  // a browser without the ToggleEvent global cannot throw. Tooltips and
  // sub-menus inside a menu are popovers too; only the menu's own counts,
  // which also leaves out an element not yet upgraded to an action menu.
  private menuOf(event:Event, state:MenuState):ActionMenuElement|null {
    if (!('newState' in event) || event.newState !== state) {
      return null;
    }

    const { target } = event;
    const menu = target instanceof HTMLElement ? target.closest<ActionMenuElement>('action-menu') : null;
    return menu?.popoverElement === target && this.accepts(menu) ? menu : null;
  }
}
