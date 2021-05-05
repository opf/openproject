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
import { APIv3UserPaths } from "core-app/modules/apiv3/endpoints/users/apiv3-user-paths";
import { Observable } from "rxjs";
import { UserResource } from "core-app/modules/hal/resources/user-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

export class Apiv3UsersPaths extends APIv3ResourceCollection<UserResource, APIv3UserPaths> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'users', APIv3UserPaths);
  }

  // Static paths

  // /api/v3/users/me
  public readonly me = this.path + '/me';

  /**
   * Create a new UserResource
   *
   * @param resource
   */
  public post(resource:{
    // TODO: The typing here could be a lot better
    login?:string,
    firstName?:string,
    lastName?:string,
    email?:string,
    admin?:boolean,
    language?:string,
    password?:string,
    auth_source?:string,
    identity_url?:string,
    status:'invited'|'active',
  }):Observable<UserResource> {
    return this
      .halResourceService
      .post<UserResource>(
        this.path,
        resource,
      );
  }
}
