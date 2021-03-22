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

import { APIv3QueriesPaths } from "core-app/modules/apiv3/endpoints/queries/apiv3-queries-paths";
import { APIv3TypesPaths } from "core-app/modules/apiv3/endpoints/types/apiv3-types-paths";
import { APIV3WorkPackagesPaths } from "core-app/modules/apiv3/endpoints/work_packages/api-v3-work-packages-paths";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { CachableAPIV3Resource } from "core-app/modules/apiv3/cache/cachable-apiv3-resource";
import { MultiInputState } from "reactivestates";
import { APIv3VersionsPaths } from "core-app/modules/apiv3/endpoints/versions/apiv3-versions-paths";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";
import { APIv3ProjectsPaths } from "core-app/modules/apiv3/endpoints/projects/apiv3-projects-paths";

export class APIv3ProjectPaths extends CachableAPIV3Resource<ProjectResource> {
  // /api/v3/projects/:project_id/available_assignees
  public readonly available_assignees = this.subResource('available_assignees');

  // /api/v3/projects/:project_id/queries
  public readonly queries = new APIv3QueriesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/types
  public readonly types = new APIv3TypesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/work_packages
  public readonly work_packages = new APIV3WorkPackagesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/versions
  public readonly versions = new APIv3VersionsPaths(this.apiRoot, this.path);

  protected createCache():StateCacheService<ProjectResource> {
    return (this.parent as APIv3ProjectsPaths).cache;
  }
}
