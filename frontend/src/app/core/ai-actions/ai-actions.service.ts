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
import { ConfigurationService } from 'core-app/core/config/configuration.service';
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

const FEATURE_FLAG = 'aiTextTransformActions';
const LAST_ACTION_STORAGE_KEY = 'openproject.ai_actions.last_action_id';

/**
 * Counterpart of the CKEditor Assistant button, which only renders the list and reports the chosen
 * action. Availability is decided server-side; an empty list keeps the button hidden.
 */
@Injectable({ providedIn: 'root' })
export class AiActionsService {
  private http = inject(HttpClient);

  private pathHelper = inject(PathHelperService);

  private configuration = inject(ConfigurationService);

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

  run(action:IAiTextTransformAction):Promise<void> {
    this.rememberAction(action);

    return Promise.resolve();
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

    if (!isNewResource(workPackage)) {
      return paths.aiTextTransformActionsByWorkPackage(workPackage.id!);
    }

    const projectId = this.linkedId(workPackage.$links?.project?.href);
    const typeId = this.linkedId(workPackage.$links?.type?.href);

    return projectId && typeId ? paths.aiTextTransformActionsByProject(projectId, typeId) : null;
  }

  private linkedId(href:string|undefined):string|null {
    return href ? idFromLink(href) : null;
  }
}
