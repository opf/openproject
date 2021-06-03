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

import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { APIv3GettableResource } from "core-app/modules/apiv3/paths/apiv3-resource";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { buildApiV3Filter } from "core-components/api/api-v3/api-v3-filter-builder";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface, listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";

export class Apiv3AvailableProjectsPaths
  extends APIv3GettableResource<CollectionResource<ProjectResource>>
  implements Apiv3ListResourceInterface<ProjectResource> {

  /**
   * Load a list of available projects with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<ProjectResource>> {
    return this
      .halResourceService
      .get<CollectionResource<ProjectResource>>(this.path + listParamsString(params));
  }

  /**
   * Performs a request against the available_projects endpoint
   * to see whether this is contained
   *
   * Returns whether the given id exists in the set
   * of available projects
   *
   * @param projectId
   */
  public exists(projectId:string):Observable<boolean> {
    return this
      .halResourceService
      .get<CollectionResource<ProjectResource>>(
        this.path,
        { filters: buildApiV3Filter('id', '=', [projectId]).toJson() }
      )
      .pipe(
        map(collection => collection.count > 0)
      );
  }

}
