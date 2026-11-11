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

import { Controller } from '@hotwired/stimulus';
import type { ActionMenuElement } from '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element';
import type { RootAwareChild, SortableListsRoot } from './drag-and-drop';
import { relativeUrl } from './url';
import { resolveClosestItemElement, resolveItemId } from './list-dom';
import { primaryMenuOf } from './menu-dom';

const SINGULAR_COUNT = 1;

export default class MenuSourceController extends Controller<HTMLElement> implements RootAwareChild {
  static values = { url: String, menuLabelKey: String };

  static targets = ['menu'];

  declare readonly urlValue:string;
  declare readonly menuLabelKeyValue:string;
  declare readonly hasMenuLabelKeyValue:boolean;
  declare readonly menuTargets:HTMLElement[];

  private openMenu:ActionMenuElement|null = null;

  private root?:SortableListsRoot;
  private listeners?:AbortController;

  connect():void {
    this.listeners = new AbortController();
    const { signal } = this.listeners;
    // beforetoggle and toggle do not bubble.
    this.element.addEventListener('beforetoggle', this.onBeforeToggle, { capture: true, signal });
    this.element.addEventListener('toggle', this.onToggle, { capture: true, signal });
    document.addEventListener('turbo:before-cache', this.onBeforeCache, { signal });
  }

  disconnect():void {
    this.listeners?.abort();
    this.listeners = undefined;
    this.disconnectRoot();
    this.openMenu = null;
  }

  // The deferred list arrives after the menu opened, labeled by the invoker
  // button. Accname does not follow the button's own aria-labelledby on to
  // its tooltip, so the list is pointed at the tooltip directly.
  menuTargetConnected(list:HTMLElement):void {
    const menu = list.closest<ActionMenuElement>('action-menu');
    const tooltip = menu && this.tooltipOf(menu);
    if (!menu || !tooltip) {
      return;
    }

    list.setAttribute('aria-labelledby', tooltip.id);
    if (menu === this.openMenu) {
      this.rename(menu, this.scopeCountOf(list));
    }
  }

  private readonly onBeforeToggle = (event:Event):void => {
    if (!('newState' in event) || event.newState !== 'open') {
      return;
    }

    const menu = primaryMenuOf(event.target);
    const itemElement = menu && resolveClosestItemElement(menu, this.element);
    const root = this.root;
    if (!menu || !itemElement || !root) {
      return;
    }

    const src = this.menuSrc(itemElement, root.selectForAction(itemElement).items);
    if (src) {
      menu.setAttribute('src', src);
    }

    this.openMenu = menu;
    const loadedList = this.menuTargets.find((list) => menu.contains(list));
    if (loadedList) {
      this.rename(menu, this.scopeCountOf(loadedList));
    }
  };

  private readonly onToggle = (event:Event):void => {
    if (!('newState' in event) || event.newState !== 'closed') {
      return;
    }

    const menu = primaryMenuOf(event.target);
    if (!menu || !resolveClosestItemElement(menu, this.element)) {
      return;
    }

    if (menu === this.openMenu) {
      this.openMenu = null;
    }
    this.rename(menu, SINGULAR_COUNT);
  };

  // A restored page reloads its menus when they next open; the snapshot only
  // has to lose the open menu and its batch name.
  private readonly onBeforeCache = ():void => {
    const menu = this.openMenu;
    if (!menu) {
      return;
    }

    const overlay = menu.popoverElement;
    if (overlay?.matches(':popover-open')) {
      overlay.hidePopover();
    }
    this.openMenu = null;
    this.rename(menu, SINGULAR_COUNT);
  };

  // The server decides between the batch and the singular menu, so the list
  // it renders carries the count the name reports.
  private scopeCountOf(list:HTMLElement):number {
    const count = Number.parseInt(list.dataset.sortableListsScopeCount ?? '', 10);
    return Number.isNaN(count) ? SINGULAR_COUNT : count;
  }

  // Primer's IconButton drops its aria-label in favor of aria-labelledby at
  // the label tooltip, so the tooltip text is the name.
  private rename(menu:ActionMenuElement, count:number):void {
    const tooltip = this.tooltipOf(menu);
    if (tooltip && this.hasMenuLabelKeyValue) {
      tooltip.textContent = I18n.t(this.menuLabelKeyValue, { count });
    }
  }

  private tooltipOf(menu:ActionMenuElement):HTMLElement|null {
    const labelId = menu.invokerElement?.getAttribute('aria-labelledby');
    const tooltip = labelId ? menu.ownerDocument.getElementById(labelId) : null;
    return tooltip?.localName === 'tool-tip' ? tooltip : null;
  }

  // A refused scope (a fixed or non-orderable card, or selection disabled)
  // still loads the invoker's own menu.
  private menuSrc(invoker:HTMLElement, scope:HTMLElement[]):string|null {
    const invokerId = resolveItemId(invoker);
    if (!invokerId) {
      return null;
    }

    const ids = scope.length > 0 ? scope.map(resolveItemId) : [invokerId];
    const url = new URL(this.urlValue, window.location.href);
    ids.forEach((id) => {
      if (id) {
        url.searchParams.append('ids[]', id);
      }
    });
    url.searchParams.set('invoker_id', invokerId);

    return relativeUrl(url);
  }

  connectRoot(root:SortableListsRoot):void {
    this.root = root;
  }

  disconnectRoot():void {
    this.root = undefined;
  }
}
