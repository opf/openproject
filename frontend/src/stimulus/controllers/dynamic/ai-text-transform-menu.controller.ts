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

import { Controller } from '@hotwired/stimulus';

interface ActionResource {
  id:number;
  label:string;
}

interface ActionCollection {
  _embedded:{ elements:ActionResource[] };
}

export interface AiTextTransformStartDetail {
  actionId:number;
  label:string;
  editorWrapper:HTMLElement;
  context:Record<string, number>;
}

export const AI_TEXT_TRANSFORM_START_EVENT = 'op:ai-text-transform:start';

/**
 * Demo (AI-126): the AI action menu next to the description editor's toolbar. It lists the
 * actions the API offers for the editor's context (AI-134) and asks the result popover to
 * run the chosen one. The menu stays hidden when the API offers nothing.
 */
export default class AiTextTransformMenuController extends Controller<HTMLElement> {
  static targets = ['template'];

  static values = { listUrl: String, context: Object };

  declare readonly templateTarget:HTMLButtonElement;
  declare readonly listUrlValue:string;
  declare readonly contextValue:Record<string, number>;

  connect():void {
    void this.loadActions();
  }

  run(event:Event):void {
    const item = event.currentTarget as HTMLElement;
    const editorWrapper = this.element.closest('op-ckeditor')?.querySelector<HTMLElement>('.op-ckeditor-source-element');
    if (!editorWrapper) {
      return;
    }

    const detail:AiTextTransformStartDetail = {
      actionId: Number(item.dataset.actionId),
      label: item.dataset.actionLabel ?? '',
      editorWrapper,
      context: this.contextValue,
    };
    window.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_START_EVENT, { detail }));
  }

  private async loadActions():Promise<void> {
    const response = await fetch(this.listUrlValue, {
      credentials: 'same-origin',
      headers: { Accept: 'application/hal+json', 'X-Requested-With': 'XMLHttpRequest' },
    });
    if (!response.ok) {
      return;
    }

    const collection = await response.json() as ActionCollection;
    const actions = collection._embedded.elements;
    if (actions.length === 0) {
      return;
    }

    actions.forEach((action) => this.appendItem(action));
    this.element.hidden = false;
  }

  private appendItem(action:ActionResource):void {
    const templateItem = this.templateTarget.closest('li');
    if (!templateItem?.parentElement) {
      return;
    }

    const item = templateItem.cloneNode(true) as HTMLLIElement;
    const button = item.querySelector<HTMLButtonElement>('button');
    const label = item.querySelector<HTMLElement>('.ActionListItem-label');
    if (!button || !label) {
      return;
    }

    item.hidden = false;
    button.id = `${button.id}-${action.id}`;
    button.type = 'button';
    button.removeAttribute('data-ai-text-transform-menu-target');
    button.dataset.actionId = String(action.id);
    button.dataset.actionLabel = action.label;
    label.textContent = action.label;
    templateItem.parentElement.append(item);
  }
}
