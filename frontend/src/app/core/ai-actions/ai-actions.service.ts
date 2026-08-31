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
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';

export interface IAiTextTransformAction {
  id:number;
  label:string;
  position:number;
}

interface IActionListResponse {
  actions:IAiTextTransformAction[];
}

interface IEditorContextResource {
  id?:string|null;
  _type?:string;
  $links?:{ type?:{ href?:string } };
}

// Counterpart of the CKEditor AI actions dropdown, which only renders the
// list and reports the selection. Availability is decided entirely
// server-side; an empty list keeps the dropdown hidden.
@Injectable({ providedIn: 'root' })
export class AiActionsService {
  private http = inject(HttpClient);

  private pathHelper = inject(PathHelperService);

  async actionsFor(resource:IEditorContextResource|undefined, field:string|undefined):Promise<IAiTextTransformAction[]> {
    const params = this.contextParams(resource, field);

    if (params === null) {
      return [];
    }

    try {
      const response = await firstValueFrom(
        this.http.get<IActionListResponse>(this.listPath(), { params }),
      );
      return (response.actions || []).sort((a, b) => a.position - b.position);
    } catch {
      return [];
    }
  }

  // Entry point for the editor plugin; the execute flow (request, loading
  // state, diff preview, accept/reject) lands in a follow-up.
  run(_action:IAiTextTransformAction, _editor:unknown, _resource:IEditorContextResource|undefined):Promise<void> {
    return Promise.resolve();
  }

  private listPath():string {
    return `${this.pathHelper.staticBase}/ai/text_transform_actions`;
  }

  // v1 applies to the work package description editor only. Everything else
  // (comments, wiki pages, meeting notes) resolves to "no actions".
  private contextParams(resource:IEditorContextResource|undefined, field:string|undefined):Record<string, string>|null {
    if (!resource || field !== 'description' || resource._type !== 'WorkPackage') {
      return null;
    }

    if (resource.id && resource.id !== 'new') {
      return { work_package_id: resource.id };
    }

    const typeHref = resource.$links?.type?.href;
    const typeId = typeHref && idFromLink(typeHref);
    return typeId ? { type_id: typeId } : null;
  }
}
