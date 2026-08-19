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
import { ApiV3UserPaths } from 'core-app/core/apiv3/endpoints/users/apiv3-user-paths';
import { Observable } from 'rxjs';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';

export class ApiV3UsersPaths extends ApiV3ResourceCollection<UserResource, ApiV3UserPaths> {
  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'users', ApiV3UserPaths);
  }

  // Static paths

  // /api/v3/users/me
  public readonly me = this.subResource('me', ApiV3UserPaths);

  // /api/v3/users/form
  public readonly form = this.subResource('form', ApiV3FormResource);

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
