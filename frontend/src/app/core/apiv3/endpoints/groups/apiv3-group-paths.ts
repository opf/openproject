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
import { GroupResource } from 'core-app/features/hal/resources/group-resource';
import { Observable } from 'rxjs';

export class ApiV3GroupPaths extends ApiV3GettableResource<GroupResource> {
  /**
   * Update a placeholder user resource or payload
   * @param resource
   */
  public patch(resource:GroupResource|{ name:string }):Observable<GroupResource> {
    return this
      .halResourceService
      .patch<GroupResource>(this.path, {
      name: resource.name,
    });
  }

  /**
   * Delete a placeholder user resource
   */
  public delete():Observable<unknown> {
    return this
      .halResourceService
      .delete(this.path);
  }
}
