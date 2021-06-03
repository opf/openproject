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
//++

import { APIv3GettableResource, APIv3ResourceCollection } from "core-app/modules/apiv3/paths/apiv3-resource";
import { APIv3QueryPaths } from "core-app/modules/apiv3/endpoints/queries/apiv3-query-paths";
import { QueryResource } from "core-app/modules/hal/resources/query-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Apiv3QueryForm } from "core-app/modules/apiv3/endpoints/queries/apiv3-query-form";
import { Observable } from "rxjs";
import { QueryFormResource } from "core-app/modules/hal/resources/query-form-resource";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { Apiv3ListParameters, listParamsString } from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { QueryFiltersService } from "core-components/wp-query/query-filters.service";
import { HalPayloadHelper } from "core-app/modules/hal/schemas/hal-payload.helper";

export class APIv3QueriesPaths extends APIv3ResourceCollection<QueryResource, APIv3QueryPaths> {
  @InjectField() private queryFilters:QueryFiltersService;

  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'queries', APIv3QueryPaths);
  }

  // Static paths
  // /api/v3/queries/form
  readonly form = this.subResource('form', Apiv3QueryForm);

  // /api/v3/queries/default
  readonly default = this.subResource<APIv3GettableResource<QueryResource>>('default');

  // /api/v3/queries/filter_instance_schemas/:id
  readonly filter_instance_schemas = new APIv3ResourceCollection(this.apiRoot, this.path, 'filter_instance_schemas');

  /**
   * Load a list of queries with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<QueryResource>> {
    return this
      .halResourceService
      .get<CollectionResource<QueryResource>>(this.path + listParamsString(params));
  }

  /**
   * Locate a query for the response for the given query request.
   * This might be the default query or an existing query identified by its ID.
   * @param queryData
   * @param queryId
   * @param projectIdentifier
   */
  public find(queryData:Object, queryId?:string, projectIdentifier?:string|null|undefined):Observable<QueryResource> {
    let path:string;

    if (queryId) {
      path = this.apiRoot.queries.id(queryId).toString();
    } else {
      path = this.apiRoot.withOptionalProject(projectIdentifier).queries.default.toString();
    }

    return this
      .halResourceService
      .get<QueryResource>(path, queryData);
  }


  /**
   * Stream the response for the given query request
   *
   * @param params
   */
  public parameterised(params:Object):Observable<QueryResource> {
    return this.halResourceService
      .get<QueryResource>(
        this.default.path,
        params
      );
  }

  /**
   * Create a new query resource
   *
   * @param payload Payload object or query HAL resource
   * @param form Form resource, needed when QueryResource is passed
   */
  public post(payload:QueryResource|Object, form?:QueryFormResource):Observable<QueryResource> {
    if (payload instanceof QueryResource && form) {
      // Extracting requires having the filter schemas loaded as the dependencies
      this.queryFilters.mapSchemasIntoFilters(payload, form);
      payload = HalPayloadHelper.extractPayloadFromSchema(payload, form.schema);
    }

    return this
      .halResourceService
      .post<QueryResource>(
        this.apiRoot.queries.path, payload
      );
  }

  /**
   * Invert the starred state of the given query
   *
   * @param query
   */
  public toggleStarred(query:QueryResource):Promise<unknown> {
    if (query.starred) {
      return query.unstar();
    } else {
      return query.star();
    }
  }

  /**
   * Filter for non-hidden queries
   *
   * @param projectIdentifier
   */
  public filterNonHidden(projectIdentifier?:string|null):Observable<CollectionResource<QueryResource>> {
    const listParams:Apiv3ListParameters = {
      filters: [['hidden', '=', ['f']]]
    };

    if (projectIdentifier) {
      // all queries with the provided projectIdentifier
      listParams.filters!.push(['project_identifier', '=', [projectIdentifier]]);
    } else {
      // all queries having no project (i.e. being global)
      listParams.filters!.push(['project', '!*', []]);
    }

    return this.list(listParams);
  }
}
