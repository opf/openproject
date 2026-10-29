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
import { v4 as uuidv4 } from 'uuid';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { IHALCollection } from 'core-app/core/apiv3/types/hal-collection.type';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import type { ICKEditorInstance } from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

export interface IAiTextTransformAction {
  id:number;
  label:string;
  position:number;
  injectsTypeTemplate:boolean;
}

interface IEditorContextResource {
  id:string|null;
  _type?:string;
  $links?:{
    type?:{ href?:string };
    project?:{ href?:string };
  };
}

export type IAiActionsEditor = Pick<ICKEditorInstance, 'getData'|'data'|'model'|'config'|'state'>;

interface IPendingRequest {
  requestId:string;
  editor:IAiActionsEditor;
}

type IDescriptionContext = { workPackageId:string }|{ projectId:string, typeId:string };

interface IAcceptedDetail {
  requestId:string;
  text:string;
}

const FEATURE_FLAG = 'aiTextTransformActions';
const LAST_ACTION_STORAGE_KEY = 'openproject.ai_actions.last_action_id';
export const AI_TEXT_TRANSFORM_ACCEPTED_EVENT = 'op-dispatched:ai-text-transform:accepted';
export const AI_TEXT_TRANSFORM_CLOSED_EVENT = 'op-dispatched:ai-text-transform:closed';
export const AI_TEXT_TRANSFORM_APPLIED_EVENT = 'op:ai-text-transform:applied';

/**
 * Counterpart of the CKEditor Assistant button, which only renders the list and reports the chosen
 * action. Availability is decided server-side; an empty list keeps the button hidden.
 */
@Injectable({ providedIn: 'root' })
export class AiActionsService {
  private http = inject(HttpClient);

  private pathHelper = inject(PathHelperService);

  private configuration = inject(ConfigurationService);

  private turboRequests = inject(TurboRequestsService);

  private toast = inject(ToastService);

  private I18n = inject(I18nService);

  // The page shows one result pane at a time, so only the request behind it can be applied.
  private pending:IPendingRequest|null = null;

  constructor() {
    document.addEventListener(AI_TEXT_TRANSFORM_ACCEPTED_EVENT, (event) => {
      this.apply((event as CustomEvent<IAcceptedDetail>).detail);
    });
    document.addEventListener(AI_TEXT_TRANSFORM_CLOSED_EVENT, (event) => {
      this.forget((event as CustomEvent<{ requestId:string }>).detail.requestId);
    });
  }

  async actionsFor(resource:IEditorContextResource|undefined, field:string|undefined):Promise<IAiTextTransformAction[]> {
    if (!this.configuration.activeFeatureFlags.includes(FEATURE_FLAG)) {
      return [];
    }

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

  async run(action:IAiTextTransformAction, editor:IAiActionsEditor, resource?:IEditorContextResource):Promise<void> {
    this.rememberAction(action);

    const requestId = uuidv4();

    const body = new FormData();
    Object.entries({
      request_id: requestId,
      action_id: String(action.id),
      scope: 'document',
      input: editor.getData(),
      ...this.paneContext(resource, editor.config.get('openProject.context.field') as string|undefined),
    }).forEach(([name, value]) => body.set(name, value));

    try {
      await this.turboRequests.request(
        this.pathHelper.aiTextTransformPanesPath(),
        { method: 'POST', body, headers: { Accept: 'text/vnd.turbo-stream.html' }, credentials: 'same-origin' },
        true,
      );
      this.pending = { requestId, editor };
    } catch {
      this.toast.addError(this.I18n.t('js.editor.ai_actions.start_failed'));
    }
  }

  // The accepted event arrives through a turbo stream, so only requests started here may write into an editor.
  // A destroyed editor gets no answer, so the pane tells the user it is gone.
  private apply({ requestId, text }:IAcceptedDetail):void {
    const editor = this.pending?.requestId === requestId ? this.pending.editor : null;
    this.forget(requestId);
    if (!editor || editor.state === 'destroyed') {
      return;
    }

    const { model, data } = editor;
    model.change(() => {
      model.insertContent(data.parse(text), model.createRangeIn(model.document.getRoot()!));
    });

    window.dispatchEvent(new CustomEvent(AI_TEXT_TRANSFORM_APPLIED_EVENT, { detail: { requestId, ok: true } }));
  }

  private forget(requestId:string):void {
    if (this.pending?.requestId === requestId) {
      this.pending = null;
    }
  }

  private paneContext(resource:IEditorContextResource|undefined, field:string|undefined):Record<string, string> {
    const context = this.descriptionContext(resource, field);
    if (!context) {
      return {};
    }

    return 'workPackageId' in context
      ? { work_package_id: context.workPackageId }
      : { project_id: context.projectId, type_id: context.typeId };
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
    const paths = this.pathHelper.api.v3;
    const context = this.descriptionContext(resource, field);

    if (context === undefined) {
      return paths.aiTextTransformActions();
    }
    if (context === null) {
      return null;
    }

    return 'workPackageId' in context
      ? paths.aiTextTransformActionsByWorkPackage(context.workPackageId)
      : paths.aiTextTransformActionsByProject(context.projectId, context.typeId);
  }

  // undefined for any editor but a work package description, null for a new work package without project or type.
  private descriptionContext(
    resource:IEditorContextResource|undefined,
    field:string|undefined,
  ):IDescriptionContext|null|undefined {
    if (resource?._type !== 'WorkPackage' || field !== 'description') {
      return undefined;
    }

    if (!isNewResource(resource)) {
      return { workPackageId: resource.id! };
    }

    const projectId = this.linkedId(resource.$links?.project?.href);
    const typeId = this.linkedId(resource.$links?.type?.href);

    return projectId && typeId ? { projectId, typeId } : null;
  }

  private linkedId(href:string|undefined):string|null {
    return href ? idFromLink(href) : null;
  }
}
