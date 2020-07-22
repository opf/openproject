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

import {APIv3ResourceCollection, APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {Injector} from "@angular/core";
import {APIV3WorkPackagePaths} from "core-app/modules/apiv3/endpoints/work_packages/api-v3-work-package-paths";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

export class APIV3WorkPackagesPaths extends APIv3ResourceCollection<WorkPackageResource, APIV3WorkPackagePaths> {
  // Base path
  public readonly path:string;

  constructor(readonly injector:Injector,
              protected basePath:string) {
    super(injector, basePath, 'work_packages', APIV3WorkPackagePaths);
  }

  // Static paths

  // /api/v3/(projects/:projectIdentifier)/work_packages/form
  public readonly form = new APIv3ResourcePath(this.injector, this.path, 'form');

  /**
   * Shortcut to filter work packages by subject or ID
   * @param term
   * @param idOnly
   */
  public filterBySubjectOrId(term:string, idOnly:boolean = false):APIv3ResourcePath<CollectionResource<WorkPackageResource>> {
    let filters:ApiV3FilterBuilder = new ApiV3FilterBuilder();

    if (idOnly) {
      filters.add('id', '=', [term]);
    } else {
      filters.add('subjectOrId', '**', [term]);
    }

    return this.filtered(filters);
  }

}
