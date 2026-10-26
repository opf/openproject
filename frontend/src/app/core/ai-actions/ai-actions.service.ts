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

import { inject, Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { IEditorWithContent } from 'core-app/core/ai-actions/editor-content';
import {
  AI_TEXT_TRANSFORM_APPLIED_EVENT,
  AI_TEXT_TRANSFORM_APPLY_EVENT,
  AI_TEXT_TRANSFORM_CLOSED_EVENT,
  AiTextTransformApplyDetail,
  AiTextTransformAppliedDetail,
  AiTextTransformScope,
} from 'core-app/core/ai-actions/ai-text-transform-events';

export interface IAiTextTransformAction {
  id:number;
  label:string;
  position:number;
  injectsTypeTemplate:boolean;
}

interface IEditorContextResource {
  id?:string|null;
  _type?:string;
  $links?:{
    type?:{ href?:string };
    project?:{ href?:string };
  };
}

interface IPendingRequest {
  editor:IEditorWithContent;
  scope:AiTextTransformScope;
}

export const AI_SELECTION_MARKER = 'ai-text-transform:selection';
const LAST_ACTION_STORAGE_KEY = 'openproject.ai_actions.last_action_id';
// Demo only: ?ai_demo_fault=blocked or =failed in the page URL makes the next runs end that way.
const DEMO_FAULT_PARAM = 'ai_demo_fault';

/**
 * Counterpart of the CKEditor Assistant button, which only renders the list and reports the chosen
 * action. Availability is decided server-side; an empty list keeps the button hidden.
 *
 * Demo (AI-126 demo branch, until AI-176): run requests the server-rendered result pane through
 * Turbo and applies the text the pane hands back to the editor model.
 */
@Injectable({ providedIn: 'root' })
export class AiActionsService {
  private http = inject(HttpClient);

  private pathHelper = inject(PathHelperService);

  private turboRequests = inject(TurboRequestsService);

  private pending = new Map<string, IPendingRequest>();

  constructor() {
    document.addEventListener(AI_TEXT_TRANSFORM_APPLY_EVENT, (event) => {
      this.apply((event as CustomEvent<AiTextTransformApplyDetail>).detail);
    });
    document.addEventListener(AI_TEXT_TRANSFORM_CLOSED_EVENT, (event) => {
      this.closed((event as CustomEvent<{ requestId:string }>).detail.requestId);
    });
  }

  async actionsFor(resource:IEditorContextResource|undefined, field:string|undefined):Promise<IAiTextTransformAction[]> {
    const path = this.listPath(resource, field);

    if (path === null) {
      return [];
    }

    try {
      const collection = await firstValueFrom(this.http.get<IHALCollection<IAiTextTransformAction>>(path));
      return collection._embedded.elements
        .map(({ id, label, position, injectsTypeTemplate }) => ({ id, label, position, injectsTypeTemplate }))
        .sort((a, b) => a.position - b.position);
    } catch {
      return [];
    }
  }

  defaultAction(actions:IAiTextTransformAction[]):IAiTextTransformAction|undefined {
    const lastActionId = this.lastActionId();

    return actions.find((action) => action.id === lastActionId) ?? actions[0];
  }

  async run(action:IAiTextTransformAction, editor?:IEditorWithContent, resource?:IEditorContextResource):Promise<void> {
    this.rememberAction(action);
    if (!editor) {
      return;
    }

    this.forgetRequestsOf(editor);

    // An action that injects the type template describes the whole description,
    // so it always runs on the document, even with text selected.
    const selection = action.injectsTypeTemplate ? null : this.markSelection(editor);
    const scope:AiTextTransformScope = selection === null ? 'document' : 'selection';
    const requestId = crypto.randomUUID();
    this.pending.set(requestId, { editor, scope });

    await this.turboRequests.request(`${this.pathHelper.staticBase}/ai/text_transform_panes`, {
      method: 'POST',
      body: this.paneRequest({
        request_id: requestId,
        action_id: String(action.id),
        scope,
        input: selection ?? editor.getData(),
        ...this.paneContext(resource, this.fieldOf(editor)),
      }),
      headers: { Accept: 'text/vnd.turbo-stream.html' },
      credentials: 'same-origin',
    });
  }

  // Only results for requests started here are applied: the apply event comes from a turbo
  // stream, and an injected stream must not be able to write into the editor.
  private apply({ requestId, text }:AiTextTransformApplyDetail):void {
    const request = this.pending.get(requestId);
    if (!request) {
      return;
    }

    const { editor, scope } = request;
    const marker = editor.model.markers.get(AI_SELECTION_MARKER);
    const ok = scope === 'document' || marker !== null;

    if (ok) {
      // insertContent keeps the undo history, unlike setData.
      editor.model.change((writer) => {
        const range = marker && scope === 'selection'
          ? marker.getRange()
          : editor.model.createRangeIn(editor.model.document.getRoot());
        editor.model.insertContent(editor.data.parse(text), range);
        if (marker) {
          writer.removeMarker(AI_SELECTION_MARKER);
        }
      });
      this.pending.delete(requestId);
    }

    const detail:AiTextTransformAppliedDetail = { requestId, ok };
    window.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_APPLIED_EVENT, { detail }));
  }

  private closed(requestId:string):void {
    const request = this.pending.get(requestId);
    if (request) {
      this.pending.delete(requestId);
      this.clearMarker(request.editor);
    }
  }

  private forgetRequestsOf(editor:IEditorWithContent):void {
    this.pending.forEach((request, requestId) => {
      if (request.editor === editor) {
        this.pending.delete(requestId);
      }
    });
  }

  private markSelection(editor:IEditorWithContent):string|null {
    this.clearMarker(editor);
    const { selection } = editor.model.document;
    if (selection.isCollapsed) {
      return null;
    }

    const markdown = editor.data.stringify(editor.model.getSelectedContent(selection));
    if (markdown.trim() === '') {
      return null;
    }

    editor.model.change((writer) => {
      writer.addMarker(AI_SELECTION_MARKER, { range: selection.getFirstRange(), usingOperation: false });
    });
    return markdown;
  }

  private clearMarker(editor:IEditorWithContent):void {
    if (editor.model.markers.get(AI_SELECTION_MARKER)) {
      editor.model.change((writer) => writer.removeMarker(AI_SELECTION_MARKER));
    }
  }

  private paneRequest(fields:Record<string, string>):FormData {
    const body = new FormData();
    Object.entries(fields).forEach(([key, value]) => body.set(key, value));

    const demoFault = new URLSearchParams(window.location.search).get(DEMO_FAULT_PARAM);
    if (demoFault) {
      body.set('demo_fault', demoFault);
    }
    return body;
  }

  // The work package description runs with its context; every other editor runs without one.
  private paneContext(resource:IEditorContextResource|undefined, field:string|undefined):Record<string, string> {
    if (resource?._type !== 'WorkPackage' || field !== 'description') {
      return {};
    }

    if (resource.id && resource.id !== 'new') {
      return { work_package_id: resource.id };
    }

    const projectId = this.linkedId(resource.$links?.project?.href);
    const typeId = this.linkedId(resource.$links?.type?.href);
    return projectId && typeId ? { project_id: projectId, type_id: typeId } : {};
  }

  private fieldOf(editor:IEditorWithContent):string|undefined {
    const openProject = editor.config?.get('openProject') as { context?:{ field?:string } }|undefined;
    return openProject?.context?.field;
  }

  private rememberAction(action:IAiTextTransformAction):void {
    this.withStorage((storage) => storage.setItem(LAST_ACTION_STORAGE_KEY, String(action.id)));
  }

  private lastActionId():number|null {
    const stored = this.withStorage((storage) => storage.getItem(LAST_ACTION_STORAGE_KEY));

    return stored == null ? null : Number(stored);
  }

  private withStorage<T>(access:(storage:Storage) => T):T|null {
    try {
      return access(window.localStorage);
    } catch {
      return null;
    }
  }

  private listPath(resource:IEditorContextResource|undefined, field:string|undefined):string|null {
    if (resource?._type === 'WorkPackage' && field === 'description') {
      return this.workPackageListPath(resource);
    }

    return this.pathHelper.api.v3.aiTextTransformActions();
  }

  private workPackageListPath(workPackage:IEditorContextResource):string|null {
    const paths = this.pathHelper.api.v3;

    if (workPackage.id && workPackage.id !== 'new') {
      return paths.aiTextTransformActionsByWorkPackage(workPackage.id);
    }

    const projectId = this.linkedId(workPackage.$links?.project?.href);
    const typeId = this.linkedId(workPackage.$links?.type?.href);

    return projectId && typeId ? paths.aiTextTransformActionsByProject(projectId, typeId) : null;
  }

  private linkedId(href:string|undefined):string|null {
    return href ? idFromLink(href) : null;
  }
}
