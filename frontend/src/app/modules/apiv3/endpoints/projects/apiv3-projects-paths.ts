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

import { APIv3ProjectPaths } from "core-app/modules/apiv3/endpoints/projects/apiv3-project-paths";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { SchemaResource } from "core-app/modules/hal/resources/schema-resource";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface,
  listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { Observable } from "rxjs";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { CachableAPIV3Collection } from "core-app/modules/apiv3/cache/cachable-apiv3-collection";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { ProjectCache } from "core-app/modules/apiv3/endpoints/projects/project.cache";

export class APIv3ProjectsPaths
  extends CachableAPIV3Collection<ProjectResource, APIv3ProjectPaths>
  implements Apiv3ListResourceInterface<ProjectResource> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'projects', APIv3ProjectPaths);
  }

  // /api/v3/projects/schema
  public readonly schema = this.subResource<SchemaResource>('schema');

  /**
   * Load a list of project with a given list parameter filter
   *
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<ProjectResource>> {
    return this
      .halResourceService
      .get<CollectionResource<ProjectResource>>(this.path + listParamsString(params))
      .pipe(
        this.cacheResponse()
      );
  }

  protected createCache():StateCacheService<ProjectResource> {
    return new ProjectCache(this.injector, this.states.projects);
  }
}
