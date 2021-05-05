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


import { Apiv3TimeEntryPaths } from "core-app/modules/apiv3/endpoints/time-entries/apiv3-time-entry-paths";
import { TimeEntryResource } from "core-app/modules/hal/resources/time-entry-resource";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { APIv3FormResource } from "core-app/modules/apiv3/forms/apiv3-form-resource";
import { Observable } from "rxjs";
import { CollectionResource } from "core-app/modules/hal/resources/collection-resource";
import { CachableAPIV3Collection } from "core-app/modules/apiv3/cache/cachable-apiv3-collection";
import { MultiInputState } from "reactivestates";
import {
  Apiv3ListParameters,
  Apiv3ListResourceInterface,
  listParamsString
} from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";
import { TimeEntryCacheService } from "core-app/modules/apiv3/endpoints/time-entries/time-entry-cache.service";
import { StateCacheService } from "core-app/modules/apiv3/cache/state-cache.service";

export class Apiv3TimeEntriesPaths
  extends CachableAPIV3Collection<TimeEntryResource, Apiv3TimeEntryPaths>
  implements Apiv3ListResourceInterface<TimeEntryResource> {
  constructor(protected apiRoot:APIV3Service,
              protected basePath:string) {
    super(apiRoot, basePath, 'time_entries', Apiv3TimeEntryPaths);
  }

  // Static paths
  public readonly form = this.subResource('form', APIv3FormResource);

  /**
   * Load a list of time entries with a given list parameter filter
   * @param params
   */
  public list(params?:Apiv3ListParameters):Observable<CollectionResource<TimeEntryResource>> {
    return this
      .halResourceService
      .get<CollectionResource<TimeEntryResource>>(this.path + listParamsString(params))
      .pipe(
        this.cacheResponse()
      );
  }

  /**
   * Create a time entry resource from the given payload
   * @param payload
   */
  public post(payload:Object):Observable<TimeEntryResource> {
    return this
      .halResourceService
      .post<TimeEntryResource>(this.path, payload)
      .pipe(
        this.cacheResponse()
      );
  }

  protected createCache():StateCacheService<TimeEntryResource> {
    return new TimeEntryCacheService(this.injector, this.states.timeEntries);
  }
}
