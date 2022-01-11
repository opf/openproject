// -- copyright
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
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApiV3CapabilityPaths } from 'core-app/core/apiv3/endpoints/capabilities/apiv3-capability-paths';
import { CapabilityResource } from 'core-app/features/hal/resources/capability-resource';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { Observable } from 'rxjs';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { ApiV3Collection } from 'core-app/core/apiv3/cache/cachable-apiv3-collection';
import {
  ApiV3ListParameters,
  ApiV3ListResourceInterface,
  listParamsString,
} from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { CapabilityCacheService } from 'core-app/core/apiv3/endpoints/capabilities/capability-cache.service';
import { StateCacheService } from 'core-app/core/apiv3/cache/state-cache.service';

export class ApiV3CapabilitiesPaths
  extends ApiV3Collection<CapabilityResource, ApiV3CapabilityPaths>
  implements ApiV3ListResourceInterface<CapabilityResource> {
  constructor(protected apiRoot:ApiV3Service,
    protected basePath:string) {
    super(apiRoot, basePath, 'capabilities', ApiV3CapabilityPaths);
  }

  /**
   * Load a list of capabilities with a given list parameter filter
   * @param params
   */
  public list(params?:ApiV3ListParameters):Observable<CollectionResource<CapabilityResource>> {
    return this
      .halResourceService
      .get<CollectionResource<CapabilityResource>>(this.path + listParamsString(params))
      .pipe(
        this.cacheResponse(),
      );
  }

  protected createCache():StateCacheService<CapabilityResource> {
    return new CapabilityCacheService(this.injector, this.states.capabilities);
  }
}
