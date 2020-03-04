// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// ++

import {ApiV3WorkPackagesPaths} from 'core-app/modules/common/path-helper/apiv3/work_packages/apiv3-work-packages-paths';
import {Apiv3UsersPaths} from 'core-app/modules/common/path-helper/apiv3/users/apiv3-users-paths';
import {Apiv3ProjectsPaths} from 'core-app/modules/common/path-helper/apiv3/projects/apiv3-projects-paths';
import {
  SimpleResource,
  SimpleResourceCollection
} from 'core-app/modules/common/path-helper/apiv3/path-resources';
import {Apiv3QueriesPaths} from 'core-app/modules/common/path-helper/apiv3/queries/apiv3-queries-paths';
import {Apiv3ProjectPaths} from 'core-app/modules/common/path-helper/apiv3/projects/apiv3-project-paths';
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {Apiv3TypesPaths} from "core-app/modules/common/path-helper/apiv3/types/apiv3-types-paths";
import {Apiv3GridsPaths} from "core-app/modules/common/path-helper/apiv3/grids/apiv3-grids-paths";
import {Apiv3NewsesPaths} from "core-app/modules/common/path-helper/apiv3/news/apiv3-newses-paths";
import {Apiv3TimeEntriesPaths} from "core-app/modules/common/path-helper/apiv3/time-entries/apiv3-time-entries-paths";
import {Apiv3VersionPaths} from "core-app/modules/common/path-helper/apiv3/versions/apiv3-version-paths";
import {Apiv3MembershipsPaths} from "core-app/modules/common/path-helper/apiv3/memberships/apiv3-memberships-paths";
import {Apiv3GroupsPaths} from "core-app/modules/common/path-helper/apiv3/groups/apiv3-groups-path";

export class ApiV3Paths {
  // Base path
  public readonly apiV3Base  = this.appBasePath + '/api/v3';

  // /api/v3/attachments
  public readonly attachments = new SimpleResource(this.apiV3Base, 'attachments');

  // /api/v3/configuration
  public readonly configuration = new SimpleResource(this.apiV3Base, 'configuration');

  // /api/v3/root
  public readonly root = new SimpleResource(this.apiV3Base, '');

  // /api/v3/statuses
  public readonly statuses = new SimpleResourceCollection(this.apiV3Base, 'statuses');

  // /api/v3/relations
  public readonly relations = new SimpleResourceCollection(this.apiV3Base, 'relations');

  // /api/v3/priorities
  public readonly priorities = new SimpleResourceCollection(this.apiV3Base, 'priorities');

  // /api/v3/time_entries
  public readonly time_entries = new Apiv3TimeEntriesPaths(this.apiV3Base);

  // /api/v3/memberships
  public readonly memberships = new Apiv3MembershipsPaths(this.apiV3Base);

  // /api/v3/news
  public readonly news = new Apiv3NewsesPaths(this.apiV3Base);

  // /api/v3/types
  public readonly types = new Apiv3TypesPaths(this.apiV3Base);

  // /api/v3/versions
  public readonly versions = new Apiv3VersionPaths(this.apiV3Base);

  // /api/v3/work_packages
  public readonly work_packages = new ApiV3WorkPackagesPaths(this.apiV3Base);

  // /api/v3/queries
  public readonly queries = new Apiv3QueriesPaths(this.apiV3Base);

  // /api/v3/projects
  public readonly projects = new Apiv3ProjectsPaths(this.apiV3Base);

  // /api/v3/users
  public readonly users = new Apiv3UsersPaths(this.apiV3Base);

  // /api/v3/help_texts
  public readonly help_texts = new SimpleResourceCollection(this.apiV3Base, 'help_texts');

  // /api/v3/grids
  public readonly grids = new Apiv3GridsPaths(this.apiV3Base);

  // /api/v3/groups
  public readonly groups = new Apiv3GroupsPaths(this.apiV3Base);


  constructor(readonly appBasePath:string) {
  }

  /**
   * Returns possible subpaths either in this api root or below /projects/:id/
   *
   * @param {string | number} projectIdentifier
   * @returns {Apiv3ProjectPaths | this}
   */
  public withOptionalProject(projectIdentifier:string|number|null|undefined):Apiv3ProjectPaths|this {
    if (_.isNil(projectIdentifier)) {
      return this;
    } else {
      return this.projects.id(projectIdentifier);
    }
  }

  /**
   * returns a resource segment from (/base)/api/v3/(resource)
   * @param segment
   */
  public resource(segment:string) {
    if (!segment.startsWith('/')) {
      segment = '/' + segment;
    }

    return this.apiV3Base + segment;
  }

  public previewMarkup(context:string) {
    let base = this.apiV3Base + '/render/markdown';

    if (context) {
      return base + `?context=${context}`;
    } else {
      return base;
    }
  }

  public principals(projectId:string|number, term:string|null) {
    let filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();
    // Only real and activated users:
    filters.add('status', '!', ['3']);
    // that are members of that project:
    filters.add('member', '=', [projectId.toString()]);
    // That are users:
    filters.add('type', '=', ['User', 'Group']);
    // That are not the current user:
    filters.add('id', '!', ['me']);

    if (term && term.length > 0) {
      // Containing the that substring:
      filters.add('name', '~', [term]);
    }

    return this.apiV3Base +
      '/principals?' +
      filters.toParams({ sortBy: '[["name","asc"]]', offset: '1', pageSize: '10' });
  }

  public wpBySubjectOrId(term:string, idOnly:boolean = false) {
    let filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    if (idOnly) {
      filters.add('id', '=', [term]);
    } else {
      filters.add('subjectOrId', '**', [term]);
    }

    return this.apiV3Base +
      '/work_packages?' +
      filters.toParams({ sortBy: '[["updatedAt","desc"]]', offset: '1', pageSize: '10' });
  }
}
