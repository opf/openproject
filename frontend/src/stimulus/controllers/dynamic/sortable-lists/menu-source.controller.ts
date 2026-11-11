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
import type { SelectionAwareChild, SortableListsRoot } from './drag-and-drop';
import { relativeUrl } from './url';
import { resolveClosestItemElement, resolveItemId } from './list-dom';
import { MenuEvents } from './menu-events';
import { RenderedMenuScope } from './rendered-menu-scope';
import { batchSelectedAttribute } from './selection';

const SINGULAR_COUNT = 1;

export default class MenuSourceController extends Controller<HTMLElement> implements SelectionAwareChild {
  static values = { url: String, menuLabelKey: String };

  static targets = ['menu'];

  declare readonly urlValue:string;
  declare readonly menuLabelKeyValue:string;
  declare readonly hasMenuLabelKeyValue:boolean;
  declare readonly menuTargets:HTMLElement[];

  private openMenu:ActionMenuElement|null = null;

  private root?:SortableListsRoot;
  private menus?:MenuEvents;
  private listeners?:AbortController;

  connect():void {
    this.menus = new MenuEvents(
      this.element,
      { opening: this.onOpening, closed: this.onClosed },
      (menu) => resolveClosestItemElement(menu, this.element) !== null,
    );
    this.menus.start();
    this.listeners = new AbortController();
    document.addEventListener('turbo:before-cache', this.onBeforeCache, { signal: this.listeners.signal });
  }

  disconnect():void {
    this.menus?.stop();
    this.menus = undefined;
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
      this.rename(menu, RenderedMenuScope.of(list)?.count ?? SINGULAR_COUNT);
    }
  }

  private readonly onOpening = (menu:ActionMenuElement):void => {
    const itemElement = resolveClosestItemElement(menu, this.element);
    const root = this.root;
    if (!itemElement || !root) {
      return;
    }

    const src = this.menuSrc(itemElement, root.selectForAction(itemElement).items);
    if (src) {
      menu.setAttribute('src', src);
    }

    this.openMenu = menu;
    const loadedList = this.menuTargets.find((list) => menu.contains(list));
    if (loadedList) {
      this.rename(menu, RenderedMenuScope.of(loadedList)?.count ?? SINGULAR_COUNT);
    }
  };

  private readonly onClosed = (menu:ActionMenuElement):void => {
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
    this.selectionPresented();
  }

  // A card's menu opens on the whole selection only when that card is part
  // of a selection of two or more, so only those cards take the batch name.
  selectionPresented():void {
    if (!this.hasMenuLabelKeyValue) {
      return;
    }

    const selectedCount = this.element.querySelectorAll(`[${batchSelectedAttribute}]`).length;
    const singularLabel = I18n.t(this.menuLabelKeyValue, { count: SINGULAR_COUNT });
    const batchLabel = selectedCount > 1 ? I18n.t(this.menuLabelKeyValue, { count: selectedCount }) : singularLabel;
    this.cardTooltips().forEach(([item, tooltip]) => {
      const label = item.hasAttribute(batchSelectedAttribute) ? batchLabel : singularLabel;
      if (tooltip.textContent !== label) {
        tooltip.textContent = label;
      }
    });
  }

  private cardTooltips():[item:HTMLElement, tooltip:HTMLElement][] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('action-menu'))
      .flatMap((menu) => {
        const item = resolveClosestItemElement(menu, this.element);
        const tooltip = item && this.invokerTooltipOf(menu);
        return item && tooltip ? [[item, tooltip] as [HTMLElement, HTMLElement]] : [];
      });
  }

  // The invoker need not sit inside its action-menu.
  private invokerTooltipOf(menu:HTMLElement):HTMLElement|null {
    const overlayId = menu.querySelector('anchored-position')?.id;
    if (!overlayId) {
      return null;
    }

    const invokerSelector = `[popovertarget="${CSS.escape(overlayId)}"]`;
    const invoker = menu.querySelector(invokerSelector) ?? menu.ownerDocument.querySelector(invokerSelector);
    // A morph can leave the id of a replaced tooltip in the invoker's
    // aria-labelledby next to the live one.
    const labelIds = invoker?.getAttribute('aria-labelledby')?.split(/\s+/) ?? [];
    return labelIds
      .map((id) => menu.ownerDocument.getElementById(id))
      .find((label):label is HTMLElement => label?.localName === 'tool-tip') ?? null;
  }

  disconnectRoot():void {
    this.root = undefined;
  }
}
