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

import { ApiV3QueriesPaths } from 'core-app/core/apiv3/endpoints/queries/apiv3-queries-paths';
import { ApiV3TypesPaths } from 'core-app/core/apiv3/endpoints/types/apiv3-types-paths';
import { ApiV3WorkPackagesPaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-packages-paths';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { ApiV3VersionsPaths } from 'core-app/core/apiv3/endpoints/versions/apiv3-versions-paths';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { ApiV3ProjectsPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-projects-paths';
import { ApiV3ProjectCopyPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-project-copy-paths';

export class ApiV3ProjectPaths extends ApiV3Resource<ProjectResource> {
  // /api/v3/projects/:project_id/available_assignees
  public readonly available_assignees = this.subResource('available_assignees');

  // /api/v3/projects/:project_id/queries
  public readonly queries = new ApiV3QueriesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/types
  public readonly types = new ApiV3TypesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/work_packages
  public readonly work_packages = new ApiV3WorkPackagesPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/versions
  public readonly versions = new ApiV3VersionsPaths(this.apiRoot, this.path);

  // /api/v3/projects/:project_id/copy
  public readonly copy = new ApiV3ProjectCopyPaths(this.apiRoot, this.path);

  protected createCache():StateCacheService<ProjectResource> {
    return (this.parent as ApiV3ProjectsPaths).cache;
  }
}
