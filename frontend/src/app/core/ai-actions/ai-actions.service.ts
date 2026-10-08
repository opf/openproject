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

import { inject, Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { firstValueFrom, Observable, timeout, TimeoutError } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { IEditorWithContent, replaceEditorContent } from 'core-app/core/ai-actions/editor-content';

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

interface IRunEvent {
  seq:number;
  kind:'status'|'text_delta'|'completed'|'error';
  payload:{ text?:string; message?:string; delta?:string; status?:string };
}

interface IRunResource {
  id:string;
  status:'queued'|'running'|'succeeded'|'failed'|'cancelled';
  events:IRunEvent[];
}

interface IRunOutcome {
  status:IRunResource['status'];
  text?:string;
  message?:string;
}

interface IRunState {
  deadline:number;
  runId:string|null;
  editorGone:boolean;
  cancelRequested:boolean;
}

const TERMINAL_STATUSES = ['succeeded', 'failed', 'cancelled'];
const READ_ONLY_LOCK = 'ai-actions';
const MIN_POLL_DELAY = 400;
const MAX_POLL_DELAY = 1000;
const RUN_TIMEOUT = 200_000;
const REQUEST_TIMEOUT = 30_000;

// Counterpart of the CKEditor AI actions dropdown, which only renders the
// list and reports the selection. Availability is decided entirely
// server-side; an empty list keeps the dropdown hidden.
@Injectable({ providedIn: 'root' })
export class AiActionsService {
  private http = inject(HttpClient);

  private pathHelper = inject(PathHelperService);

  private toast = inject(ToastService);

  private I18n = inject(I18nService);

  delay = (ms:number):Promise<void> => new Promise((resolve) => { setTimeout(resolve, ms); });

  requestTimeout = REQUEST_TIMEOUT;

  private busyEditors = new WeakSet<IEditorWithContent>();

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

  async run(action:IAiTextTransformAction, editor:IEditorWithContent, resource:IEditorContextResource|undefined):Promise<void> {
    const context = this.runContext(resource);

    if (context === null || this.busyEditors.has(editor)) {
      return;
    }

    this.busyEditors.add(editor);
    const state:IRunState = {
      deadline: Date.now() + RUN_TIMEOUT, runId: null, editorGone: false, cancelRequested: false,
    };
    editor.once('destroy', () => {
      state.editorGone = true;
      void this.cancelRun(state);
    });
    editor.enableReadOnlyMode(READ_ONLY_LOCK);
    const notice = this.toast.addNotice(this.I18n.t('js.editor.ai_actions.running', { action: action.label }));

    try {
      const run = await this.createRun(action, editor.getData(), context);
      state.runId = run.id;
      const outcome = await this.awaitOutcome(state);

      if (state.editorGone) {
        return;
      }

      if (outcome.status === 'succeeded' && outcome.text?.trim()) {
        replaceEditorContent(editor, outcome.text);
        this.toast.addSuccess(this.I18n.t('js.editor.ai_actions.succeeded', { action: action.label }));
      } else if (outcome.status !== 'cancelled') {
        this.toast.addError(outcome.message ?? this.I18n.t('js.editor.ai_actions.failed'));
      }
    } catch (error) {
      void this.cancelRun(state);
      if (!state.editorGone) {
        this.toast.addError(this.errorMessage(error));
      }
    } finally {
      this.busyEditors.delete(editor);
      this.toast.remove(notice);
      if (!state.editorGone) {
        editor.disableReadOnlyMode(READ_ONLY_LOCK);
      }
    }
  }

  private createRun(action:IAiTextTransformAction, content:string, context:Record<string, string>):Promise<IRunResource> {
    return this.request(this.http.post<IRunResource>(this.runsPath(), { actionId: action.id, content, ...context }));
  }

  private async awaitOutcome(state:IRunState):Promise<IRunOutcome> {
    const outcome:IRunOutcome = { status: 'queued' };
    let cursor = 0;
    let pollDelay = MIN_POLL_DELAY;

    while (!TERMINAL_STATUSES.includes(outcome.status)) {
      if (state.editorGone) {
        await this.cancelRun(state);
        return { status: 'cancelled' };
      }

      if (Date.now() > state.deadline) {
        await this.cancelRun(state);
        return { status: 'failed', message: this.I18n.t('js.editor.ai_actions.timeout') };
      }

      const run = await this.request(this.http.get<IRunResource>(`${this.runsPath()}/${state.runId}?after=${cursor}`));
      outcome.status = run.status;

      run.events.forEach((event) => {
        cursor = Math.max(cursor, event.seq);
        if (event.kind === 'completed') {
          outcome.text = event.payload.text;
        } else if (event.kind === 'error') {
          outcome.message = event.payload.message;
        }
      });

      if (!TERMINAL_STATUSES.includes(outcome.status)) {
        await this.delay(pollDelay);
        pollDelay = Math.min(MAX_POLL_DELAY, pollDelay + 100);
      }
    }

    return outcome;
  }

  private cancelRun(state:IRunState):Promise<unknown> {
    if (state.cancelRequested || state.runId === null) {
      return Promise.resolve();
    }

    state.cancelRequested = true;
    return this.request(this.http.post(`${this.runsPath()}/${state.runId}/cancel`, {})).catch(() => undefined);
  }

  private request<T>(source:Observable<T>):Promise<T> {
    return firstValueFrom(source.pipe(timeout(this.requestTimeout)));
  }

  private errorMessage(error:unknown):string {
    if (error instanceof TimeoutError) {
      return this.I18n.t('js.editor.ai_actions.timeout');
    }

    if (error instanceof HttpErrorResponse) {
      const message = (error.error as { message?:string }|null)?.message;
      if (message) {
        return message;
      }
    }

    return this.I18n.t('js.editor.ai_actions.failed');
  }

  private runsPath():string {
    return `${this.pathHelper.api.v3.apiV3Base}/ai_text_transform_runs`;
  }

  // v1 applies to the work package description editor only. Everything else
  // (comments, wiki pages, meeting notes) resolves to "no actions".
  private listPath(resource:IEditorContextResource|undefined, field:string|undefined):string|null {
    const context = field === 'description' ? this.runContext(resource) : null;

    if (context === null) {
      return null;
    }

    const base = this.pathHelper.api.v3.apiV3Base;

    if (context.workPackageId) {
      return `${base}/work_packages/${context.workPackageId}/ai_text_transform_actions`;
    }

    return `${base}/projects/${context.projectId}/ai_text_transform_actions?typeId=${context.typeId}`;
  }

  private runContext(resource:IEditorContextResource|undefined):Record<string, string>|null {
    if (resource?._type !== 'WorkPackage') {
      return null;
    }

    if (resource.id && resource.id !== 'new') {
      return { workPackageId: resource.id };
    }

    const projectId = this.linkedId(resource.$links?.project?.href);
    const typeId = this.linkedId(resource.$links?.type?.href);

    return projectId && typeId ? { projectId, typeId } : null;
  }

  private linkedId(href:string|undefined):string|null {
    return href ? idFromLink(href) : null;
  }
}
