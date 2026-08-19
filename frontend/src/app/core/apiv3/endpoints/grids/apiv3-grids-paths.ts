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

import { ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { ApiV3GridPaths } from 'core-app/core/apiv3/endpoints/grids/apiv3-grid-paths';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { ApiV3GridForm } from 'core-app/core/apiv3/endpoints/grids/apiv3-grid-form';
import { Observable } from 'rxjs';
import {
  ApiV3ListParameters,
  ApiV3ListResourceInterface,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';

export class ApiV3GridsPaths
  extends ApiV3ResourceCollection<GridResource, ApiV3GridPaths>
  implements ApiV3ListResourceInterface<GridResource> {
  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'grids', ApiV3GridPaths);
  }

  readonly form = this.subResource('form', ApiV3GridForm);

  /**
   * Load a list of grids with a given list parameter filter
   * @param params
   */
  public list(params?:ApiV3ListParameters):Observable<CollectionResource<GridResource>> {
    return this
      .halResourceService
      .get<CollectionResource<GridResource>>(this.path + listParamsString(params));
  }

  /**
   * Create a new GridResource
   *
   * @param resource
   * @param schema
   */
  public post(resource:GridResource, schema:SchemaResource|null = null):Observable<GridResource> {
    return this
      .halResourceService
      .post<GridResource>(
      this.path,
      this.form.extractPayload(resource, schema),
    );
  }
}
