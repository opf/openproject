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

import { Injectable, Injector } from "@angular/core";
import {
  APIv3GettableResource,
  APIv3ResourceCollection,
  APIv3ResourcePath
} from "core-app/modules/apiv3/paths/apiv3-resource";
import { Constructor } from "@angular/cdk/table";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { Apiv3GridsPaths } from "core-app/modules/apiv3/endpoints/grids/apiv3-grids-paths";
import { Apiv3TimeEntriesPaths } from "core-app/modules/apiv3/endpoints/time-entries/apiv3-time-entries-paths";
import { Apiv3MembershipsPaths } from "core-app/modules/apiv3/endpoints/memberships/apiv3-memberships-paths";
import { Apiv3UsersPaths } from "core-app/modules/apiv3/endpoints/users/apiv3-users-paths";
import { Apiv3PlaceholderUsersPaths } from 'core-app/modules/apiv3/endpoints/placeholder-users/apiv3-placeholder-users-paths.ts';
import { Apiv3GroupsPaths } from 'core-app/modules/apiv3/endpoints/groups/apiv3-groups-paths.ts';
import { APIv3TypesPaths } from "core-app/modules/apiv3/endpoints/types/apiv3-types-paths";
import { APIv3QueriesPaths } from "core-app/modules/apiv3/endpoints/queries/apiv3-queries-paths";
import { APIV3WorkPackagesPaths } from "core-app/modules/apiv3/endpoints/work_packages/api-v3-work-packages-paths";
import { APIv3ProjectPaths } from "core-app/modules/apiv3/endpoints/projects/apiv3-project-paths";
import { APIv3ProjectsPaths } from "core-app/modules/apiv3/endpoints/projects/apiv3-projects-paths";
import { APIv3StatusesPaths } from "core-app/modules/apiv3/endpoints/statuses/apiv3-statuses-paths";
import { APIv3RolesPaths } from "core-app/modules/apiv3/endpoints/roles/apiv3-roles-paths";
import { APIv3VersionsPaths } from "core-app/modules/apiv3/endpoints/versions/apiv3-versions-paths";
import { Apiv3RelationsPaths } from "core-app/modules/apiv3/endpoints/relations/apiv3-relations-paths";
import { Apiv3NewsPaths } from "core-app/modules/apiv3/endpoints/news/apiv3-news-paths";
import { Apiv3HelpTextsPaths } from "core-app/modules/apiv3/endpoints/help_texts/apiv3-help-texts-paths";
import { Apiv3ConfigurationPath } from "core-app/modules/apiv3/endpoints/configuration/apiv3-configuration-path";
import { Apiv3BoardsPaths } from "core-app/modules/apiv3/virtual/apiv3-boards-paths";
import { RootResource } from "core-app/modules/hal/resources/root-resource";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import * as ts from "typescript/lib/tsserverlibrary";
import Project = ts.server.Project;

@Injectable({ providedIn: 'root' })
export class APIV3Service {
  // /api/v3/attachments
  public readonly attachments = this.apiV3CollectionEndpoint('attachments');

  // /api/v3/configuration
  public readonly configuration = this.apiV3CustomEndpoint(Apiv3ConfigurationPath);

  // /api/v3/documents
  public readonly documents = this.apiV3CollectionEndpoint('documents');

  // /api/v3/grids
  public readonly grids = this.apiV3CustomEndpoint(Apiv3GridsPaths);

  // /api/v3/principals
  public readonly principals = this.apiV3CollectionEndpoint('principals');

  // /api/v3/root
  public readonly root = this.apiV3SingularEndpoint<RootResource>('');

  // /api/v3/statuses
  public readonly statuses = this.apiV3CustomEndpoint(APIv3StatusesPaths);

  // /api/v3/relations
  public readonly relations = this.apiV3CustomEndpoint(Apiv3RelationsPaths);

  // /api/v3/priorities
  public readonly priorities = this.apiV3CollectionEndpoint('priorities');

  // /api/v3/time_entries
  public readonly time_entries = this.apiV3CustomEndpoint(Apiv3TimeEntriesPaths);

  // /api/v3/memberships
  public readonly memberships = this.apiV3CustomEndpoint(Apiv3MembershipsPaths);

  // /api/v3/news
  public readonly news = this.apiV3CustomEndpoint(Apiv3NewsPaths);

  // /api/v3/types
  public readonly types = this.apiV3CustomEndpoint(APIv3TypesPaths);

  // /api/v3/versions
  public readonly versions = this.apiV3CustomEndpoint(APIv3VersionsPaths);

  // /api/v3/work_packages
  public readonly work_packages = this.apiV3CustomEndpoint(APIV3WorkPackagesPaths);

  // /api/v3/queries
  public readonly queries = this.apiV3CustomEndpoint(APIv3QueriesPaths);

  // /api/v3/projects
  public readonly projects = this.apiV3CustomEndpoint(APIv3ProjectsPaths);

  // /api/v3/users
  public readonly users = this.apiV3CustomEndpoint(Apiv3UsersPaths);

  // /api/v3/placeholderUsers
  public readonly placeholder_users = this.apiV3CustomEndpoint(Apiv3PlaceholderUsersPaths);

  // /api/v3/groups
  public readonly groups = this.apiV3CustomEndpoint(Apiv3GroupsPaths);

  // /api/v3/roles
  public readonly roles = this.apiV3CustomEndpoint(APIv3RolesPaths);

  // /api/v3/help_texts
  public readonly help_texts = this.apiV3CustomEndpoint(Apiv3HelpTextsPaths);

  // /api/v3/job_statuses
  public readonly job_statuses = this.apiV3CollectionEndpoint('job_statuses');

  // VIRTUAL boards are /api/v3/grids + a scope filter
  public readonly boards = this.apiV3CustomEndpoint(Apiv3BoardsPaths);

  constructor(readonly injector:Injector,
              readonly pathHelper:PathHelperService) {
  }

  /**
   * Returns the part of the API that exists both
   *  - WITHIN a project scope /api/v3/projects/*
   *  - GLOBALLY /api/v3/*
   *
   *  The available API endpoints are being restricted automatically by typescript.
   *
   * @param projectIdentifier
   */
  public withOptionalProject(projectIdentifier:string|number|null|undefined):APIv3ProjectPaths|this {
    if (_.isNil(projectIdentifier)) {
      return this;
    } else {
      return this.projects.id(projectIdentifier);
    }
  }

  public collectionFromString(fullPath:string) {
    const path = fullPath.replace(this.pathHelper.api.v3.apiV3Base + '/', '');

    return this.apiV3CollectionEndpoint(path);
  }

  private apiV3CollectionEndpoint<V extends HalResource, T extends APIv3GettableResource<V>>(segment:string, resource?:Constructor<T>) {
    return new APIv3ResourceCollection<V, T>(this, this.pathHelper.api.v3.apiV3Base, segment, resource);
  }

  private apiV3CustomEndpoint<T>(cls:Constructor<T>):T {
    return new cls(this, this.pathHelper.api.v3.apiV3Base);
  }

  private apiV3SingularEndpoint<T extends HalResource = HalResource>(segment:string):APIv3GettableResource<T> {
    return new APIv3GettableResource<T>(this, this.pathHelper.api.v3.apiV3Base, segment);
  }
}
