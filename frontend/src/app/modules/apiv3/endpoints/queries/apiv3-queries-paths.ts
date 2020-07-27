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

import {APIv3GettableResource, APIv3ResourceCollection} from "core-app/modules/apiv3/paths/apiv3-resource";
import {APIv3QueryPaths} from "core-app/modules/apiv3/endpoints/queries/apiv3-query-paths";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {Apiv3QueryForm} from "core-app/modules/apiv3/endpoints/queries/apiv3-query-form";

export class APIv3QueriesPaths extends APIv3ResourceCollection<QueryResource, APIv3QueryPaths> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'queries', APIv3QueryPaths);
  }

  // Static paths
  // /api/v3/queries/form
  readonly form = this.subResource('form', Apiv3QueryForm);

  // /api/v3/queries/default
  readonly default = this.subResource<APIv3GettableResource<QueryResource>>('default');

  // /api/v3/queries/filter_instance_schemas/:id
  filterInstanceSchemas = new APIv3ResourceCollection(this.apiRoot, this.path, 'filter_instance_schemas');
}
