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
import { Apiv3GroupPaths } from "core-app/modules/apiv3/endpoints/groups/apiv3-group-paths";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Observable } from "rxjs";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface,
  listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { GroupResource } from 'core-app/modules/hal/resources/group-resource';

export class Apiv3GroupsPaths
  extends APIv3ResourceCollection<GroupResource, Apiv3GroupPaths>
  implements Apiv3ListResourceInterface<GroupResource> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'groups', Apiv3GroupPaths);
  }

  /**
   * Load a list of placeholder users with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<GroupResource>> {
    return this
      .halResourceService
      .get<CollectionResource<GroupResource>>(this.path + listParamsString(params));
  }

  /**
   * Create a new GroupResource
   *
   * @param resource
   */
  public post(resource:{ name:string }):Observable<GroupResource> {
    return this
      .halResourceService
      .post<GroupResource>(
        this.path,
        resource,
      );
  }
}
