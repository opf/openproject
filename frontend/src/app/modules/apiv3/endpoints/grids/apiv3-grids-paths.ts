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

import { APIv3ResourceCollection } from "core-app/modules/apiv3/paths/apiv3-resource";
import { Apiv3GridPaths } from "core-app/modules/apiv3/endpoints/grids/apiv3-grid-paths";
import { GridResource } from "core-app/modules/hal/resources/grid-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import { Apiv3GridForm } from "core-app/modules/apiv3/endpoints/grids/apiv3-grid-form";
import { Observable } from "rxjs";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface,
  listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";

export class Apiv3GridsPaths
  extends APIv3ResourceCollection<GridResource, Apiv3GridPaths>
  implements Apiv3ListResourceInterface<GridResource> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'grids', Apiv3GridPaths);
  }

  readonly form = this.subResource('form', Apiv3GridForm);

  /**
   * Load a list of grids with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<GridResource>> {
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
        this.form.extractPayload(resource, schema)
      );
  }
}
