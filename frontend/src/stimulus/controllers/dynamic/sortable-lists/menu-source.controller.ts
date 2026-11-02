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
import type SortableListsController from '../sortable-lists.controller';
import { resolveClosestItemElement, resolveItemId } from './list-dom';

const SINGULAR_COUNT = 1;

export default class MenuSourceController extends Controller<HTMLElement> {
  static values = { url: String, menuLabelKey: String };

  static targets = ['menu'];

  declare readonly urlValue:string;
  declare readonly menuLabelKeyValue:string;
  declare readonly hasMenuLabelKeyValue:boolean;
  declare readonly menuTargets:HTMLElement[];

  private openMenu:ActionMenuElement|null = null;

  private readonly lazyFragments = new WeakMap<ActionMenuElement, Element>();

  connect():void {
    // beforetoggle and toggle do not bubble.
    this.element.addEventListener('beforetoggle', this.onBeforeToggle, true);
    this.element.addEventListener('toggle', this.onToggle, true);
    this.element.addEventListener('sortable-lists:menu-scope-changed', this.onScopeChanged);
    document.addEventListener('turbo:before-cache', this.onBeforeCache);
  }

  disconnect():void {
    this.element.removeEventListener('beforetoggle', this.onBeforeToggle, true);
    this.element.removeEventListener('toggle', this.onToggle, true);
    this.element.removeEventListener('sortable-lists:menu-scope-changed', this.onScopeChanged);
    document.removeEventListener('turbo:before-cache', this.onBeforeCache);
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
    if (!(event instanceof ToggleEvent) || event.newState !== 'open') {
      return;
    }

    const menu = this.primaryMenuOf(event.target);
    const itemElement = menu && resolveClosestItemElement(menu, this.element);
    const root = this.root;
    if (!menu || !itemElement || !root) {
      return;
    }

    this.rememberLazyFragment(menu);
    const src = this.menuSrc(itemElement, root.selectForAction(itemElement).items);
    if (src && menu.getAttribute('src') !== src) {
      menu.setAttribute('src', src);
    }

    this.openMenu = menu;
    const loadedList = this.menuTargets.find((list) => menu.contains(list));
    if (loadedList) {
      this.rename(menu, this.scopeCountOf(loadedList));
    }
  };

  private readonly onToggle = (event:Event):void => {
    if (!(event instanceof ToggleEvent) || event.newState !== 'closed') {
      return;
    }

    const menu = this.primaryMenuOf(event.target);
    if (!menu || !resolveClosestItemElement(menu, this.element)) {
      return;
    }

    if (menu === this.openMenu) {
      this.openMenu = null;
    }
    this.rename(menu, SINGULAR_COUNT);
  };

  private readonly onScopeChanged = (event:Event):void => {
    const menu = event.target instanceof HTMLElement ? event.target.closest<ActionMenuElement>('action-menu') : null;
    const list = menu && this.menuTargets.find((target) => menu.contains(target));
    if (menu && list && menu === this.openMenu) {
      this.rename(menu, this.scopeCountOf(list));
    }
  };

  // Primer treats a menu as deferred only if it connects with its lazy
  // fragment in place, so a snapshot of a loaded menu would come back
  // unable to load for a later selection.
  private readonly onBeforeCache = ():void => {
    this.element.querySelectorAll<ActionMenuElement>('action-menu').forEach((menu) => {
      const fragment = this.lazyFragments.get(menu);
      if (fragment) {
        this.restoreLazyFragment(menu, fragment);
      }
    });
  };

  private rememberLazyFragment(menu:ActionMenuElement):void {
    const fragment = this.primaryBodyOf(menu)?.querySelector(':scope > include-fragment[src]');
    if (fragment && !this.lazyFragments.has(menu)) {
      this.lazyFragments.set(menu, fragment.cloneNode(true) as Element);
    }
  }

  private restoreLazyFragment(menu:ActionMenuElement, fragment:Element):void {
    const body = this.primaryBodyOf(menu);
    const src = fragment.getAttribute('src');
    if (!body || !src) {
      return;
    }

    const overlay = this.overlayOf(menu);
    if (overlay?.matches(':popover-open')) {
      overlay.hidePopover();
    }
    if (menu === this.openMenu) {
      this.openMenu = null;
    }

    body.replaceChildren(fragment.cloneNode(true));
    menu.setAttribute('src', src);
    this.rename(menu, SINGULAR_COUNT);
  }

  private overlayOf(menu:ActionMenuElement):HTMLElement|null {
    return menu.querySelector<HTMLElement>(':scope > anchored-position');
  }

  // Sub-menus nest their own overlay bodies inside the loaded list.
  private primaryBodyOf(menu:ActionMenuElement):HTMLElement|null {
    const overlay = this.overlayOf(menu);
    const bodies = overlay ? Array.from(overlay.querySelectorAll<HTMLElement>('.Overlay-body')) : [];
    return bodies.find((body) => body.closest('anchored-position') === overlay) ?? null;
  }

  // The server decides between the batch and the singular menu, so the list
  // it renders carries the count the name reports. A list narrowed to its
  // singular fallback on the client is a singular menu.
  private scopeCountOf(list:HTMLElement):number {
    if (list.hasAttribute('data-sortable-lists-scope-narrowed')) {
      return SINGULAR_COUNT;
    }

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

  // Tooltips and sub-menus inside the card menu are popovers too.
  private primaryMenuOf(target:EventTarget|null):ActionMenuElement|null {
    if (!(target instanceof HTMLElement) || target.localName !== 'anchored-position') {
      return null;
    }

    const container = target.parentElement?.closest<HTMLElement>('anchored-position, action-menu');
    return container?.localName === 'action-menu' ? container as ActionMenuElement : null;
  }

  // A refused scope (a fixed or non-orderable card, or selection disabled)
  // still loads the invoker's own menu.
  private menuSrc(invoker:HTMLElement, scope:HTMLElement[]):string|null {
    const invokerId = resolveItemId(invoker);
    if (!invokerId) {
      return null;
    }

    const ids = scope.length > 0 ? scope.map(resolveItemId) : [invokerId];
    const params = new URLSearchParams();
    ids.forEach((id) => {
      if (id) {
        params.append('ids[]', id);
      }
    });
    params.append('invoker_id', invokerId);

    return `${this.urlValue}?${params.toString()}`;
  }

  private get root():SortableListsController|null {
    return this.application.getControllerForElementAndIdentifier(this.element, 'sortable-lists') as SortableListsController|null;
  }
}
