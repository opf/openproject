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
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ApiV3FormResource } from 'core-app/core/apiv3/forms/apiv3-form-resource';
import { Observable } from 'rxjs';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { ApiV3AvailableProjectsPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-available-projects-paths';
import { ApiV3VersionPaths } from 'core-app/core/apiv3/endpoints/versions/apiv3-version-paths';

export class ApiV3VersionsPaths extends ApiV3ResourceCollection<VersionResource, ApiV3VersionPaths> {
  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'versions', ApiV3VersionPaths);
  }

  // /api/v3/versions/form
  public readonly form = this.subResource('form', ApiV3FormResource);

  public readonly available_projects = this.subResource('available_projects', ApiV3AvailableProjectsPaths);

  /**
   * Get all versions
   */
  public get():Observable<CollectionResource<VersionResource>> {
    return this
      .halResourceService
      .get<CollectionResource<VersionResource>>(this.path);
  }

  /**
   * Create a version from the given payload
   *
   * @param payload
   * @return {Promise<WorkPackageResource>}
   */
  public post(payload:Object):Observable<VersionResource> {
    return this
      .halResourceService
      .post<VersionResource>(this.path, payload);
  }
}
