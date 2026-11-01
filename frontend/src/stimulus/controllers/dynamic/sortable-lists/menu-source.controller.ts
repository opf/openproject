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
import type SortableListsController from '../sortable-lists.controller';
import { resolveClosestItemElement, resolveItemId } from './list-dom';

export default class MenuSourceController extends Controller<HTMLElement> {
  static values = { url: String };

  declare readonly urlValue:string;

  connect():void {
    // beforetoggle does not bubble.
    this.element.addEventListener('beforetoggle', this.onBeforeToggle, true);
  }

  disconnect():void {
    this.element.removeEventListener('beforetoggle', this.onBeforeToggle, true);
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

    const src = this.menuSrc(itemElement, root.selectForAction(itemElement).items);
    if (src && menu.getAttribute('src') !== src) {
      menu.setAttribute('src', src);
    }
  };

  // Tooltips and sub-menus inside the card menu are popovers too.
  private primaryMenuOf(target:EventTarget|null):HTMLElement|null {
    if (!(target instanceof HTMLElement) || target.localName !== 'anchored-position') {
      return null;
    }

    const container = target.parentElement?.closest<HTMLElement>('anchored-position, action-menu');
    return container?.localName === 'action-menu' ? container : null;
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
