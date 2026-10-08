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
import type { EditorSelectionResult } from 'core-app/shared/components/editor/components/ckeditor/ckeditor-setup.service';

interface ActionResource {
  id:number;
  label:string;
  injectsTypeTemplate:boolean;
}

export type AiTextTransformScope = 'document'|'selection';

interface ActionCollection {
  _embedded:{ elements:ActionResource[] };
}

export interface AiTextTransformStartDetail {
  requestId:string;
  actionId:number;
  label:string;
  context:Record<string, number>;
  scope:AiTextTransformScope;
  input:string;
}

export interface AiTextTransformApplyDetail {
  requestId:string;
  scope:AiTextTransformScope;
  text:string;
}

export interface AiTextTransformAppliedDetail {
  requestId:string;
  ok:boolean;
}

export const AI_TEXT_TRANSFORM_START_EVENT = 'op:ai-text-transform:start';
export const AI_TEXT_TRANSFORM_APPLIED_EVENT = 'op:ai-text-transform:applied';
// Dispatched by the server through the dispatchEvent turbo stream action.
export const AI_TEXT_TRANSFORM_APPLY_EVENT = 'op-dispatched:ai-text-transform:apply';
export const AI_TEXT_TRANSFORM_CLOSED_EVENT = 'op-dispatched:ai-text-transform:closed';

/**
 * Demo (AI-126): the AI action menu next to the description editor's toolbar, standing in for the
 * CKEditor plugin (AI-101). It lists the actions the API offers for the editor's context (AI-134),
 * asks the result pane to run the chosen one and applies the result the pane hands back. The menu
 * stays hidden when the API offers nothing.
 */
export default class AiTextTransformMenuController extends Controller<HTMLElement> {
  static targets = ['template'];

  static values = { listUrl: String, context: Object };

  declare readonly templateTarget:HTMLButtonElement;
  declare readonly listUrlValue:string;
  declare readonly contextValue:Record<string, number>;

  // Only results for requests this menu started are applied: the apply event comes from a turbo
  // stream, and an injected stream must not be able to write into the editor.
  private readonly pending = new Map<string, { wrapper:HTMLElement; scope:AiTextTransformScope }>();

  private readonly onApply = (event:Event) => this.apply((event as CustomEvent<AiTextTransformApplyDetail>).detail);
  private readonly onClosed = (event:Event) => this.closed((event as CustomEvent<{ requestId:string }>).detail);

  connect():void {
    document.addEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    document.addEventListener(AI_TEXT_TRANSFORM_CLOSED_EVENT, this.onClosed);
    void this.loadActions();
  }

  disconnect():void {
    document.removeEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, this.onApply);
    document.removeEventListener(AI_TEXT_TRANSFORM_CLOSED_EVENT, this.onClosed);
    this.pending.clear();
  }

  async run(event:Event):Promise<void> {
    const item = event.currentTarget as HTMLElement;
    const editorWrapper = this.element.closest('op-ckeditor')?.querySelector<HTMLElement>('.op-ckeditor-source-element');
    if (!editorWrapper) {
      return;
    }

    // An action that injects the type template describes the whole description,
    // so it always runs on the document, even with text selected.
    const selection = item.dataset.actionInjectsTemplate === 'true'
      ? { markdown: '', empty: true }
      : await this.readSelection(editorWrapper);
    if (selection.empty) {
      editorWrapper.dispatchEvent(new CustomEvent('op:ckeditor:clearSelectionMarker'));
    }

    const detail:AiTextTransformStartDetail = {
      requestId: crypto.randomUUID(),
      actionId: Number(item.dataset.actionId),
      label: item.dataset.actionLabel ?? '',
      context: this.contextValue,
      scope: selection.empty ? 'document' : 'selection',
      input: selection.empty ? await this.readDocument(editorWrapper) : selection.markdown,
    };
    this.pending.set(detail.requestId, { wrapper: editorWrapper, scope: detail.scope });
    window.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_START_EVENT, { detail }));
  }

  private apply({ requestId, text }:AiTextTransformApplyDetail):void {
    const request = this.pending.get(requestId);
    if (!request?.wrapper.isConnected) {
      return;
    }

    let ok = true;
    if (request.scope === 'selection') {
      request.wrapper.dispatchEvent(new CustomEvent('op:ckeditor:replaceSelection', {
        detail: { markdown: text, done: (replaced:boolean) => { ok = replaced; } },
      }));
    } else {
      request.wrapper.dispatchEvent(new CustomEvent('op:ckeditor:replaceDocument', { detail: text }));
    }

    if (ok) {
      this.pending.delete(requestId);
    }
    const detail:AiTextTransformAppliedDetail = { requestId, ok };
    window.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_APPLIED_EVENT, { detail }));
  }

  private closed({ requestId }:{ requestId:string }):void {
    const request = this.pending.get(requestId);
    if (!request) {
      return;
    }

    this.pending.delete(requestId);
    if (request.wrapper.isConnected) {
      request.wrapper.dispatchEvent(new CustomEvent('op:ckeditor:clearSelectionMarker'));
    }
  }

  private readSelection(wrapper:HTMLElement):Promise<EditorSelectionResult> {
    return new Promise((resolve) => {
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:getSelection', { detail: resolve }));
    });
  }

  private readDocument(wrapper:HTMLElement):Promise<string> {
    return new Promise((resolve) => {
      wrapper.dispatchEvent(new CustomEvent('op:ckeditor:getData', { detail: (data:string) => resolve(data) }));
    });
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
    button.dataset.actionInjectsTemplate = String(action.injectsTypeTemplate);
    label.textContent = action.label;
    templateItem.parentElement.append(item);
  }
}
