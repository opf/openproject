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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { ApiV3RelationsPaths } from 'core-app/core/apiv3/endpoints/relations/apiv3-relations-paths';
import { ApiV3Resource } from 'core-app/core/apiv3/cache/cachable-apiv3-resource';
import { ApiV3WorkPackagesPaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-packages-paths';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';
import { ApiV3WorkPackageForm } from 'core-app/core/apiv3/endpoints/work_packages/apiv3-work-package-form';

export class ApiV3WorkPackagePaths extends ApiV3Resource<WorkPackageResource> {
  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/relations
  public readonly relations = this.subResource('relations', ApiV3RelationsPaths);

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/revisions
  public readonly revisions = this.subResource('revisions');

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/activities
  public readonly activities = this.subResource('activities');

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/available_watchers
  public readonly available_watchers = this.subResource('available_watchers');

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/available_projects
  public readonly available_projects = this.subResource('available_projects');

  // /api/v3/(?:projectPath)/work_packages/(:workPackageId)/github_pull_requests
  public readonly github_pull_requests = this.subResource('github_pull_requests');

  // /api/v3/(projects/:projectIdentifier)/work_packages/(:workPackageId)/form
  public readonly form:ApiV3WorkPackageForm = this.subResource('form', ApiV3WorkPackageForm);

  protected createCache():StateCacheService<WorkPackageResource> {
    return (this.parent as ApiV3WorkPackagesPaths).cache;
  }
}
