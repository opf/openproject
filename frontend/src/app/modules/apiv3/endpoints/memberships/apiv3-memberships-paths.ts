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

import {APIv3GettableResource, APIv3ResourceCollection} from "core-app/modules/apiv3/paths/apiv3-resource";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {Apiv3AvailableProjectsPaths} from "core-app/modules/apiv3/endpoints/projects/apiv3-available-projects-paths";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface, listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import {Observable} from "rxjs";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {MembershipResource, MembershipResourceEmbedded} from "core-app/modules/hal/resources/membership-resource";
import {Apiv3MembershipsForm} from "core-app/modules/apiv3/endpoints/memberships/apiv3-memberships-form";


export class Apiv3MembershipsPaths
  extends APIv3ResourceCollection<MembershipResource, APIv3GettableResource<MembershipResource>>
  implements Apiv3ListResourceInterface<MembershipResource> {

  // Static paths
  readonly form = this.subResource('form', Apiv3MembershipsForm);

  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'memberships');
  }

  /**
   * Load a list of membership entries with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<MembershipResource>> {
    return this
      .halResourceService
      .get<CollectionResource<MembershipResource>>(this.path + listParamsString(params));
  }


  // /api/v3/memberships/available_projects
  readonly available_projects = this.subResource('available_projects', Apiv3AvailableProjectsPaths);

  /**
   * Create a new MembershipResource
   *
   * @param resource
   */
  public post(resource:MembershipResourceEmbedded):Observable<MembershipResource> {
    const payload = this.form.extractPayload(resource);
    return this
      .halResourceService
      .post<MembershipResource>(
        this.path,
        payload,
      );
  }

}
