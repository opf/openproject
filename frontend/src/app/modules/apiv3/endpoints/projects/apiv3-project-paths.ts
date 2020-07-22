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

import {APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {APIv3QueriesPaths} from "core-app/modules/apiv3/endpoints/queries/apiv3-queries-paths";
import {APIv3TypesPaths} from "core-app/modules/apiv3/endpoints/types/apiv3-types-paths";
import {APIv3VersionPaths} from "core-app/modules/apiv3/endpoints/versions/apiv3-version-paths";
import {Apiv3QueryFilterInstanceSchemaPaths} from "core-app/modules/apiv3/endpoints/projects/apiv3-query-filter-instance-schema-paths";
import {APIV3WorkPackagesPaths} from "core-app/modules/apiv3/endpoints/work_packages/api-v3-work-packages-paths";

export class APIv3ProjectPaths extends APIv3ResourcePath {

  // /api/v3/projects/:project_id/available_assignees
  public readonly available_assignees = this.subResource('available_assignees');

  public readonly queries = new APIv3QueriesPaths(this.injector, this.path);

  public readonly types = new APIv3TypesPaths(this.injector, this.path);

  public readonly work_packages = new APIV3WorkPackagesPaths(this.injector, this.path);

  public readonly versions = new APIv3VersionPaths(this.injector, this.path);

  // /api/v3/queries/filter_instance_schemas/:id
  public filterInstanceSchema(id:string|number):Apiv3QueryFilterInstanceSchemaPaths {
    return new Apiv3QueryFilterInstanceSchemaPaths(`${this.path}/filter_instance_schemas`, id);
  }
}
