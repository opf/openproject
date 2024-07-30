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

import { ApiV3GettableResource } from 'core-app/core/apiv3/paths/apiv3-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { ApiV3QueryOrder } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-order';
import { ApiV3QueryForm } from 'core-app/core/apiv3/endpoints/queries/apiv3-query-form';
import { Observable } from 'rxjs';
import { QueryFormResource } from 'core-app/features/hal/resources/query-form-resource';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';
import { QueryFiltersService } from 'core-app/features/work-packages/components/wp-query/query-filters.service';
import { HalPayloadHelper } from 'core-app/features/hal/schemas/hal-payload.helper';
import { PaginationObject } from 'core-app/shared/components/table-pagination/pagination-service';

export class ApiV3QueryPaths extends ApiV3GettableResource<QueryResource> {
  @InjectField() private queryFilters:QueryFiltersService;

  // Static paths
  readonly form = this.subResource('form', ApiV3QueryForm);

  // Order path
  readonly order = new ApiV3QueryOrder(this.injector, this.path, 'order');

  /**
   * Stream the response for the given query request
   * @param queryData
   */
  public parameterised(params:Object):Observable<QueryResource> {
    return this.halResourceService
      .get<QueryResource>(this.path, params);
  }

  /**
   * Update the given query
   * @param query
   * @param form
   */
  public patch(payload:QueryResource|Object, form?:QueryFormResource):Observable<QueryResource> {
    if (payload instanceof QueryResource && form) {
      // Extracting requires having the filter schemas loaded as the dependencies
      this.queryFilters.mapSchemasIntoFilters(payload, form);
      payload = HalPayloadHelper.extractPayloadFromSchema(payload, form.schema);
    }

    return this
      .halResourceService
      .patch<QueryResource>(this.path, payload);
  }

  /**
   * Delete the query
   */
  public delete() {
    return this
      .halResourceService
      .delete(this.path);
  }

  /**
   * Reload with a given pagination
   * @param pagination
   */
  public paginated(pagination:PaginationObject):Observable<QueryResource> {
    return this.parameterised(pagination);
  }
}
