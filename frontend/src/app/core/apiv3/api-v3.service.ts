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

import { Injectable, Injector } from '@angular/core';
import { ApiV3GettableResource, ApiV3ResourceCollection } from 'core-app/core/apiv3/paths/apiv3-resource';
import { Constructor } from '@angular/cdk/table';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3GridsPaths } from 'core-app/core/apiv3/endpoints/grids/apiv3-grids-paths';
import { ApiV3TimeEntriesPaths } from 'core-app/core/apiv3/endpoints/time-entries/apiv3-time-entries-paths';
import { ApiV3CapabilitiesPaths } from 'core-app/core/apiv3/endpoints/capabilities/apiv3-capabilities-paths';
import { ApiV3MembershipsPaths } from 'core-app/core/apiv3/endpoints/memberships/apiv3-memberships-paths';
import { ApiV3UsersPaths } from 'core-app/core/apiv3/endpoints/users/apiv3-users-paths';
import { ApiV3TypesPaths } from 'core-app/core/apiv3/endpoints/types/apiv3-types-paths';
import { ApiV3QueriesPaths } from 'core-app/core/apiv3/endpoints/queries/apiv3-queries-paths';
import { ApiV3WorkPackagesPaths } from 'core-app/core/apiv3/endpoints/work_packages/api-v3-work-packages-paths';
import { ApiV3ProjectPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-project-paths';
import { ApiV3ProjectsPaths } from 'core-app/core/apiv3/endpoints/projects/apiv3-projects-paths';
import { ApiV3StatusesPaths } from 'core-app/core/apiv3/endpoints/statuses/apiv3-statuses-paths';
import { ApiV3RolesPaths } from 'core-app/core/apiv3/endpoints/roles/apiv3-roles-paths';
import { ApiV3VersionsPaths } from 'core-app/core/apiv3/endpoints/versions/apiv3-versions-paths';
import { ApiV3RelationsPaths } from 'core-app/core/apiv3/endpoints/relations/apiv3-relations-paths';
import { ApiV3NewsPaths } from 'core-app/core/apiv3/endpoints/news/apiv3-news-paths';
import { ApiV3HelpTextsPaths } from 'core-app/core/apiv3/endpoints/help_texts/apiv3-help-texts-paths';
import { ApiV3ConfigurationPath } from 'core-app/core/apiv3/endpoints/configuration/apiv3-configuration-path';
import { ApiV3BoardsPaths } from 'core-app/core/apiv3/virtual/apiv3-boards-paths';
import { RootResource } from 'core-app/features/hal/resources/root-resource';
import {
  ApiV3PlaceholderUsersPaths,
} from 'core-app/core/apiv3/endpoints/placeholder-users/apiv3-placeholder-users-paths';
import { ApiV3GroupsPaths } from 'core-app/core/apiv3/endpoints/groups/apiv3-groups-paths';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ApiV3NotificationsPaths } from 'core-app/core/apiv3/endpoints/notifications/apiv3-notifications-paths';
import { ApiV3ViewsPaths } from 'core-app/core/apiv3/endpoints/views/apiv3-views-paths';
import { Apiv3BackupsPath } from 'core-app/core/apiv3/endpoints/backups/apiv3-backups-path';
import { ApiV3DaysPaths } from 'core-app/core/apiv3/endpoints/days/api-v3-days-paths';
import { ApiV3StoragesPaths } from 'core-app/core/apiv3/endpoints/storages/api-v3-storages-paths';
import {
  ApiV3ProjectStoragesPaths,
} from 'core-app/core/apiv3/endpoints/project-storages/api-v3-project-storages-paths';

@Injectable({ providedIn: 'root' })
export class ApiV3Service {
  // /api/v3/attachments
  public readonly attachments = this.apiV3CollectionEndpoint('attachments');

  // /api/v3/backups
  public readonly backups = this.apiV3CustomEndpoint(Apiv3BackupsPath);

  // /api/v3/configuration
  public readonly configuration = this.apiV3CustomEndpoint(ApiV3ConfigurationPath);

  // /api/v3/days
  public readonly days = this.apiV3CustomEndpoint(ApiV3DaysPaths);

  // /api/v3/documents
  public readonly documents = this.apiV3CollectionEndpoint('documents');

  // /api/v3/file_links
  public readonly file_links = this.apiV3CollectionEndpoint('file_links');

  // /api/v3/notifications
  public readonly notifications = this.apiV3CustomEndpoint(ApiV3NotificationsPaths);

  // /api/v3/github_pull_requests
  public readonly github_pull_requests = this.apiV3CollectionEndpoint('github_pull_requests');

  // /api/v3/grids
  public readonly grids = this.apiV3CustomEndpoint(ApiV3GridsPaths);

  // /api/v3/principals
  public readonly principals = this.apiV3CollectionEndpoint('principals');

  // /api/v3/root
  public readonly root = this.apiV3SingularEndpoint<RootResource>('');

  // /api/v3/shares
  public readonly shares = this.apiV3CollectionEndpoint('shares');

  // /api/v3/statuses
  public readonly statuses = this.apiV3CustomEndpoint(ApiV3StatusesPaths);

  // /api/v3/relations
  public readonly relations = this.apiV3CustomEndpoint(ApiV3RelationsPaths);

  // /api/v3/priorities
  public readonly priorities = this.apiV3CollectionEndpoint('priorities');

  // /api/v3/time_entries
  public readonly time_entries = this.apiV3CustomEndpoint(ApiV3TimeEntriesPaths);

  // /api/v3/actions
  public readonly actions = this.apiV3CollectionEndpoint('actions');

  // /api/v3/capabilities
  public readonly capabilities = this.apiV3CustomEndpoint(ApiV3CapabilitiesPaths);

  // /api/v3/meetings
  public readonly meetings = this.apiV3CollectionEndpoint('meetings');

  // /api/v3/memberships
  public readonly memberships = this.apiV3CustomEndpoint(ApiV3MembershipsPaths);

  // /api/v3/news
  public readonly news = this.apiV3CustomEndpoint(ApiV3NewsPaths);

  // /api/v3/storages
  public readonly storages = this.apiV3CustomEndpoint(ApiV3StoragesPaths);

  // /api/v3/project_storages
  public readonly projectStorages = this.apiV3CustomEndpoint(ApiV3ProjectStoragesPaths);

  // /api/v3/types
  public readonly types = this.apiV3CustomEndpoint(ApiV3TypesPaths);

  // /api/v3/versions
  public readonly versions = this.apiV3CustomEndpoint(ApiV3VersionsPaths);

  // /api/v3/work_packages
  public readonly work_packages = this.apiV3CustomEndpoint(ApiV3WorkPackagesPaths);

  // /api/v3/queries
  public readonly queries = this.apiV3CustomEndpoint(ApiV3QueriesPaths);

  // /api/v3/projects
  public readonly projects = this.apiV3CustomEndpoint(ApiV3ProjectsPaths);

  // /api/v3/users
  public readonly users = this.apiV3CustomEndpoint(ApiV3UsersPaths);

  // /api/v3/placeholder_users
  public readonly placeholder_users = this.apiV3CustomEndpoint(ApiV3PlaceholderUsersPaths);

  // /api/v3/groups
  public readonly groups = this.apiV3CustomEndpoint(ApiV3GroupsPaths);

  // /api/v3/roles
  public readonly roles = this.apiV3CustomEndpoint(ApiV3RolesPaths);

  // /api/v3/help_texts
  public readonly help_texts = this.apiV3CustomEndpoint(ApiV3HelpTextsPaths);

  // /api/v3/job_statuses
  public readonly job_statuses = this.apiV3CollectionEndpoint('job_statuses');

  // /api/v3/views
  public readonly views = this.apiV3CustomEndpoint(ApiV3ViewsPaths);

  // VIRTUAL boards are /api/v3/grids + a scope filter
  public readonly boards = this.apiV3CustomEndpoint(ApiV3BoardsPaths);

  constructor(
    readonly injector:Injector,
    readonly pathHelper:PathHelperService,
  ) { }

  /**
   * Returns the part of the API that exists both
   *  - WITHIN a project scope /api/v3/projects/*
   *  - GLOBALLY /api/v3/*
   *
   *  The available API endpoints are being restricted automatically by typescript.
   *
   * @param projectIdentifier
   */
  public withOptionalProject(projectIdentifier:string|number|null|undefined):ApiV3ProjectPaths|this {
    if (_.isNil(projectIdentifier)) {
      return this;
    }
    return this.projects.id(projectIdentifier);
  }

  public collectionFromString(fullPath:string) {
    const path = fullPath.replace(`${this.pathHelper.api.v3.apiV3Base}/`, '');

    return this.apiV3CollectionEndpoint(path);
  }

  private apiV3CollectionEndpoint<V extends HalResource, T extends ApiV3GettableResource<V>>(segment:string, resource?:Constructor<T>) {
    return new ApiV3ResourceCollection<V, T>(this, this.pathHelper.api.v3.apiV3Base, segment, resource);
  }

  private apiV3CustomEndpoint<T>(cls:Constructor<T>):T {
    // eslint-disable-next-line new-cap
    return new cls(this, this.pathHelper.api.v3.apiV3Base);
  }

  private apiV3SingularEndpoint<T extends HalResource = HalResource>(segment:string):ApiV3GettableResource<T> {
    return new ApiV3GettableResource<T>(this, this.pathHelper.api.v3.apiV3Base, segment);
  }
}
