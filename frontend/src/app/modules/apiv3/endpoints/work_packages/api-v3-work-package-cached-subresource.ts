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

import {APIv3GettableResource, APIv3ResourcePath} from "core-app/modules/apiv3/paths/apiv3-resource";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {Apiv3RelationsPaths} from "core-app/modules/apiv3/endpoints/relations/apiv3-relations-paths";
import {WorkPackageCollectionResource} from "core-app/modules/hal/resources/wp-collection-resource";
import {Observable} from "rxjs";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {CachableAPIV3Resource} from "core-app/modules/apiv3/cache/cachable-apiv3-resource";
import {APIV3WorkPackagesPaths} from "core-app/modules/apiv3/endpoints/work_packages/api-v3-work-packages-paths";
import {StateCacheService} from "core-app/modules/apiv3/cache/state-cache.service";
import {take, tap} from "rxjs/operators";
import {WorkPackageCache} from "core-app/modules/apiv3/endpoints/work_packages/work-package.cache";

export class ApiV3WorkPackageCachedSubresource extends APIv3GettableResource<WorkPackageCollectionResource> {

  public get():Observable<WorkPackageCollectionResource> {
    return this
      .halResourceService
      .get<WorkPackageCollectionResource>(this.path)
      .pipe(
        tap(collection => this.cache.updateWorkPackageList(collection.elements)),
        take(1)
      );
  }

  protected get cache():WorkPackageCache {
    return (this.parent as APIV3WorkPackagesPaths).cache;
  }
}
