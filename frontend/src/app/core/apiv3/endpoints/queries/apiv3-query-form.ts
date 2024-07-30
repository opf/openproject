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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { Observable } from 'rxjs';
import * as URI from 'urijs';
import { map, tap } from 'rxjs/operators';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { QueryFiltersService } from 'core-app/features/work-packages/components/wp-query/query-filters.service';

export class ApiV3QueryForm extends ApiV3FormResource<QueryFormResource> {
  @InjectField() private queryFilters:QueryFiltersService;

  /**
   * Load the query form for the given existing (or new) query resource
   * @param query
   */
  public load(query:QueryResource):Observable<[QueryFormResource, QueryResource]> {
    // We need a valid payload so that we
    // can check whether form saving is possible.
    // The query needs a name to be valid.
    const payload:any = {
      name: query.name || '!!!__O__o__O__!!!',
    };

    if (query.project) {
      payload._links = {
        project: {
          href: query.project.href,
        },
      };
    }

    const { path } = this.apiRoot.queries.withOptionalId(query.id).form;
    return this.halResourceService
      .post<QueryFormResource>(path, payload)
      .pipe(
        tap((form) => this.queryFilters.setSchemas(form.$embedded.schema.$embedded.filtersSchemas)),
        map((form) => [form, this.buildQueryResource(form)]),
      );
  }

  /**
   * Load the query form only with the given query props.
   *
   * @param params
   * @param queryId
   * @param projectIdentifier
   * @param payload
   */
  public loadWithParams(params:{ [key:string]:unknown }, queryId:string|null|undefined, projectIdentifier:string|undefined|null, payload:any = {}):Observable<[QueryFormResource, QueryResource]> {
    // We need a valid payload so that we
    // can check whether form saving is possible.
    // The query needs a name to be valid.
    if (!queryId && !payload.name) {
      payload.name = '!!!__O__o__O__!!!';
    }

    if (projectIdentifier) {
      payload._links = payload._links || {};
      payload._links.project = {
        href: this.apiRoot.projects.id(projectIdentifier).toString(),
      };
    }

    const { path } = this.apiRoot.queries.withOptionalId(queryId).form;
    const href = URI(path).search(params).toString();
    return this.halResourceService
      .post<QueryFormResource>(href, payload)
      .pipe(
        tap((form) => this.queryFilters.setSchemas(form.$embedded.schema.$embedded.filtersSchemas)),
        map((form) => [form, this.buildQueryResource(form)]),
      );
  }

  protected buildQueryResource(form:QueryFormResource):QueryResource {
    return this.halResourceService.createHalResourceOfType<QueryResource>('Query', form.payload);
  }
}
