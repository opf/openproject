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

const itemSelector = '[data-sortable-lists--item-id-value]';
const scopeAttribute = 'data-type-projects-selection-scope';
const actionAttribute = 'data-type-projects-selection-action';

type Scope = 'single'|'batch';

/**
 * Points a project row's menu at the batch selection when the row belongs to
 * it, so the kebab and the right-click act on every selected project.
 *
 * Membership is read from the rows' `data-batch-selected`, which
 * `sortable-lists` maintains; this controller never changes the selection.
 */
export default class TypeProjectsSelectionController extends Controller<HTMLElement> {
  static values = { switchUrl: String, removeUrl: String };

  declare readonly switchUrlValue:string;
  declare readonly removeUrlValue:string;

  connect():void {
    this.element.addEventListener('contextual-action-menu:beforeOpen', this.onContextMenu);
    this.element.addEventListener('click', this.onClick);
  }

  disconnect():void {
    this.element.removeEventListener('contextual-action-menu:beforeOpen', this.onContextMenu);
    this.element.removeEventListener('click', this.onClick);
  }

  private readonly onContextMenu = (event:Event):void => {
    if (event.target instanceof Element) {
      this.scopeMenuOf(event.target);
    }
  };

  private readonly onClick = (event:MouseEvent):void => {
    const invoker = event.target instanceof Element
      ? event.target.closest('action-menu [aria-haspopup="true"]')
      : null;

    if (invoker) {
      this.scopeMenuOf(invoker);
    }
  };

  private scopeMenuOf(element:Element):void {
    const row = element.closest<HTMLElement>(itemSelector);
    if (!row) {
      return;
    }

    const batch = this.batchOf(row);
    const scope:Scope = batch.length > 1 ? 'batch' : 'single';

    row.querySelectorAll<HTMLElement>(`[${scopeAttribute}]`).forEach((item) => {
      item.hidden = item.getAttribute(scopeAttribute) !== scope;
    });

    if (scope === 'batch') {
      this.pointBatchActions(row, batch);
    }
  }

  private batchOf(row:HTMLElement):string[] {
    if (!row.hasAttribute('data-batch-selected')) {
      return [];
    }

    return Array.from(this.element.querySelectorAll<HTMLElement>(`${itemSelector}[data-batch-selected]`))
      .map((selected) => selected.getAttribute('data-sortable-lists--item-id-value')!);
  }

  private pointBatchActions(row:HTMLElement, projectIds:string[]):void {
    row.querySelectorAll<HTMLAnchorElement>(`a[${actionAttribute}]`).forEach((link) => {
      const base = link.getAttribute(actionAttribute) === 'switch' ? this.switchUrlValue : this.removeUrlValue;
      const url = new URL(base, window.location.origin);
      projectIds.forEach((id) => url.searchParams.append('project_ids[]', id));

      link.setAttribute('href', `${url.pathname}${url.search}`);
    });
  }
}
