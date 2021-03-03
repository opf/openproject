//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See docs/COPYRIGHT.rdoc for more details.
//++    Ng1FieldControlsWrapper,

import { Injectable } from "@angular/core";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { NEVER, Observable, throwError } from "rxjs";
import { filter, map, take, tap } from "rxjs/operators";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { multiInput } from "reactivestates";
import { TransitionService } from "@uirouter/core";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { CurrentProjectService } from "core-components/projects/current-project.service";

export type SupportedAttributeModels = 'project'|'workPackage';

@Injectable({ providedIn: "root" })
export class AttributeModelLoaderService {

  text = {
    not_found: this.I18n.t('js.editor.macro.attribute_reference.not_found')
  };

  // Cache the required model/id values because
  // we may need to expensively filter for them
  private cache$ = multiInput<HalResource>();

  constructor(readonly apiV3Service:APIV3Service,
              readonly transitions:TransitionService,
              readonly currentProject:CurrentProjectService,
              readonly I18n:I18nService) {

    // Clear cached values whenever leaving the page
    transitions.onStart({}, () => {
      this.cache$.clear();
      return true;
    });
  }

  /**
   * Require a given model with an id reference to be loaded.
   * This might be a singular resource identified by an actual integer ID or
   * another (e.g., work package subject) reference.
   *
   * @param model
   * @param id
   */
  require(model:SupportedAttributeModels, id:string):Promise<HalResource|null> {
    const identifier = `${model}-${id}`;
    const state = this.cache$.get(identifier);

    if (state.isPristine()) {
      const promise = this
        .load(model, id)
        .pipe(
          filter(response => !!response)
        )
        .toPromise();
      state.clearAndPutFromPromise(promise as PromiseLike<HalResource>);

      return promise;
    }

    return state
      .values$()
      .pipe(
        take(1),
        tap(val => console.log("VAL " + val), err => console.error('ERR ' + err))
      )
      .toPromise();
  }

  private load(model:SupportedAttributeModels, id?:string|undefined|null):Observable<HalResource|null> {
    switch (model) {
    case 'workPackage':
      return this.loadWorkPackage(id);
    case 'project':
      return this.loadProject(id);
    default:
      return NEVER;
    }
  }

  private loadProject(id:string|undefined|null) {
    id = id || this.currentProject.id;

    if (!id) {
      return throwError(this.text.not_found);
    }

    return this
      .apiV3Service
      .projects
      .id(id)
      .get()
      .pipe(
        take(1)
      );
  }

  private loadWorkPackage(id?:string|undefined|null) {
    if (!id) {
      return throwError(this.text.not_found);
    }

    // Return global reference to the subject
    if (/^[1-9]\d*$/.test(id)) {
      return this
        .apiV3Service
        .work_packages
        .id(id)
        .get()
        .pipe(
          take(1)
        );
    }

    // Otherwise, look for subject IN the current project (if we're in project context)
    return this
      .apiV3Service
      .withOptionalProject(this.currentProject.id)
      .work_packages
      .filterBySubjectOrId(id, false, { pageSize: '1' })
      .get()
      .pipe(
        take(1),
        map(collection => collection.elements[0] || null)
      );
  }
}
